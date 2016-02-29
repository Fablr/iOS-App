//
//  FablerAutoDownload.swift
//  Fabler
//
//  Created by Christopher Day on 2/18/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import Foundation
import SwiftDate
import Kingfisher
import RxSwift
import RxCocoa

public enum FablerAutoDownloadState {
    case NotRunning
    case CalculatingEpisodes
    case DownloadingEpisodes
    case CachingImages
    case DeletingEpisodes
    case Errored
}

public enum FablerAutoDownloadTask {
    case CalculateEpisodes
    case DownloadEpisodes
    case CacheImages
    case DeleteEpisodes
}

public class FablerAutoDownload {

    // MARK: - singleton

    public static let sharedInstance = FablerAutoDownload()

    // MARK: - private members

    private var tasks: [FablerAutoDownloadTask] = []
    private let queue: dispatch_queue_t = dispatch_queue_create("com.Fabler.Fabler.AutoDownloadQueue", nil)
    private var episodes: [Int] = []
    private var downloads: [FablerDownload] = []
    private var bag: DisposeBag! = DisposeBag()
    private var podcasts: Int = 0

    // MARK: - public members

    public var state: FablerAutoDownloadState = .NotRunning

    // MARK: - public methods

    deinit {
        self.bag = nil
    }

    public func addTask(task: FablerAutoDownloadTask) {
        Log.info("Adding task to AutoDownload")

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
            Log.error("AutoDownload is in error state")
            return
        }

        Log.info("AutoDownload performing next task")

        if let task = self.tasks.last {
            switch task {
            case .CalculateEpisodes:
                self.calculateEpisodes()
            case .DownloadEpisodes:
                self.downloadEpisodes()
            case .CacheImages:
                self.cacheImages()
            case .DeleteEpisodes:
                self.deleteEpisodes()
            }
        } else {
            self.state = .NotRunning
        }
    }

    private func completeTask() {
        _ = self.tasks.popLast()
        self.bag = DisposeBag()
        self.performNextTask()
    }

    private func calculateEpisodes() {
        Log.info("AutoDownload is calculating episodes to download")

        self.state = .CalculatingEpisodes

        let service = PodcastService()

        _ = service.getSubscribedPodcasts(self.queue, completion: { podcasts in
            Log.info("AutoDownload calculating episodes podcast callback")

            let service = EpisodeService()

            self.podcasts = podcasts.count

            for podcast in podcasts {
                let count = podcast.downloadAmount
                _ = service.getEpisodesForPodcast(podcast, queue: self.queue, completion: { episodes in
                    Log.info("AutoDownload calculating episodes episode callback")

                    self.calculateDownloadsForPodcast(count, episodes: episodes)

                    self.podcasts -= 1

                    if self.podcasts == 0 {
                        dispatch_async(self.queue, {
                            self.completeTask()
                        })
                    }
                })
            }
        })
    }

    private func downloadEpisodes() {
        Log.info("AutoDownload downloading episodes")

        self.state = .DownloadingEpisodes

        let downloader = FablerDownloadManager.sharedInstance

        for id in self.episodes {
            let service = EpisodeService()

            if let episode = service.getEpisodeFor(id, completion: nil), let download = downloader.downloadWithEpisode(episode) {
                Log.info("AutoDownloading episode")
                self.downloads.append(download)

                download.rx_observe(FablerDownloadState.self, "state")
                .subscribeNext({ state in
                    Log.info("AutoDownload removing completed downloads")

                    let finished = self.downloads.filter { $0.state == .Completed || $0.state == .Failed }

                    for download in finished {
                        self.downloads.removeAtIndex(self.downloads.indexOf({ $0 == download })!)
                    }

                    if self.downloads.count == 0 {
                        dispatch_async(self.queue, {
                            Log.info("AutoDownload downloads finished")
                            self.episodes.removeAll()
                            self.completeTask()
                        })
                    }
                })
                .addDisposableTo(self.bag)
            }
        }

        if self.downloads.count == 0 {
            Log.info("AutoDownload downloads finished")
            self.episodes.removeAll()
            self.completeTask()
        }
    }

    private func calculateDownloadsForPodcast(count: Int, episodes: [Episode]) {
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

            _ = downloads.map { self.episodes.append($0.episodeId) }
        }
    }

    private func cacheImages() {
        self.state = .CachingImages

        let service = PodcastService()

        _ = service.getSubscribedPodcasts(self.queue, completion: { (podcasts) in
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
                            self.completeTask()
                        }
                    })
                }
            }

            if self.podcasts == 0 {
                self.completeTask()
            }
        })
    }

    private func deleteEpisodes() {
        Log.info("AutoDownload deleting old episodes")

        self.state = .DeletingEpisodes

        let podcastService = PodcastService()
        let episodeService = EpisodeService()

        let podcasts = podcastService.getSubscribedPodcasts(completion: nil)

        for podcast in podcasts {
            let episodes = episodeService.getEpisodesForPodcast(podcast, completion: nil)
            let filteredEpisodes = episodes.filter({ $0.completed && !($0.saved) && ($0.download != nil) })

            for episode in filteredEpisodes {
                episode.download?.remove()
            }
        }

        self.completeTask()
    }
}
