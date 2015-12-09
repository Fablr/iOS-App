//
//  PodcastService.swift
//  Fabler
//
//  Created by Christopher Day on 10/30/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import Alamofire
import SwiftyJSON
import RealmSwift

class PodcastService {

    // MARK: - PodcastService functions

    init() {
    }

    // MARK: - PodcastService API functions

    func setNotificationForPodcast(podcast: Podcast, allowNotifications: Bool) {
        do {
            let realm = try Realm()

            try realm.write {
                podcast.notify = allowNotifications
            }
        } catch {
            Log.error("Realm write failed.")
        }
    }

    func setDownloadForPodcast(podcast: Podcast, allowAutoDownload: Bool) {
        do {
            let realm = try Realm()

            try realm.write {
                podcast.download = allowAutoDownload
            }
        } catch {
            Log.error("Realm write failed.")
        }
    }

    func setDownloadAmountForPodcast(podcast: Podcast, amount: Int) {
        do {
            let realm = try Realm()

            try realm.write {
                podcast.downloadAmount = amount
            }
        } catch {
            Log.error("Realm write failed.")
        }
    }

    func readPodcast(podcastId: Int, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: Podcast?) -> Void)?) -> Podcast? {
        if let completion = completion {
            let request = Alamofire
            .request(FablerClient.Router.ReadPodcasts())
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    self.serializePodcastObject(json)
                case .Failure(let error):
                    Log.error("Podcast request failed with \(error).")
                }

                dispatch_async(queue, {completion(result: self.readPodcastFromRealm(podcastId))})
            }

            Log.debug("Read podcast request: \(request)")
        }

        return readPodcastFromRealm(podcastId)
    }

    private func readPodcastFromRealm(podcastId: Int) -> Podcast? {
        var podcast: Podcast? = nil

        do {
            let realm = try Realm()

            podcast = realm.objects(Podcast).filter("podcastId == %d", podcastId).first
        } catch {
            Log.error("Realm read failed.")
        }

        return podcast
    }

    func readAllPodcasts(queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: [Podcast]) -> Void)?) -> [Podcast] {
        if let completion = completion {
            let request = Alamofire
            .request(FablerClient.Router.ReadPodcasts())
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    self.serializePodcastCollection(json)
                case .Failure(let error):
                    Log.error("Podcasts request failed with \(error).")
                }

                dispatch_async(queue, {completion(result: self.readAllPodcastsFromRealm())})
            }

            Log.debug("Read podcasts request: \(request)")
        }

        return self.readAllPodcastsFromRealm()
    }

    private func readAllPodcastsFromRealm() -> [Podcast] {
        var podcasts: [Podcast] = []

        do {
            let realm = try Realm()

            podcasts = Array(realm.objects(Podcast))
        } catch {
            Log.error("Realm read failed.")
        }

        return podcasts
    }

    func readSubscribedPodcasts(queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: [Podcast]) -> Void)?) -> [Podcast] {
        if let completion = completion {
            let request = Alamofire
            .request(FablerClient.Router.ReadSubscribedPodcasts())
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    let local_podcasts = self.readSubscribedPodcastsFromRealm()
                    let server_podcasts = self.serializePodcastCollection(json)
                    self.updateUnsubscribedPodcasts(local_podcasts, server: server_podcasts)
                case .Failure(let error):
                    Log.error("Subscribed podcasts request failed with \(error).")
                }

                dispatch_async(queue, {completion(result: self.readSubscribedPodcastsFromRealm())})
            }

            Log.debug("Subscribed podcasts request: \(request)")
        }

        return self.readSubscribedPodcastsFromRealm()
    }

    private func readSubscribedPodcastsFromRealm() -> [Podcast] {
        var podcasts: [Podcast] = []

        do {
            let realm = try Realm()

            podcasts = Array(realm.objects(Podcast).filter("subscribed == YES"))
        } catch {
            Log.error("Realm read failed.")
        }

        return podcasts
    }

    func subscribeToPodcast(podcast: Podcast, subscribe: Bool, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        do {
            let realm = try Realm()

            try realm.write {
                podcast.subscribed = subscribe
            }
        } catch {
            Log.error("Realm write failed.")
        }

        let request = Alamofire
        .request(FablerClient.Router.SubscribeToPodcast(podcast: podcast.podcastId, subscribe: subscribe))
        .validate(statusCode: 200..<202)
        .responseJSON { response in
            switch response.result {
            case .Success:
                dispatch_async(queue, {completion(result: true)})
            case .Failure(let error):
                Log.error("Subscription request failed with \(error).")

                do {
                    let responseRealm = try Realm()

                    try responseRealm.write {
                        podcast.subscribed = !subscribe
                    }
                } catch {
                    Log.error("Realm write failed.")
                }

                dispatch_async(queue, {completion(result: false)})
            }
        }

        Log.debug("Subscription request: \(request)")
    }

    // MARK: - PodcastService serialize functions

    private func serializePodcastObject(data: JSON) -> Podcast? {
        let podcast = Podcast()

        if let id = data["id"].int {
            podcast.podcastId = id
        }

        if let title = data["title"].string {
            podcast.title = title
        }

        if let author = data["author"].string {
            podcast.author = author
        }

        if let explicit = data["explicit"].bool {
            podcast.explicit = explicit
        }

        if let subscribed = data["subscribed"].bool {
            podcast.subscribed = subscribed
        }

        if let publisherName = data["subscribed"].string {
            podcast.publisherName = publisherName
        }

        if let publisherId = data["publisher"].int {
            podcast.publisherId = publisherId
        }

        if let summary = data["summary"].string {
            podcast.summary = summary
        }

        if let category = data["category"].string {
            podcast.category = category
        }

        if let image = data["image"].string {
            podcast.image = image
        }

        do {
            let realm = try Realm()

            try realm.write {
                realm.add(podcast, update: true)
            }
        } catch {
            Log.error("Realm write failed.")
        }

        return podcast
    }

    private func serializePodcastCollection(data: JSON) -> [Podcast] {
        var podcasts: [Podcast] = []

        for (_, subJson):(String, JSON) in data {
            do {
                if let podcast = serializePodcastObject(subJson) {
                    podcasts.append(podcast)
                }
            }
        }

        return podcasts
    }

    // MARK: - PodcastService helper functions

    private func updateUnsubscribedPodcasts(local: [Podcast], server: [Podcast]) {
        do {
            let realm = try Realm()

            for podcast in local {
                if !server.contains(podcast) {
                    try realm.write {
                        podcast.subscribed = false
                    }
                }
            }
        } catch {
            Log.error("Realm write failed.")
        }
    }
}
