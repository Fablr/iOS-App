//
//  Episode.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift

final public class Episode: Object {

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
    dynamic var download: FablerDownload?

    // MARK: - Setting members

    dynamic var saved: Bool = false

    // MARK: - Episode functions

    public func localURL() -> NSURL? {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        if let url = NSURL(string: link), lastPathComponent = url.lastPathComponent {
            let fullPath = documentsPath.stringByAppendingPathComponent(lastPathComponent)
            return NSURL(fileURLWithPath:fullPath)
        }
        return nil
    }

    // MARK: - Realm methods

    override public static func primaryKey() -> String? {
        return "episodeId"
    }
}
