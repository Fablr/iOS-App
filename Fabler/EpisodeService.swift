//
//  EpisodeService.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import Alamofire
import SwiftyJSON
import CoreData

class EpisodeService {

    // MARK: - CoreData context

    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    // MARK: - EpisodeService functions

    init() {
    }

    // MARK: - EpisodeService API functions

    func getEpisodesForPodcast(podcastId: Int, completion: (result: [Episode]) -> Void) -> [Episode] {
        let local_episodes: [Episode]

        let request = NSFetchRequest(entityName: "Episode")
        request.predicate = NSPredicate(format: "podcastId == %d", podcastId)

        do {
            local_episodes = try context.executeFetchRequest(request) as! [Episode]
        } catch _ {
            local_episodes = []
            print("Error fetching subscribed Podcasts.")
        }

        Alamofire
            .request(FablerClient.Router.ReadEpisodesForPodcast(podcast: podcastId))
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    let server_episodes = self.serializeEpisodeCollection(json)
                    completion(result: server_episodes)
                case .Failure(let error):
                    print(error)
                    completion(result: local_episodes)
                }
            }

        return local_episodes
    }

    func setMarkForEpisode(episode: Episode, mark: NSTimeInterval, completed: Bool) {
        episode.completed = completed
        episode.mark = mark

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print(nserror)
            }
        }

        Alamofire
            .request(FablerClient.Router.UpdateEpisodeMark(episode: episode.id, mark: episode.mark, completed: episode.completed))
            .validate(statusCode: 200..<202)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    break
                case .Failure(let error):
                    print(error)
                    // mark for reupload
                }
        }
    }

    // MARK: - EpisodeService serialize functions

    private func serializeEpisodeObject(data: JSON) -> Episode? {
        var episode: Episode?

        if let id = data["id"].int {
            let request = NSFetchRequest(entityName: "Episode")
            let predicate = NSPredicate(format: "id == %d", id)
            request.predicate = predicate

            do {
                let result = try context.executeFetchRequest(request) as! [Episode]
                switch result.count {
                case 1:
                    episode = result[0]
                case 0:
                    break
                default:
                    assert(false, "Invalid data returned from Core Data.")
                }
            } catch _ {
                print("Unable to find returned Podcast in store.")
            }
        }

        if episode == nil {
            episode = NSEntityDescription.insertNewObjectForEntityForName("Episode", inManagedObjectContext: self.context) as? Episode
        }

        if let id = data["id"].int {
            episode?.id = id
        }

        if let title = data["title"].string {
            episode?.title = title
        }

        if let link = data["link"].string {
            episode?.link = link
        }

        if let subtitle = data["subtitle"].string {
            episode?.subtitle = subtitle
        }

        if let episodeDescription = data["description"].string {
            episode?.episodeDescription = episodeDescription
        }

        if let pubdate = (data["pubdate"].string)?.toNSDate() {
            episode?.pubdate = pubdate
        }

        if let duration = (data["duration"].string)?.toNSTimeInterval() {
            episode?.duration = duration
        }

        if let explicit = data["explicit"].bool {
            episode?.explicit = explicit
        }

        if let podcastId = data["podcast"].int {
            episode?.podcastId = podcastId
        }

        if let mark = (data["mark"].string)?.toNSTimeInterval() {
            episode?.mark = mark
        }

        if let completed = data["completed"].bool {
            episode?.completed = completed
        }

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print(nserror)
                episode = nil
            }
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
