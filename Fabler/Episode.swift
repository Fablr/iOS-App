//
//  Episode.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import CoreData

@objc(Episode)
final class Episode : NSManagedObject {

    // MARK: - Episode members

    @NSManaged var title: String
    @NSManaged var subtitle: String
    @NSManaged var explicit: Bool
    @NSManaged var pubdate: NSDate
    @NSManaged var duration: NSTimeInterval
    @NSManaged var episodeDescription: String
    @NSManaged var id: Int
    @NSManaged var link: String
    @NSManaged var podcastId: Int
}
