//
//  Episode.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift

final class Episode : Object {

    // MARK: - Episode members

    dynamic var title: String = ""
    dynamic var subtitle: String = ""
    dynamic var explicit: Bool = false
    dynamic var pubdate: NSDate = NSDate()
    dynamic var duration: NSTimeInterval = 0
    dynamic var episodeDescription: String = ""
    dynamic var id: Int = 0
    dynamic var link: String = ""
    dynamic var podcastId: Int = 0
    dynamic var mark: NSTimeInterval = 0
    dynamic var completed: Bool = false

    // MARK: - Local tracking members

    dynamic var downloadStateRaw: Int = 0

    // MARK: - Realm methods

    override static func primaryKey() -> String? {
        return "id"
    }

    // MARK: - Computed properties

    var downloadState: DownloadStatus {
        get {
            if let state = DownloadStatus(rawValue: self.downloadStateRaw) {
                return state
            }

            return DownloadStatus.NotStarted
        }
    }
}
