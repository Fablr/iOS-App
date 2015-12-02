//
//  SyncEngine.swift
//  Fabler
//
//  Created by Christopher Day on 11/17/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift
import Alamofire

// MARK: - DownloadManager Enums

enum DownloadManagerError: ErrorType {
    case ObjectDidNotInheritFromDownloadObject
    case ObjectDoesNotHavePrimaryKey
    case ObjectAlreadyDownloading
    case ObjectHasInvalidServerURL
    case ObjectDownloadHasNotStarted
}

enum DownloadStatus: Int {
    case NotStarted = 0
    case DownloadStarted = 1
    case DownloadPaused = 2
    case DownloadComplete = 3
}

// MARK: - PersistedTask

final class PersistedTask: Object {

    // MARK: - Members

    dynamic var sessionIdentifier: String = ""
    dynamic var taskIdentifier: Int = 0
    dynamic var objectKey: Int = 0
    dynamic var objectType: String = ""
}

// MARK: - DownloadObject

class DownloadObject: Object {

    // MARK: - Members

    dynamic var downloadStateRaw: Int = 0
    dynamic var readBytes: Int = 0
    dynamic var totalBytes: Int = 0
    dynamic var expectedBytes: Int = 0
    dynamic var localPath: String = ""
    dynamic var serverPath: String = ""

    // MARK: - Computed properties

    var downloadState: DownloadStatus {
        get {
            if let state = DownloadStatus(rawValue: self.downloadStateRaw) {
                return state
            }

            return DownloadStatus.NotStarted
        }
    }

    // MARK: - Methods

    func primaryKeyValue() -> Int? {
        preconditionFailure("This method must be overriden to support DownloadObject.")
    }
}

// MARK: - DownloadManager

public class DownloadManager {

    // MARK: - Members

    private let manager: Alamofire.Manager
    private var backgroundCompletionHandler: (() -> Void)?

    public let identifier: String

    // MARK: - Methods

    init(identifier: String) {
        self.identifier = identifier

        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(self.identifier)
        self.manager = Alamofire.Manager(configuration: configuration)

        self.manager.delegate.downloadTaskDidFinishDownloadingToURL = self.downloadTaskDidFinishDownloadingToURL
        self.manager.delegate.downloadTaskDidWriteData = self.downloadTaskDidWriteData
    }

    public func setBackgroundCompletionHandler(handler: () -> Void) {
        self.backgroundCompletionHandler = handler
        self.manager.backgroundCompletionHandler = self.backgroundCompletionHandler
    }

    func initiateDownload(object: Object) throws {
        let realm = try Realm()

        guard let download = object as? DownloadObject else {
            throw DownloadManagerError.ObjectDidNotInheritFromDownloadObject
        }

        guard let objectKey = download.primaryKeyValue() else {
            throw DownloadManagerError.ObjectDoesNotHavePrimaryKey
        }

        let objectType = object.className

        let persistedTask = realm.objects(PersistedTask).filter("objectType == %@ AND objectKey == %d", objectType, objectKey).first

        guard persistedTask != nil else {
            try realm.write {
                object.setValue(DownloadStatus.DownloadStarted.rawValue, forKey: "downloadStateRaw")
            }

            throw DownloadManagerError.ObjectAlreadyDownloading
        }

        if let url = NSURL(string: download.serverPath) {
            let localURL = NSURL(fileURLWithPath: download.localPath)
            let mutableURLRequest = NSMutableURLRequest(URL: url)
            mutableURLRequest.HTTPMethod = Alamofire.Method.GET.rawValue
            let request = self.manager.download(mutableURLRequest, destination: {temporaryURL, response in return localURL})

            let persistedTask = PersistedTask()
            persistedTask.sessionIdentifier = self.identifier
            persistedTask.taskIdentifier = request.task.taskIdentifier
            persistedTask.objectType = objectType
            persistedTask.objectKey = objectKey

            try realm.write {
                realm.add(persistedTask, update: true)
                object.setValue(DownloadStatus.DownloadStarted.rawValue, forKey: "downloadStateRaw")
            }
        } else {
            throw DownloadManagerError.ObjectHasInvalidServerURL
        }
    }

    func pauseDownload(object: Object) throws {
        let realm = try Realm()

        guard let download = object as? DownloadObject else {
            throw DownloadManagerError.ObjectDidNotInheritFromDownloadObject
        }

        guard let objectKey = download.primaryKeyValue() else {
            throw DownloadManagerError.ObjectDoesNotHavePrimaryKey
        }

        let objectType = object.className

        guard let _ = realm.objects(PersistedTask).filter("objectType == %@ AND objectKey == %d", objectType, objectKey).first else {
            throw DownloadManagerError.ObjectDownloadHasNotStarted
        }

        // get task

        // cancel task

        // write data out to file

        try realm.write {
            object.setValue(DownloadStatus.DownloadPaused.rawValue, forKey: "downloadStateRaw")
        }
    }

    func resumeDownload(object: Object) throws {
        let realm = try Realm()

        // get data

        // resume download with data

        // create persisted task

        try realm.write {
            object.setValue(DownloadStatus.DownloadStarted.rawValue, forKey: "downloadStateRaw")
        }
    }

    // MARK: - Private Methods

    private func downloadTaskDidFinishDownloadingToURL(session: NSURLSession, task: NSURLSessionDownloadTask, url: NSURL) {
        do {
            let realm = try Realm()

            if let sessionId = session.configuration.identifier {
                if let persistedTask = realm.objects(PersistedTask).filter("sessionIdentifier == %@ AND taskIdentifier == %d", sessionId, task.taskIdentifier).first {
                    if let object = realm.dynamicObjectForPrimaryKey(persistedTask.objectType, key: persistedTask.objectKey), let urlString = object.valueForKey("localPath") as? String {
                        do {
                            let localURL = NSURL(fileURLWithPath: urlString)
                            try NSFileManager.defaultManager().moveItemAtURL(url, toURL: localURL)
                        } catch {
                            try realm.write {
                                object.setValue(url.path, forKey: "localPath")
                            }
                        }

                        try realm.write {
                            object.setValue(DownloadStatus.DownloadComplete.rawValue, forKey: "downloadStateRaw")
                            realm.delete(persistedTask)
                        }
                    }
                }
            }
        } catch {
            fatalError("Realm is unavailable.")
        }
    }

    private func downloadTaskDidWriteData (session: NSURLSession, task: NSURLSessionDownloadTask, read: Int64, totalRead: Int64, expected: Int64) {
        do {
            let realm = try Realm()

            if let sessionId = session.configuration.identifier, let persistedTask = realm.objects(PersistedTask).filter("sessionIdentifier == %@ AND taskIdentifier == %d", sessionId, task.taskIdentifier).first {
                if let object = realm.dynamicObjectForPrimaryKey(persistedTask.objectType, key: persistedTask.objectKey) {
                    try realm.write {
                        object.setValue(Int(read), forKey: "readBytes")
                        object.setValue(Int(totalRead), forKey: "totalBytes")
                        object.setValue(Int(expected), forKey: "expectedBytes")
                    }
                }
            }
        } catch {
            fatalError("Realm is unavailable.")
        }
    }
}
