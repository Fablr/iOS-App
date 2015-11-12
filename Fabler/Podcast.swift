//
//  Podcast.swift
//  Fabler
//
//  Created by Christopher Day on 10/30/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import CoreData

@objc(Podcast)
final class Podcast : NSManagedObject {

    // MARK: - Podcast members

    @NSManaged var title: String
    @NSManaged var author: String
    @NSManaged var explicit: Bool
    @NSManaged var id: Int
    @NSManaged var subscribed: Bool
    @NSManaged var publisherName: String
    @NSManaged var publisherId: Int
    @NSManaged var summary: String
    @NSManaged var category: String
}
