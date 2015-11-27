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
        let realm = try! Realm()

        try! realm.write {
            podcast.notify = allowNotifications
        }
    }

    func setDownloadForPodcast(podcast: Podcast, allowAutoDownload: Bool) {
        let realm = try! Realm()

        try! realm.write {
            podcast.download = allowAutoDownload
        }
    }

    func setDownloadAmountForPodcast(podcast: Podcast, amount: Int) {
        let realm = try! Realm()

        try! realm.write {
            podcast.downloadAmount = amount
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
                    print(error)
                }

                dispatch_async(queue, {completion(result: self.readPodcastFromRealm(podcastId))})
            }

            debugPrint(request)
        }

        return readPodcastFromRealm(podcastId)
    }

    private func readPodcastFromRealm(podcastId: Int) -> Podcast? {
        let realm = try! Realm()

        return realm.objects(Podcast).filter("podcastId == %d", podcastId).first
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
                    print(error)
                }

                dispatch_async(queue, {completion(result: self.readAllPodcastsFromRealm())})
            }

            debugPrint(request)
        }

        return self.readAllPodcastsFromRealm()
    }

    private func readAllPodcastsFromRealm() -> [Podcast] {
        let realm = try! Realm()

        return Array(realm.objects(Podcast))
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
                    print(error)
                }

                dispatch_async(queue, {completion(result: self.readSubscribedPodcastsFromRealm())})
            }

            debugPrint(request)
        }

        return self.readSubscribedPodcastsFromRealm()
    }

    private func readSubscribedPodcastsFromRealm() -> [Podcast] {
        let realm = try! Realm()

        return Array(realm.objects(Podcast).filter("subscribed == YES"))
    }

    func subscribeToPodcast(podcast: Podcast, subscribe: Bool, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        let realm = try! Realm()

        try! realm.write {
            podcast.subscribed = subscribe
        }

        let request = Alamofire
        .request(FablerClient.Router.SubscribeToPodcast(podcast: podcast.podcastId, subscribe: subscribe))
        .validate(statusCode: 200..<202)
        .responseJSON { response in
            switch response.result {
            case .Success:
                dispatch_async(queue, {completion(result: true)})
            case .Failure(let error):
                print(error)
                dispatch_async(queue, {completion(result: false)})
            }
        }

        debugPrint(request)
    }

    // MARK: - PodcastService serialize functions

    private func serializePodcastObject(data: JSON) -> Podcast? {
        let podcast = Podcast()
        let realm = try! Realm()

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

        try! realm.write {
            realm.add(podcast, update: true)
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
        let realm = try! Realm()

        for podcast in local {
            if !server.contains(podcast) {
                try! realm.write {
                    podcast.subscribed = false
                }
            }
        }
    }
}
