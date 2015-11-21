//
//  SyncEngine.swift
//  Fabler
//
//  Created by Christopher Day on 11/17/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import CoreData
import Alamofire

@objc enum DownloadStatus: Int {
    case NotStarted = 0
    case DownloadStarted = 1
    case DownloadPaused = 2
    case DownloadComplete = 3
    case DeleteOnNextDownload = 4
}

let PodcastDirectory = "podcasts"

class DownloadManager {

    var queue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    }

    init() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        //
        // Only kickoff Auto-download sequence if we get a valid token
        // back from the server.
        //
        notificationCenter.addObserverForName(TokenDidChangeNotification, object: nil, queue: mainQueue) { _ in
            let service = PodcastService()
            service.readSubscribedPodcasts(self.queue, completion: self.readSubscribedPodcastEpisodes)
        }
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
            let url = NSURL(string: episode.link)!
            let ext = url.pathExtension!
            let file = root.URLByAppendingPathComponent(String(format: "%d.%s", episode.id, ext))

            switch episode.downloadState {
            case .NotStarted:
                _ = Alamofire
                .download(Alamofire.Method.GET, url.path!, destination: {temporaryURL, response in return file})
                .progress { bytesRead, totalBytesRead, totalBytesExpectedToRead in

                }
                .response { _, _, data, error in

                }
                break
            case .DownloadStarted:
                // ensure download is started
                break
            case .DownloadPaused:
                //
                // Do nothing, allow user to restart download.
                //
                break
            case .DownloadComplete:
                break
            case .DeleteOnNextDownload:
                // delete from local cache
                break
            }
        }
    }
}
