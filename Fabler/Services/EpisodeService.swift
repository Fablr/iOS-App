//
//  EpisodeService.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import Alamofire
import SwiftyJSON
import RealmSwift

public class EpisodeService {

    // MARK: - EpisodeService API methods

    public func getEpisodeFor(episodeId: Int, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: Episode?) -> Void)?) -> Episode? {
        if let completion = completion {
            let request = Alamofire
                .request(FablerClient.Router.ReadEpisode(episode: episodeId))
                .validate()
                .responseSwiftyJSON { response in
                    switch response.result {
                    case .Success(let json):
                        self.serializeEpisodeObject(json)
                    case .Failure(let error):
                        Log.error("User request failed with \(error).")
                    }

                    dispatch_async(queue) {
                        completion(result: self.getEpisodeFromRealm(episodeId))
                    }
            }

            Log.debug("Read user request: \(request)")
        }

        return self.getEpisodeFromRealm(episodeId)
    }

    private func getEpisodeFromRealm(episodeId: Int) -> Episode? {
        var episode: Episode? = nil

        do {
            let realm = try Realm()

            episode = realm.objectForPrimaryKey(Episode.self, key: episodeId)
        } catch {
            Log.error("Realm read failed.")
        }

        return episode
    }

    public func getEpisodesForPodcast(podcast: Podcast, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: [Episode]) -> Void)?) -> [Episode] {
        let id = podcast.podcastId

        if let completion = completion {
            let request = Alamofire
            .request(FablerClient.Router.ReadEpisodesForPodcast(podcast: id))
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    self.serializeEpisodeCollection(json)
                case .Failure(let error):
                    Log.error("Episodes request failed with \(error).")
                }

                dispatch_async(queue) {
                    completion(result: self.getEpisodesForPodcastFromRealm(id))
                }
            }

            Log.debug("Read episodes request: \(request)")
        }

        return self.getEpisodesForPodcastFromRealm(id)
    }

    private func getEpisodesForPodcastFromRealm(podcastId: Int) -> [Episode] {
        var episodes: [Episode] = []

        do {
            let realm = try Realm()

            episodes = Array(realm.objects(Episode).filter("podcastId == %d", podcastId))
        } catch {
            Log.error("Realm read failed.")
        }

        return episodes
    }

    public func setMarkForEpisode(episode: Episode, mark: NSTimeInterval, completed: Bool) {
        do {
            let realm = try Realm()

            try realm.write {
                episode.completed = completed
                episode.mark = mark
            }
        } catch {
            Log.error("Realm write failed.")
        }

        let request = Alamofire
        .request(FablerClient.Router.UpdateEpisodeMark(episode: episode.episodeId, mark: episode.mark, completed: episode.completed))
        .validate(statusCode: 200..<202)
        .responseJSON { response in
            switch response.result {
            case .Success:
                break
            case .Failure(let error):
                Log.error("Episode mark request failed with \(error).")
            }
        }

        Log.debug("Episode mark request: \(request)")
    }

    public func flipSaveForEpisode(episode: Episode) {
        do {
            let realm = try Realm()

            try realm.write {
                episode.saved = !(episode.saved)
            }
        } catch {
            Log.error("Realm write failed.")
        }
    }

    // MARK: - EpisodeService serialize functions

    public func serializeEpisodeObject(data: JSON) -> Episode? {
        var episode: Episode?

        do {
            let realm = try Realm()

            if let id = data["id"].int {
                if let existingEpisode = realm.objectForPrimaryKey(Episode.self, key: id) {
                    episode = existingEpisode
                } else {
                    episode = Episode()
                    episode?.episodeId = id

                    try realm.write {
                        realm.add(episode!)
                    }
                }
            }

            if let episode = episode {
                try realm.write {
                    if let title = data["title"].string {
                        episode.title = title
                    }

                    if let link = data["link"].string {
                        episode.link = link
                    }

                    if let subtitle = data["subtitle"].string {
                        episode.subtitle = subtitle
                    }

                    if let episodeDescription = data["description"].string {
                        episode.episodeDescription = episodeDescription
                    }

                    if let pubdate = (data["pubdate"].string)?.toNSDate() {
                        episode.pubdate = pubdate
                    }

                    if let duration = (data["duration"].string)?.toNSTimeInterval() {
                        episode.duration = duration
                    }

                    if let explicit = data["explicit"].bool {
                        episode.explicit = explicit
                    }

                    if let podcastId = data["podcast"].int {
                        let podcastService = PodcastService()
                        episode.podcast = podcastService.readPodcastFor(podcastId, completion: nil)

                        episode.podcastId = podcastId
                    }

                    if let mark = (data["mark"].string)?.toNSTimeInterval() {
                        episode.mark = mark
                    }

                    if let completed = data["completed"].bool {
                        episode.completed = completed
                    }
                }
            }
        } catch {
            Log.error("Realm write failed.")
            episode = nil
        }

        return episode
    }

    public func serializeEpisodeCollection(data: JSON) -> [Episode] {
        var episodes: [Episode] = []

        for (_, subJson):(String, JSON) in data {
            do {
                if let episode = serializeEpisodeObject(subJson) {
                    episodes.append(episode)
                }
            }
        }

        return episodes
    }
}
