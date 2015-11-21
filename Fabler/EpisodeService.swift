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

    func getEpisodesForPodcast(podcastId: Int, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: [Episode]) -> Void)?) -> [Episode] {

        if completion != nil {
            let request = Alamofire
            .request(FablerClient.Router.ReadEpisodesForPodcast(podcast: podcastId))
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    self.serializeEpisodeCollection(json)
                case .Failure(let error):
                    print(error)
                }

                dispatch_async(queue, {completion!(result: self.getEpisodesForPodcastFromRealm(podcastId))})
            }

            debugPrint(request)
        }

        return self.getEpisodesForPodcastFromRealm(podcastId)
    }

    private func getEpisodesForPodcastFromRealm(podcastId: Int) -> [Episode] {
        let realm = try! Realm()

        return Array(realm.objects(Episode).filter("podcastId == %d", podcastId))
    }

    func setMarkForEpisode(episode: Episode, mark: NSTimeInterval, completed: Bool) {
        let realm = try! Realm()

        try! realm.write {
            episode.completed = completed
            episode.mark = mark
        }

        let request = Alamofire
        .request(FablerClient.Router.UpdateEpisodeMark(episode: episode.id, mark: episode.mark, completed: episode.completed))
        .validate(statusCode: 200..<202)
        .responseJSON { response in
            switch response.result {
            case .Success:
                break
            case .Failure(let error):
                print(error)
            }
        }

        debugPrint(request)
    }

    // MARK: - EpisodeService serialize functions

    private func serializeEpisodeObject(data: JSON) -> Episode? {
        let episode = Episode()
        let realm = try! Realm()

        if let id = data["id"].int {
            episode.id = id
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

        try! realm.write {
            realm.add(episode, update: true)
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
