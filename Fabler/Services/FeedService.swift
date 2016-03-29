//
//  FeedService.swift
//  Fabler
//
//  Created by Christopher Day on 3/27/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import Alamofire
import SwiftyJSON
import RealmSwift

public class FeedService {

    // MARK: - FeedService API methods

    public func getFeedFor(user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: [Event]) -> Void) {
        let id = user.userId

        let request = Alamofire
        .request(FablerClient.Router.ReadUsersFeed(user: id))
        .validate()
        .responseSwiftyJSON { response in
            switch response.result {
            case .Success(let json):
                self.clearRealmEvents()
                self.serializeEventCollection(json)
            case .Failure(let error):
                Log.error("Feed request failed with \(error).")
            }

            dispatch_async(queue) {
                completion(result: self.getRealmEvents())
            }
        }

        Log.debug("Read feed request: \(request)")
    }

    private func getRealmEvents() -> [Event] {
        var events: [Event] = []

        do {
            let realm = try Realm()

            events = Array(realm.objects(Event))
        } catch {
            Log.warning("Realm read failed")
        }

        return events
    }

    private func clearRealmEvents() {
        do {
            let realm = try Realm()

            let events = realm.objects(Event)

            try realm.write {
                realm.delete(events)
            }
        } catch {
            Log.warning("Realm write failed")
        }
    }

    // MARK: - FeedService serialize functions

    public func serializeEventObject(data: JSON) -> Event? {
        var event: Event?

        do {
            let realm = try Realm()

            if let id = data["id"].int {
                if let existingEvent = realm.objectForPrimaryKey(Event.self, key: id) {
                    event = existingEvent
                } else {
                    event = Event()
                    event?.eventId = id

                    try realm.write {
                        realm.add(event!)
                    }
                }
            }

            guard let event = event else {
                fatalError("Failed to create event object")
            }

            try realm.write {
                if let type = data["event_type"].string {
                    event.eventTypeRaw = type
                }

                let userJson = data["user"]
                let userService = UserService()
                if let user = userService.serializeUserObject(userJson) {
                    event.user = user
                }

                let eventObjectJson = data["event_object"]
                switch event.eventType {
                case .Commented:
                    let commentService = CommentService()
                    if let comment = commentService.serializeCommentObject(eventObjectJson, episode: nil, podcast: nil) {
                        event.comment = comment
                    }

                case .Followed:
                    if let user = userService.serializeUserObject(eventObjectJson) {
                        event.followed = user
                    }

                case .Listened:
                    let episodeService = EpisodeService()
                    if let episode = episodeService.serializeEpisodeObject(eventObjectJson) {
                        event.episode = episode
                    }

                case .Subscribed:
                    let podcastService = PodcastService()
                    if let podcast = podcastService.serializePodcastObject(eventObjectJson) {
                        event.podcast = podcast
                    }

                case .None:
                    Log.warning("Invalid content type for event")
                }
            }
        } catch {
            Log.error("Realm write failed.")
            event = nil
        }

        return event
    }

    public func serializeEventCollection(data: JSON) -> [Event] {
        var events: [Event] = []

        for (_, subJson):(String, JSON) in data {
            do {
                if let event = serializeEventObject(subJson) {
                    events.append(event)
                }
            }
        }

        return events
    }
}
