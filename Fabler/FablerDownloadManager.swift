//
//  FablerDownloader.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

//
// This code is based off https://github.com/Gurpartap/cheapjack below is the license.
//

// Copyright (c) 2015 Gurpartap Singh
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import RealmSwift

public class FablerDownloadManager: NSObject, NSURLSessionDownloadDelegate, NSURLSessionDelegate {

    // MARK: - singleton

    public static let sharedInstance = FablerDownloadManager(backgroundSessionIdentifier: "com.Fabler.Fabler.background")

    // MARK: - Public properties

    public var backgroundSessionCompletionHandler: (() -> Void)?

    // MARK: - Private properties

    private let downloadsLockQueue: dispatch_queue_t
    private let backgroundSessionIdentifier: String
    private var downloads: Array<NSURLSessionDownloadTask>
    private lazy var backgroundSession: NSURLSession = self.newBackgroundURLSession()

    // MARK: - Private methods

    private func newBackgroundURLSession() -> NSURLSession {
        let backgroundSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundSessionIdentifier)
        return NSURLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: nil)
    }

    private func handleDownloadTaskWithProgress(downloadTask: NSURLSessionDownloadTask, totalBytesWritten: Int, totalBytesExpectedToWrite: Int) {
        if let download = getDownloadFromTask(downloadTask) {
            if download.state != .Downloading {
                download.state = .Downloading
            }

            download.totalBytes = totalBytesExpectedToWrite
            download.totalBytesWritten = totalBytesWritten
        }
    }

    private func getTaskFromURL(url: String) -> NSURLSessionDownloadTask? {
        var task: NSURLSessionDownloadTask? = nil

        if let index = self.downloads.indexOf({ $0.originalRequest?.URL?.URLString == url }) {
            task = self.downloads[index]
        }

        return task
    }

    private func getDownloadFromTask(task: NSURLSessionTask) -> FablerDownload? {
        var download: FablerDownload?

        if let url = task.originalRequest?.URL {
            download = self.getDownloadFromURL(url.URLString)
        }

        return download
    }

    private func getDownloadFromURL(url: String) -> FablerDownload? {
        var download: FablerDownload?

        do {
            let realm = try Realm()
            download = realm.objects(FablerDownload).filter("urlString == %s", url).first
        } catch {
            Log.error("Realm read failed")
        }

        return download
    }

    private func removeTask(task: NSURLSessionDownloadTask) {
        if let index = self.downloads.indexOf(task) {
            self.downloads.removeAtIndex(index)
        }
    }

    // MARK: - Public methods

    public required init(backgroundSessionIdentifier: String) {
        self.downloadsLockQueue = dispatch_queue_create("com.Fabler.Fabler.downloadQueue", nil)
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
        self.downloads = Array<NSURLSessionDownloadTask>()

        super.init()
    }

    public func calculateSizeOnDisk(queue: dispatch_queue_t = dispatch_get_main_queue(), completionHandler: ((size: Int) -> ())) {
        dispatch_async(downloadsLockQueue) {
            var size: Int = 0

            do {
                let realm = try Realm()

                let downloads = Array(realm.objects(FablerDownload))
                _ = downloads.map { size += $0.totalBytesWrittenRaw }
            } catch {
                Log.error("Realm read failed")
            }

            dispatch_async(queue) {
                completionHandler(size: size)
            }
        }
    }

    public func calculateSizeOnDisk(forPodcast: Podcast, queue: dispatch_queue_t = dispatch_get_main_queue(), completionHandler: ((size: Int) -> ())) {
        let id = forPodcast.podcastId

        var size: Int = 0

        dispatch_async(downloadsLockQueue) {
            do {
                let realm = try Realm()

                let episodes = realm.objects(Episode).filter("download != nil && podcastId == %d", id)
                _ = episodes.map { size += $0.download!.totalBytesWrittenRaw }
            } catch {
                Log.error("Realm read failed")
            }

            dispatch_async(queue) {
                completionHandler(size: size)
            }
        }
    }

    public func downloadWithURL(url: NSURL, localUrl: NSURL) -> FablerDownload? {
        var download: FablerDownload?

        dispatch_sync(downloadsLockQueue) {
            do {
                var queueDownload: FablerDownload?

                let realm = try Realm()

                if let existingDownload = realm.objects(FablerDownload).filter("urlString == %s", url.URLString).first {
                    queueDownload = existingDownload
                } else {
                    queueDownload = FablerDownload()
                    queueDownload?.url = url
                    queueDownload?.localUrl = localUrl

                    try realm.write {
                        realm.add(queueDownload!)
                    }
                }
            } catch {
                Log.error("Realm write failed")
            }
        }

        download = self.getDownloadFromURL(url.URLString)

        return download
    }

    public func downloadWithEpisode(episode: Episode) -> FablerDownload? {
        var download: FablerDownload?
        let episodeId = episode.episodeId

        dispatch_sync(downloadsLockQueue) {
            do {
                var queueDownload: FablerDownload?

                let service = EpisodeService()
                let queueEpisode = service.getEpisodeFor(episodeId, completion: nil)

                let realm = try Realm()

                if let existingDownload = queueEpisode?.download {
                    queueDownload = existingDownload

                    switch existingDownload.state {
                    case .Unknown:
                        fallthrough
                    case .Waiting:
                        fallthrough
                    case .Pausing:
                        fallthrough
                    case .Paused:
                        fallthrough
                    case .Downloading:
                        fallthrough
                    case .Completed:
                        break

                    case .Cancelled:
                        fallthrough
                    case .Failed:
                        if let task = self.getTaskFromURL(existingDownload.urlString) {
                            task.cancel()
                            self.removeTask(task)
                        }

                        if let url = existingDownload.url {
                            existingDownload.state = .Waiting

                            let task = self.backgroundSession.downloadTaskWithURL(url)
                            task.resume()
                            self.downloads.append(task)
                        }
                    }
                } else {
                    if let url = NSURL(string: episode.link), let localUrl = queueEpisode?.localURL() {
                        queueDownload = FablerDownload()
                        queueDownload?.url = url
                        queueDownload?.localUrl = localUrl
                        queueDownload?.state = .Waiting

                        try realm.write {
                            realm.add(queueDownload!)
                        }

                        let task = self.backgroundSession.downloadTaskWithURL(url)
                        task.resume()
                        self.downloads.append(task)
                    }
                }

                try realm.write {
                    queueEpisode?.download = queueDownload
                }
            } catch {
                Log.error("Realm write failed")
            }
        }

        download = self.getDownloadFromURL(episode.link)

        return download
    }

    public func resumeAll() {
        dispatch_sync(downloadsLockQueue) {
            do {
                let realm = try Realm()

                let downloads = Array(realm.objects(FablerDownload))

                _ = downloads.map { $0.resume() }
            } catch {
                Log.error("Realm read failed")
            }
        }
    }

    public func resume(download: FablerDownload) {
        guard download.state == .Failed || download.state == .Paused || download.state == .Pausing || download.state == .Cancelled else {
            Log.warning("Invalid state to resume download from")
            return
        }

        let urlString = download.urlString
        let url = download.url

        dispatch_sync(downloadsLockQueue) {
            if let queueDownload = self.getDownloadFromURL(urlString) {
                if let resumeData = download.resumeData {
                    self.downloads.append(self.backgroundSession.downloadTaskWithResumeData(resumeData))

                    do {
                        let realm = try Realm()

                        try realm.write {
                            download.resumeData = nil
                        }
                    } catch {
                        Log.error("Realm write failed")
                    }
                } else {
                    if let url = url {
                        self.downloads.append(self.backgroundSession.downloadTaskWithURL(url))
                    }
                }

                queueDownload.state = .Waiting
            }
        }
    }

    public func pauseAll() {
        dispatch_sync(downloadsLockQueue) {
            do {
                let realm = try Realm()

                let downloads = Array(realm.objects(FablerDownload))

                _ = downloads.map { $0.pause() }
            } catch {
                Log.error("Realm read failed")
            }
        }
    }

    public func pause(download: FablerDownload, completionHandler: (NSData? -> Void)? = nil) {
        guard download.state == .Downloading else {
            Log.warning("Invalid state to pause download from")
            return
        }

        let urlString = download.urlString

        dispatch_sync(downloadsLockQueue) {
            if let queueDownload = self.getDownloadFromURL(urlString), let task = self.getTaskFromURL(urlString) {
                queueDownload.state = .Pausing
                task.cancelByProducingResumeData { (data) -> Void in
                    if let handlerDownload = self.getDownloadFromURL(urlString) {
                        handlerDownload.state = .Paused

                        do {
                            let realm = try Realm()

                            try realm.write {
                                handlerDownload.resumeData = data
                            }
                        } catch {
                            Log.error("Realm write failed")
                        }

                        completionHandler?(data)
                    }
                }

                self.removeTask(task)
            }
        }
    }

    public func cancelAll() {
        dispatch_sync(downloadsLockQueue) {
            do {
                let realm = try Realm()

                let downloads = Array(realm.objects(FablerDownload))

                _ = downloads.map { $0.cancel() }
            } catch {
                Log.error("Realm read failed")
            }
        }
    }

    public func cancel(download: FablerDownload) {
        guard download.state == .Downloading else {
            Log.warning("Invalid state to cancel download from")
            return
        }

        let urlString = download.urlString

        dispatch_sync(downloadsLockQueue) {
            if let queueDownload = self.getDownloadFromURL(urlString), let task = self.getTaskFromURL(urlString) {
                task.cancel()

                do {
                    let realm = try Realm()

                    try realm.write {
                        queueDownload.resumeData = nil
                    }
                } catch {
                    Log.error("Realm write failed")
                }

                self.removeTask(task)

                queueDownload.state = .Cancelled
            }
        }
    }

    public func removeAll() {
        dispatch_sync(downloadsLockQueue) {
            do {
                let realm = try Realm()

                let downloads = Array(realm.objects(FablerDownload))

                _ = downloads.map { $0.remove() }
            } catch {
                Log.error("Realm read failed")
            }
        }
    }

    public func removeAll(forPodcast: Podcast) {
        let id = forPodcast.podcastId

        dispatch_async(downloadsLockQueue) {
            do {
                let realm = try Realm()

                let episodes = realm.objects(Episode).filter("download != nil && podcastId == %d", id)

                _ =  episodes.map { $0.download!.remove() }
            } catch {
                Log.error("Realm read failed")
            }
        }
    }

    public func remove(download: FablerDownload) {
        let urlString = download.urlString

        dispatch_sync(downloadsLockQueue) {
            if let task = self.getTaskFromURL(urlString) {
                self.removeTask(task)
            }

            if let queueDownload = self.getDownloadFromURL(urlString), let local = queueDownload.localUrl {
                do {
                    try NSFileManager.defaultManager().removeItemAtURL(local)
                } catch let error as NSError {
                    Log.error("Failed to remove file due to \(error)")
                }
            }
        }
    }

    // MARK: - NSURLSessionDownloadDelegate

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let download = getDownloadFromTask(downloadTask) {
            download.state = .Completed

            if let localUrl = download.localUrl {
                do {
                    try NSFileManager.defaultManager().moveItemAtURL(location, toURL: localUrl)
                } catch let error as NSError {
                    Log.error("Failed to move file due to \(error)")
                }
            }
        }
    }

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        handleDownloadTaskWithProgress(downloadTask, totalBytesWritten: Int(fileOffset), totalBytesExpectedToWrite: Int(expectedTotalBytes))
    }

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        handleDownloadTaskWithProgress(downloadTask, totalBytesWritten: Int(totalBytesWritten), totalBytesExpectedToWrite: Int(totalBytesExpectedToWrite))
    }

    // MARK: - NSURLSessionTaskDelegate

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if let download = getDownloadFromTask(task) {
            download.cancel()
            download.state = .Failed

            Log.error("Failed to download file due to authentication challenge")
        }
    }

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let download = getDownloadFromTask(task) where error != nil {
            download.cancel()
            download.state = .Failed

            Log.error("Failed to download file due to \(error)")
        }
    }

    // MARK: - NSURLSessionDelegate

    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        Log.error("Download session failed due to \(error)")
    }

    public func URLSessionDidFinishEventsForBackgroundURLSession(session: NSURLSession) {
        session.getTasksWithCompletionHandler { (_, _, downloadTasks) -> Void in
            if downloadTasks.count == 0 {
                dispatch_async(dispatch_get_main_queue()) {
                    self.backgroundSessionCompletionHandler?()
                    self.backgroundSessionCompletionHandler = nil
                }
            }
        }
    }
}
