//
//  FablerDownload.swift
//  Fabler
//
//  Created by Christopher Day on 1/14/16.
//  Copyright © 2016 Fabler. All rights reserved.
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

public enum FablerDownloadState: Int {
    case Unknown = 0
    case Waiting
    case Downloading
    case Pausing
    case Paused
    case Completed
    case Cancelled
    case Failed
}

public class FablerDownload: Object {

    // MARK: - Public members

    public var url: NSURL? {
        didSet {
            if let url = url {
                do {
                    let realm = try Realm()

                    try realm.write {
                        urlString = url.URLString
                    }
                } catch {
                    Log.error("Realm write failed")
                }
            }
        }
    }

    private var _localUrl: NSURL?
    public var localUrl: NSURL? {
        set(value) {
            self._localUrl = value

            if let localUrl = self._localUrl {
                do {
                    let realm = try Realm()

                    try realm.write {
                        localUrlString = localUrl.URLString
                    }
                } catch {
                    Log.error("Realm write failed")
                }
            }
        }
        get {
            if self._localUrl != nil {
                return self._localUrl
            } else {
                return NSURL(string: self.localUrlString)
            }
        }
    }

    public private(set) var lastState: FablerDownloadState {
        set(value) {
            do {
                let realm = try Realm()

                try realm.write {
                    lastStateRaw = value.rawValue
                }
            } catch {
                Log.error("Realm write failed")
            }
        }
        get {
            return FablerDownloadState(rawValue: lastStateRaw)!
        }
    }
    public var state: FablerDownloadState {
        set(value) {
            do {
                let realm = try Realm()

                try realm.write {
                    lastStateRaw = stateRaw
                    stateRaw = value.rawValue
                }
            } catch {
                Log.error("Realm write failed")
            }
        }
        get {
            return FablerDownloadState(rawValue: stateRaw)!
        }
    }

    public var totalBytesWritten: Int {
        set(value) {
            do {
                let realm = try Realm()

                try realm.write {
                    totalBytesWrittenRaw = value

                    if totalBytesRaw > 0 {
                        fractionCompleted = Float(value) / Float(totalBytesRaw)
                    } else {
                        fractionCompleted = 0
                    }
                }
            } catch {
                Log.error("Realm write failed")
            }
        }
        get {
            return self.totalBytesWrittenRaw
        }
    }

    public var totalBytes: Int {
        set(value) {
            do {
                let realm = try Realm()

                try realm.write {
                    totalBytesRaw = value
                }
            } catch {
                Log.error("Realm write failed")
            }
        }
        get {
            return self.totalBytesWrittenRaw
        }
    }

    public let manager: FablerDownloadManager = FablerDownloadManager.sharedInstance
    public var downloadTask: NSURLSessionDownloadTask?

    // MARK: - Presisted members

    dynamic var resumeData: NSData? = nil
    dynamic var fractionCompleted: Float = 0
    dynamic var lastStateRaw: Int = 0
    dynamic var stateRaw: Int = 0
    dynamic var totalBytesRaw: Int = 0
    dynamic var totalBytesWrittenRaw: Int = 0
    dynamic var urlString: String = ""
    dynamic var localUrlString: String = ""

    // MARK: - Public methods

    public func resume() {
        guard self.state == .Failed || self.state == .Paused || self.state == .Pausing || self.state == .Cancelled else {
            Log.warning("Invalid state to resume download from")
            return
        }

        self.manager.resume(self)
    }

    public func pause(completionHandler: (NSData? -> Void)? = nil) {
        guard self.state == .Downloading else {
            Log.warning("Invalid state to pause download from")
            return
        }

        self.manager.pause(self, completionHandler: completionHandler)
    }

    public func cancel() {
        guard self.state == .Downloading else {
            Log.warning("Invalid state to cancel download from")
            return
        }

        manager.cancel(self)
    }

    public func remove() {
        guard self.state == .Completed else {
            Log.warning("Invalid state to remove download from")
            return
        }

        manager.remove(self)
    }

    // MARK: - Realm methods

    override public static func ignoredProperties() -> [String] {
        return ["url", "_localUrl", "localUrl", "lastState", "state", "totalBytesWritten", "totalBytes", "manager", "downloadTask"]
    }
}

public func == (lhs: FablerDownload, rhs: FablerDownload) -> Bool {
    return lhs.url != nil && lhs.url!.isEqual(rhs.url)
}
