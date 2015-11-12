//
//  PodcastService.swift
//  Fabler
//
//  Created by Christopher Day on 10/30/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import Alamofire
import SwiftyJSON
import CoreData

class PodcastService {

    // MARK: - CoreData context

    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    // MARK: - PodcastService functions

    init() {
    }

    // MARK: - PodcastService API functions

    func readAllPodcasts(completion: (result: [Podcast]) -> Void) -> [Podcast] {
        let local_podcasts: [Podcast]

        let request = NSFetchRequest(entityName: "Podcast")

        do {
            local_podcasts = try context.executeFetchRequest(request) as! [Podcast]
        } catch _ {
            local_podcasts = []
            print("Error fetching subscribed Podcasts.")
        }

        Alamofire
            .request(FablerClient.Router.ReadPodcasts())
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    let server_podcasts = self.serializePodcastCollection(json)
                    completion(result: server_podcasts)
                case .Failure(let error):
                    print(error)
                    completion(result: local_podcasts)
                }
            }

        return local_podcasts
    }

    func readSubscribedPodcasts(completion: (result: [Podcast]) -> Void) -> [Podcast] {
        let local_podcasts: [Podcast]

        let request = NSFetchRequest(entityName: "Podcast")
        request.predicate = NSPredicate(format: "subscribed == YES")

        do {
            local_podcasts = try context.executeFetchRequest(request) as! [Podcast]
        } catch _ {
            local_podcasts = []
            print("Error fetching subscribed Podcasts.")
        }

        Alamofire
            .request(FablerClient.Router.ReadSubscribedPodcasts())
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    let server_podcasts = self.serializePodcastCollection(json)
                    completion(result: server_podcasts)
                case .Failure(let error):
                    print(error)
                    completion(result: local_podcasts)
                }
            }

        return local_podcasts
    }

    func subscribeToPodcast(podcastId: Int, subscribe: Bool, completion: (result: Bool) -> Void) {
        Alamofire
            .request(FablerClient.Router.SubscribeToPodcast(podcast: podcastId, subscribe: subscribe))
            .validate(statusCode: 200..<202)
            .responseJSON { response in
                switch response.result {
                case .Success:
                    completion(result: true)
                case .Failure(let error):
                    print(error)
                    completion(result: false)
                }
            }
    }

    // MARK: - PodcastService serialize functions

    private func serializePodcastObject(data: JSON) -> Podcast? {
        var podcast: Podcast?

        if let id = data["id"].int {
            let request = NSFetchRequest(entityName: "Podcast")
            let predicate = NSPredicate(format: "id == %d", id)
            request.predicate = predicate

            do {
                let result = try context.executeFetchRequest(request) as! [Podcast]
                switch result.count {
                case 1:
                    podcast = result[0]
                case 0:
                    break
                default:
                    assert(false, "Invalid data returned from Core Data.")
                }
            } catch {
                print("Unable to find returned Podcast in store.")
            }
        }

        if podcast == nil {
            podcast = NSEntityDescription.insertNewObjectForEntityForName("Podcast", inManagedObjectContext: self.context) as? Podcast
        }

        if let id = data["id"].int {
            podcast?.id = id
        }

        if let title = data["title"].string {
            podcast?.title = title
        }

        if let author = data["author"].string {
            podcast?.author = author
        }

        if let explicit = data["explicit"].bool {
            podcast?.explicit = explicit
        }

        if let subscribed = data["subscribed"].bool {
            podcast?.subscribed = subscribed
        }

        if let publisherName = data["subscribed"].string {
            podcast?.publisherName = publisherName
        }

        if let publisherId = data["publisher"].int {
            podcast?.publisherId = publisherId
        }

        if let summary = data["summary"].string {
            podcast?.summary = summary
        }

        if let category = data["category"].string {
            podcast?.category = category
        }

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print(nserror)
                podcast = nil
            }
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
}
