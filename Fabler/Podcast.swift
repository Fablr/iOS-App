//
//  Podcast.swift
//  Fabler
//
//  Created by Christopher Day on 10/30/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift

final class Podcast: Object, Equatable {

    // MARK: - Podcast members

    dynamic var title: String = ""
    dynamic var author: String = ""
    dynamic var explicit: Bool = false
    dynamic var podcastId: Int = 0
    dynamic var subscribed: Bool = false
    dynamic var publisherName: String = ""
    dynamic var publisherId: Int = 0
    dynamic var summary: String = ""
    dynamic var category: String = ""
    dynamic var image: String = ""

    // MARK: - Setting members

    dynamic var notify: Bool = true
    dynamic var download: Bool = true
    dynamic var downloadAmount: Int = 3

    // MARK: - Realm methods

    override static func primaryKey() -> String? {
        return "podcastId"
    }
}

// MARK: - Podcast helper functions

func == (lhs: Podcast, rhs: Podcast) -> Bool {
    return lhs.podcastId == rhs.podcastId
}
