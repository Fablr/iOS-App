//
//  Podcast.swift
//  Fabler
//
//  Created by Christopher Day on 10/30/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import CoreData

@objc(Podcast)
final class Podcast : NSManagedObject, ResponseObjectSerializable, ResponseCollectionSerializable {

    // MARK: - Podcast members

    @NSManaged var title: String
    @NSManaged var author: String
    @NSManaged var explicit: Bool
    @NSManaged var id: Int
    @NSManaged var subscribed: Bool

    // MARK: - ResponseObjectSerializable functions

    required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        super.init(entity: NSEntityDescription.entityForName("Podcast", inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)

        self.title = representation.valueForKeyPath("title") as! String
        self.author = representation.valueForKeyPath("author") as! String
        self.explicit = representation.valueForKeyPath("explicit") as! Bool
        self.id = representation.valueForKeyPath("id") as! Int
        self.subscribed = representation.valueForKeyPath("subscribed") as! Bool
    }

    // MARK: - ResponseCollectionSerializable functions

    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Podcast] {
        var podcasts: [Podcast] = []

        if let representation = representation as? [[String: AnyObject]] {
            for podcastRepresentation in representation {
                if let podcast = Podcast(response: response, representation: podcastRepresentation) {
                    podcasts.append(podcast)
                }
            }
        }

        return podcasts
    }
}
