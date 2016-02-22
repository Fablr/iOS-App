//
//  FablerAutoDownload.swift
//  Fabler
//
//  Created by Christopher Day on 2/18/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import Foundation
import SwiftDate
import RealmSwift

public enum FablerAutoDownloadState: Int {
    case NotStarted = 0
    case Calculating
    case Calculated
    case Downloading
    case Downloaded
    case Errored
}

public class FablerAutoDownload {
    private let queue: dispatch_queue_t
    private var episodes: [Episode]
    private var downloads: [FablerDownload]
    private var token: NotificationToken?

    public var state: FablerAutoDownloadState

    public init() {
        self.queue = dispatch_queue_create("com.Fabler.Fabler.AutoDownloadQueue", nil)
        self.episodes = []
        self.downloads = []
        self.state = .NotStarted
    }

    deinit {
        self.token?.stop()
    }

    public func calculate() {
        guard self.state == .NotStarted || self.state == .Downloaded else {
            return
        }

        self.state = .Calculating

        let service = PodcastService()

        _ = service.getSubscribedPodcasts(self.queue, completion: { podcasts in
            let service = EpisodeService()

            for podcast in podcasts {
                _ = service.getEpisodesForPodcast(podcast, queue: self.queue, completion: { episodes in
                    self.calculateDownloadsForPodcast(podcast, episodes: episodes)
                })
            }
        })

        dispatch_async(self.queue, {
            self.state = .Calculated
        })
    }

    public func download() {
        guard self.state == .Calculated else {
            return
        }

        self.state = .Downloading

        let downloader = FablerDownloadManager.sharedInstance

        for episode in self.episodes {
            if let download = downloader.downloadWithEpisode(episode) {
                self.downloads.append(download)
            }
        }

        if self.token == nil {
            do {
                let realm = try Realm()

                self.token = realm.addNotificationBlock({ _, _ in
                    let finished = self.downloads.filter { $0.state == .Completed || $0.state == .Failed }

                    for download in finished {
                        self.downloads.removeAtIndex(self.downloads.indexOf({ $0 == download })!)
                    }

                    if self.downloads.count == 0 {
                        self.state = .Downloaded
                    }
                })
            } catch {
                self.state = .Errored
            }
        }
    }

    private func calculateDownloadsForPodcast(podcast: Podcast, episodes: [Episode]) {
        let count = podcast.downloadAmount
        let sortedEpisodes = episodes.sort({ (e1: Episode, e2: Episode) -> Bool in
            return e1.pubdate < e2.pubdate
        })
        let localEpisodes = sortedEpisodes.filter { $0.download != nil }

        if localEpisodes.count < count {
            let downloads: [Episode]

            if let last = localEpisodes.first {
                downloads = Array(sortedEpisodes.filter({ $0.pubdate > last.pubdate && $0.download == nil })[0...count - 1])
            } else {
                downloads = Array(sortedEpisodes.filter({ $0.download == nil})[0...count - 1])
            }

            self.episodes.appendContentsOf(downloads)
        }
    }
}
