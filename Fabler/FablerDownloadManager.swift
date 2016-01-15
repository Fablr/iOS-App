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

    // MARK: - public members

    public var backgroundSessionCompletionHandler: (() -> Void)?

    // MARK: - private members

    private let downloadsLockQueue: dispatch_queue_t
    private let backgroundSessionIdentifier: String
    private lazy var backgroundSession: NSURLSession = self.newBackgroundURLSession()

    // MARK: - private functions

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

    private func getDownloadFromTask(task: NSURLSessionTask) -> FablerDownload? {
        var download: FablerDownload?

        if let url = task.originalRequest?.URL {
            dispatch_sync(downloadsLockQueue) {
                do {
                    let realm = try Realm()

                    download = realm.objects(FablerDownload).filter("urlString == %s", url.URLString).first
                } catch {
                    Log.error("Failed Realm read")
                }
            }
        }

        return download
    }

    private func getDownloadFromId(downloadId: Int) -> FablerDownload? {
        var download: FablerDownload?

        do {
            let realm = try Realm()

            download = realm.objectForPrimaryKey(FablerDownload.self, key: downloadId)
        } catch {
            Log.error("Realm read failed")
        }

        return download
    }

    // MARK: - public functions

    public required init(backgroundSessionIdentifier: String) {
        self.downloadsLockQueue = dispatch_queue_create("com.Fabler.Fabler.downloadQueue", nil)
        self.backgroundSessionIdentifier = backgroundSessionIdentifier

        super.init()
    }

    public func downloadWithURL(url: NSURL, localUrl: NSURL, delegate: FablerDownloadDelegate?) -> FablerDownload? {
        var download: FablerDownload?
        var id: Int?

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

                id = queueDownload?.downloadId
            } catch {
                Log.error("Realm write failed")
            }
        }

        if let id = id {
            do {
                let realm = try Realm()

                download = realm.objectForPrimaryKey(FablerDownload.self, key: id)
            } catch {
                Log.error("Realm read failed")
            }
        }

        download?.delegate = delegate

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

        let id = download.downloadId

        dispatch_sync(downloadsLockQueue) {
            if let download = self.getDownloadFromId(id) {
                if let resumeData = download.resumeData {
                    download.downloadTask?.cancel()
                    download.downloadTask = self.backgroundSession.downloadTaskWithResumeData(resumeData)

                    do {
                        let realm = try Realm()

                        try realm.write {
                            download.resumeData = nil
                        }
                    } catch {
                        Log.error("Realm write failed")
                    }
                }
            }

            if let url = download.url where download.downloadTask == nil {
                download.downloadTask = self.backgroundSession.downloadTaskWithURL(url)
            }

            download.state = .Waiting
            download.downloadTask?.resume()
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

        let id = download.downloadId

        dispatch_sync(downloadsLockQueue) {
            if let download = self.getDownloadFromId(id) {
                download.state = .Pausing
                download.downloadTask?.cancelByProducingResumeData({ (data) -> Void in
                    if let download = self.getDownloadFromId(id) {
                        download.state = .Paused

                        do {
                            let realm = try Realm()

                            try realm.write {
                                download.resumeData = data
                            }
                        } catch {
                            Log.error("Realm write failed")
                        }

                        completionHandler?(data)
                    }
                })
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

        let id = download.downloadId

        dispatch_sync(downloadsLockQueue) {
            if let download = self.getDownloadFromId(id) {
                download.downloadTask?.cancel()

                do {
                    let realm = try Realm()

                    try realm.write {
                        download.resumeData = nil
                    }
                } catch {
                    Log.error("Realm write failed")
                }

                download.state = .Cancelled
            }
        }
    }

    public func removeAll() {
        do {
            let realm = try Realm()

            let downloads = Array(realm.objects(FablerDownload))

            _ = downloads.map { $0.remove() }
        } catch {
            Log.error("Realm read failed")
        }
    }

    public func remove(download: FablerDownload) {
        let id = download.downloadId

        dispatch_sync(downloadsLockQueue) {
            if let download = self.getDownloadFromId(id) {
                do {
                    let realm = try Realm()

                    try realm.write {
                        realm.delete(download)
                    }
                } catch {
                    Log.error("Realm write failed")
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
        if let download = getDownloadFromTask(task) {
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
