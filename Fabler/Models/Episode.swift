//
//  Episode.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift

final class Episode: DownloadObject {

    // swiftlint:disable variable_name

    static let PodcastDirectory = "podcasts"

    // swiftlint:enable variable_name

    // MARK: - Episode members

    dynamic var title: String = ""
    dynamic var subtitle: String = ""
    dynamic var explicit: Bool = false
    dynamic var pubdate: NSDate = NSDate()
    dynamic var duration: NSTimeInterval = 0
    dynamic var episodeDescription: String = ""
    dynamic var episodeId: Int = 0
    dynamic var link: String = ""
    dynamic var podcast: Podcast?
    dynamic var podcastId: Int = 0
    dynamic var mark: NSTimeInterval = 0
    dynamic var completed: Bool = false

    // MARK: - Setting members

    dynamic var saved: Bool = false

    // MARK: - Realm methods

    override static func primaryKey() -> String? {
        return "episodeId"
    }

    // MARK: - DownloadObject methods

    override func primaryKeyValue() -> Int {
        return self.episodeId
    }
}
