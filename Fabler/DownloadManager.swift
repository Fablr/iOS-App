//
//  SyncEngine.swift
//  Fabler
//
//  Created by Christopher Day on 11/17/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift
import Alamofire

@objc enum DownloadStatus: Int {
    case NotStarted = 0
    case DownloadStarted = 1
    case DownloadPaused = 2
    case DownloadComplete = 3
    case DeleteOnNextDownload = 4
}

let PodcastDirectory = "podcasts"

public class DownloadManager {

    private let manager: Alamofire.Manager
    private let queue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)
    private var backgroundCompletionHandler: (() -> Void)?

    public let identifier: String

    init(identifier: String) {
        self.identifier = identifier

        let configuration = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(self.identifier)
        self.manager = Alamofire.Manager(configuration: configuration)

        self.manager.delegate.downloadTaskDidFinishDownloadingToURL = self.downloadTaskDidFinishDownloadingToURL
        self.manager.delegate.downloadTaskDidWriteData = self.downloadTaskDidWriteData

        //
        // Only kickoff Auto-download sequence if we get a valid token back from the server and we are not running in the background.
        //
        if UIApplication.sharedApplication().applicationState != UIApplicationState.Background {
            let notificationCenter = NSNotificationCenter.defaultCenter()
            let mainQueue = NSOperationQueue.mainQueue()

            notificationCenter.addObserverForName(TokenDidChangeNotification, object: nil, queue: mainQueue) { _ in
                let service = PodcastService()
                service.readSubscribedPodcasts(self.queue, completion: self.readSubscribedPodcastEpisodes)
            }
        }
    }

    public func setBackgroundCompletionHandler(handler: () -> Void) {
        self.backgroundCompletionHandler = handler
        self.manager.backgroundCompletionHandler = self.backgroundCompletionHandler
    }

    func readSubscribedPodcastEpisodes(podcasts: [Podcast]) {
        let service = EpisodeService()

        for podcast in podcasts {
            service.getEpisodesForPodcast(podcast.id, queue: self.queue, completion: self.calculateDownloadsForEpisodes)
        }
    }

    func calculateDownloadsForEpisodes(episodes: [Episode]) {
        guard episodes.count != 0 else {
            return
        }

        let service = PodcastService()
        let manager = NSFileManager()
        let root = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!.URLByAppendingPathComponent(PodcastDirectory, isDirectory: true)

        let podcast = service.readPodcast(episodes.first!.podcastId, completion: nil)!
        let filteredEpisodes = episodes.sort({ $0.pubdate.compare($1.pubdate) == NSComparisonResult.OrderedAscending })[0...(podcast.downloadAmount - 1)]

        for episode in filteredEpisodes {
            var error: NSError?
            let realm = try! Realm()

            let url = NSURL(string: episode.link)!
            let ext = url.pathExtension!
            let file = root.URLByAppendingPathComponent(String(format: "%d.%s", episode.id, ext))

            let persistedTask = realm.objects(DownloadTask).filter("objectId == %d", episode.id).first

            if persistedTask != nil {
                try! realm.write {
                    episode.downloadStateRaw = DownloadStatus.DownloadStarted.rawValue
                }

                continue
            }

            if episode.completed && !episode.saved {
                try! realm.write {
                    episode.downloadStateRaw = DownloadStatus.DeleteOnNextDownload.rawValue
                }
            }

            switch episode.downloadState {
            case .NotStarted:
                let request = self.manager.download(Alamofire.Method.GET, url.path!, destination: {temporaryURL, response in return file})

                let task = DownloadTask()
                task.sessionIdentifier = self.identifier
                task.taskIdentifier = request.task.taskIdentifier
                task.localPath = file.path!
                task.objectId = episode.id

                try! realm.write {
                    realm.add(task, update: true)
                    episode.downloadStateRaw = DownloadStatus.DownloadStarted.rawValue
                }
            case .DownloadStarted:
                //
                // Download is in progress.
                //
                break
            case .DownloadPaused:
                //
                // Do nothing, allow user to restart download.
                //
                break
            case .DownloadComplete:
                if !(file.checkResourceIsReachableAndReturnError(&error)) {
                    try! realm.write {
                        episode.downloadStateRaw = DownloadStatus.NotStarted.rawValue
                    }
                }
                break
            case .DeleteOnNextDownload:
                if !(file.checkResourceIsReachableAndReturnError(&error)) {
                    try! realm.write {
                        episode.downloadStateRaw = DownloadStatus.NotStarted.rawValue
                    }
                } else {
                    do {
                        try manager.removeItemAtURL(file)
                        try realm.write {
                            episode.downloadStateRaw = DownloadStatus.NotStarted.rawValue
                        }
                    } catch {
                        print("failed to remove file")
                    }
                }
                break
            }
        }
    }

    func downloadTaskDidFinishDownloadingToURL(session: NSURLSession, task: NSURLSessionDownloadTask, url: NSURL) {
        let realm = try! Realm()

        if let sessionId = session.configuration.identifier {
            if let persistedTask = realm.objects(DownloadTask).filter("sessionIdentifier == %@ AND taskIdentifier == %d", sessionId, task.taskIdentifier).first {
                let localURL = NSURL(fileURLWithPath: persistedTask.localPath)

                do {
                    try NSFileManager.defaultManager().moveItemAtURL(url, toURL: localURL)

                    if let episode = realm.objects(Episode).filter("id == %d", persistedTask.objectId).first {
                        try realm.write {
                            episode.downloadStateRaw = DownloadStatus.DownloadComplete.rawValue
                            realm.delete(persistedTask)
                        }
                    }
                } catch {
                    print("failed to move file")
                }
            }
        }
    }

    func downloadTaskDidWriteData (session: NSURLSession, task: NSURLSessionDownloadTask, read: Int64, totalRead: Int64, expected: Int64) {
        let realm = try! Realm()

        if let sessionId = session.configuration.identifier {
            let persistedTask = realm.objects(DownloadTask).filter("sessionIdentifier == %@ AND taskIdentifier == %d", sessionId, task.taskIdentifier).first

            try! realm.write {
                persistedTask?.readBytes = read
                persistedTask?.totalBytes = totalRead
                persistedTask?.expectedBytes = expected
            }
        }
    }
}
