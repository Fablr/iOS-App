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
import Kingfisher

public enum FablerAutoDownloadState {
    case NotRunning
    case CalculatingEpisodes
    case DownloadingEpisodes
    case CachingImages
    case Errored
}

public enum FablerAutoDownloadTask {
    case CalculateEpisodes
    case DownloadEpisodes
    case CacheImages
}

public class FablerAutoDownload {

    // MARK: - singleton

    public static let sharedInstance = FablerAutoDownload()

    // MARK: - private members

    private var tasks: [FablerAutoDownloadTask] = []
    private let queue: dispatch_queue_t = dispatch_queue_create("com.Fabler.Fabler.AutoDownloadQueue", nil)
    private var episodes: [Episode] = []
    private var downloads: [FablerDownload] = []
    private var token: NotificationToken? = nil
    private var podcasts: Int = 0

    // MARK: - public members

    public var state: FablerAutoDownloadState = .NotRunning

    // MARK: - public methods

    deinit {
        self.token?.stop()
    }

    public func addTask(task: FablerAutoDownloadTask) {
        dispatch_async(self.queue, {
            self.tasks.insert(task, atIndex: 0)

            if self.tasks.count == 1 {
                self.performNextTask()
            }
        })
    }

    public func suspend() {
        dispatch_suspend(self.queue)
    }

    public func resume() {
        dispatch_resume(self.queue)
    }

    // MARK: - private methods

    private func performNextTask() {
        guard self.state != .Errored else {
            return
        }

        if let task = self.tasks.popLast() {
            switch task {
            case .CalculateEpisodes:
                self.calculateEpisodes()
            case .DownloadEpisodes:
                self.downloadEpisodes()
            case .CacheImages:
                self.cacheImages()
            }
        } else {
            self.state = .NotRunning
        }
    }

    private func calculateEpisodes() {
        self.state = .CalculatingEpisodes

        let service = PodcastService()

        _ = service.getSubscribedPodcasts(self.queue, completion: { podcasts in
            let service = EpisodeService()

            self.podcasts = podcasts.count

            for podcast in podcasts {
                _ = service.getEpisodesForPodcast(podcast, queue: self.queue, completion: { episodes in
                    self.calculateDownloadsForPodcast(podcast, episodes: episodes)

                    self.podcasts -= 1

                    if self.podcasts == 0 {
                        dispatch_async(self.queue, {
                            self.performNextTask()
                        })
                    }
                })
            }
        })
    }

    private func downloadEpisodes() {
        self.state = .DownloadingEpisodes

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
                        self.performNextTask()
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

    private func cacheImages() {
        self.state = .CachingImages

        let podcastService = PodcastService()

        _ = podcastService.getSubscribedPodcasts(self.queue, completion: { (podcasts) in
            Log.info("Caching subscribed podcast images.")

            let manager = KingfisherManager.sharedManager
            let cache = manager.cache

            for podcast in podcasts {
                let id = podcast.podcastId
                let key = "\(id)-header-blurred"

                if let _ = cache.retrieveImageInDiskCacheForKey(key) {
                    Log.debug("Skipping images for podcast \(id).")
                    continue
                }

                if let url = NSURL(string: podcast.image) {
                    self.podcasts += 1

                    manager.retrieveImageWithURL(url, optionsInfo: [.CallbackDispatchQueue(self.queue)], progressBlock: nil, completionHandler: { (image, error, cacheType, url) in
                        if error == nil, let image = image {
                            Log.info("Blurring image for '\(key)'")
                            if let blurred = image.imageWithAppliedCoreImageFilter("CIGaussianBlur", filterParameters: ["inputRadius": 25.0]) {
                                Log.info("Cached image at '\(key)'.")
                                cache.storeImage(blurred, forKey: key)
                            }
                        }

                        self.podcasts -= 1

                        if self.podcasts == 0 {
                            self.performNextTask()
                        }
                    })
                }
            }

            if self.podcasts == 0 {
                self.performNextTask()
            }
        })
    }
}
