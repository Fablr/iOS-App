//
//  FablerDownloader.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

//
// This code is based off https://github.com/Gurpartap/Fabler below is the license.
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

public protocol FablerDownloadManagerDelegate: class {
    func Fabler(manager: FablerDownloadManager, failedToMoveFileForDownload: FablerDownload, error: NSError)
    func Fabler(manager: FablerDownloadManager, completedDownload: FablerDownload, error: NSError?)
    func Fabler(manager: FablerDownloadManager, receivedChallengeForDownload: FablerDownload, challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void)
    func Fabler(manager: FablerDownloadManager, backgroundSessionBecameInvalidWithError: NSError?)
}

public protocol FablerDownloadDelegate: class {
    func download(download: FablerDownload, stateChanged toState: FablerDownloadState, fromState: FablerDownloadState)
    func download(download: FablerDownload, progressChanged fractionCompleted: Float, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
}

public enum FablerDownloadState {
    case Unknown
    case Waiting
    case Downloading
    case Pausing
    case Paused
    case Completed
    case Cancelled
}

public class FablerDownload: NSObject {

    // MARK: - public members

    public weak var delegate: FablerDownloadDelegate?
    public var url: NSURL
    public var resumeData: NSData?
    public var fractionCompleted: Float = 0

    // MARK: - private members

    private let manager: FablerDownloadManager
    private var downloadTask: NSURLSessionDownloadTask?

    // MARK: - computed members

    public private(set) var lastState: FablerDownloadState
    public private(set) var state: FablerDownloadState {
        willSet {
            lastState = state
        }
        didSet {
            delegate?.download(self, stateChanged: state, fromState: lastState)
        }
    }

    public private(set) var totalBytesExpectedToWrite: Int64
    public private(set) var totalBytesWritten: Int64 {
        didSet {
            if totalBytesExpectedToWrite > 0 {
                fractionCompleted = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            } else {
                fractionCompleted = 0
            }

            delegate?.download(self, progressChanged: fractionCompleted, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
        }
    }

    // MARK: - private functions

    private init(url: NSURL, manager: FablerDownloadManager) {
        self.url = url
        self.manager = manager
        self.state = .Unknown
        self.lastState = .Unknown
        self.totalBytesExpectedToWrite = 0
        self.totalBytesWritten = 0
    }

    // MARK: - public functions

    public func resume() {
        if let resumeData = resumeData {
            downloadTask?.cancel()
            downloadTask = manager.backgroundSession.downloadTaskWithResumeData(resumeData)
            self.resumeData = nil
        }

        if downloadTask == nil {
            downloadTask = manager.backgroundSession.downloadTaskWithURL(url)
        }

        state = .Waiting
        downloadTask?.resume()
    }

    public func pause(completionHandler: (NSData? -> Void)? = nil) {
        state = .Pausing
        downloadTask?.cancelByProducingResumeData({ (data) -> Void in
            self.state = .Paused
            self.resumeData = data
            completionHandler?(data)
        })
    }

    public func cancel() {
        downloadTask?.cancel()
        state = .Cancelled
    }

    public func remove() {
        cancel()

        dispatch_sync(manager.downloadsLockQueue) {
            if let index = self.manager.downloads.indexOf({ $0 == self }) {
                self.manager.downloads.removeAtIndex(index)
            }
        }
    }
}

public func == (lhs: FablerDownload, rhs: FablerDownload) -> Bool {
    return lhs.url.isEqual(rhs.url)
}

public class FablerDownloadManager: NSObject, NSURLSessionDownloadDelegate, NSURLSessionDelegate {

    // MARK: - public members

    public weak var delegate: FablerDownloadManagerDelegate?
    public var downloads: Array<FablerDownload>
    public var backgroundSessionCompletionHandler: (() -> Void)?
    public var downloadCompletionHandler: ((FablerDownload, NSURLSession, NSURL) -> NSURL?)?

    // MARK: - private members

