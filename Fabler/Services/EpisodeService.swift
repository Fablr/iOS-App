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

class EpisodeService {

    // MARK: - EpisodeService functions

    init() {
    }

    // MARK: - EpisodeService API functions

    func getEpisodesForPodcast(podcast: Podcast, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: [Episode]) -> Void)?) -> [Episode] {
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

                dispatch_async(queue, {completion(result: self.getEpisodesForPodcastFromRealm(id))})
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

    func setMarkForEpisode(episode: Episode, mark: NSTimeInterval, completed: Bool) {
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

    // MARK: - EpisodeService serialize functions

    private func serializeEpisodeObject(data: JSON) -> Episode? {
        let episode = Episode()

        if let id = data["id"].int {
            episode.episodeId = id
        }

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
            episode.podcastId = podcastId
        }

        if let mark = (data["mark"].string)?.toNSTimeInterval() {
            episode.mark = mark
        }

        if let completed = data["completed"].bool {
            episode.completed = completed
        }

        do {
            let realm = try Realm()

            try realm.write {
                realm.add(episode, update: true)
            }
        } catch {
            Log.error("Realm write failed.")
        }

        return episode
    }

    private func serializeEpisodeCollection(data: JSON) -> [Episode] {
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
