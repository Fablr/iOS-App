//
//  Event.swift
//  Fabler
//
//  Created by Christopher Day on 3/27/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import RealmSwift

public enum EventType: String {
    case Followed = "Followed"
    case Commented = "Commented"
    case Subscribed = "Subscribed"
    case Listened = "Listened"
    case None = "None"
}

final public class Event: Object, Equatable {

    // MARK: - Event properties

    dynamic var eventId: Int = 0
    dynamic var user: User?
    dynamic var time: NSDate = NSDate()
    dynamic var eventTypeRaw: String = "None"
    dynamic var comment: Comment?
    dynamic var episode: Episode?
    dynamic var followed: User?
    dynamic var podcast: Podcast?

    var eventType: EventType {
        get {
            if let state = EventType(rawValue: self.eventTypeRaw) {
                return state
            }

            return .None
        }
    }

    // MARK: - Realm methods

    override public static func primaryKey() -> String? {
        return "eventId"
    }
}

// MARK: - Event helper methods

public func == (lhs: Event, rhs: Event) -> Bool {
    return lhs.eventId == rhs.eventId
}