    private let downloadsLockQueue: dispatch_queue_t
    private let backgroundSessionIdentifier: String
    private lazy var backgroundSession: NSURLSession = self.newBackgroundURLSession()

    // MARK: - private functions

    private func newBackgroundURLSession() -> NSURLSession {
        let backgroundSessionConfiguration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(backgroundSessionIdentifier)
        return NSURLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: nil)
    }

    private func handleDownloadTaskWithProgress(downloadTask: NSURLSessionDownloadTask, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if let download = getDownloadFromTask(downloadTask) {
            if download.state != .Downloading {
                download.state = .Downloading
            }

            download.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            download.totalBytesWritten = totalBytesWritten
        }
    }

    private func getDownloadFromTask(task: NSURLSessionTask) -> FablerDownload? {
        var download: FablerDownload?

        if let url = task.originalRequest?.URL {
            dispatch_sync(downloadsLockQueue) {
                if let foundAtIndex = self.downloads.indexOf({ $0.url == url }) {
                    download = self.downloads[foundAtIndex]
                }
            }
        }

        return download
    }

    // MARK: - public functions

    public required init(backgroundSessionIdentifier: String) {
        self.downloads = Array<FablerDownload>()
        self.downloadsLockQueue = dispatch_queue_create("com.Fabler.Fabler.downloadQueue", nil)
        self.backgroundSessionIdentifier = backgroundSessionIdentifier

        super.init()
    }

    public func downloadWithURL(url: NSURL, delegate: FablerDownloadDelegate?, resumeData: NSData? = nil) -> FablerDownload {
        var download = FablerDownload(url: url, manager: self)

        dispatch_sync(downloadsLockQueue) {
            if let foundAtIndex = self.downloads.indexOf({ $0 == download }) {
                download = self.downloads[foundAtIndex]
            } else {
                self.downloads.append(download)
            }
        }

        download.delegate = delegate
        download.resumeData = resumeData

        return download
    }

    public func resumeAll() {
        dispatch_sync(downloadsLockQueue) {
            _ = self.downloads.map { $0.resume() }
        }
    }

    public func pauseAll() {
        dispatch_sync(downloadsLockQueue) {
            _ = self.downloads.map { $0.pause() }
        }
    }

    public func cancelAll() {
        dispatch_sync(downloadsLockQueue) {
            _ = self.downloads.map { $0.cancel() }
        }
    }

    public func removeAll() {
        dispatch_sync(downloadsLockQueue) {
            _ = self.downloads.map { $0.cancel() }
            self.downloads.removeAll()
        }
    }

    // MARK: - NSURLSessionDownloadDelegate

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        if let download = getDownloadFromTask(downloadTask) {
            download.state = .Completed
            if let moveTo = downloadCompletionHandler?(download, session, location) {
                do {
                    try NSFileManager.defaultManager().moveItemAtURL(location, toURL: moveTo)
                } catch let error as NSError {
                    self.delegate?.Fabler(self, failedToMoveFileForDownload: download, error: error)
                }
            }
        }
    }

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
        handleDownloadTaskWithProgress(downloadTask, totalBytesWritten: fileOffset, totalBytesExpectedToWrite: expectedTotalBytes)
    }

    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        handleDownloadTaskWithProgress(downloadTask, totalBytesWritten: totalBytesWritten, totalBytesExpectedToWrite: totalBytesExpectedToWrite)
    }

    // MARK: - NSURLSessionTaskDelegate

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if let download = getDownloadFromTask(task) {
            delegate?.Fabler(self, receivedChallengeForDownload: download, challenge: challenge, completionHandler: completionHandler)
        }
    }

    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let download = getDownloadFromTask(task) {
            delegate?.Fabler(self, completedDownload: download, error: error)
        }
    }

    // MARK: - NSURLSessionDelegate

    public func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?) {
        delegate?.Fabler(self, backgroundSessionBecameInvalidWithError: error)
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
