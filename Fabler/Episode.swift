//
//  Episode.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import CoreData

@objc(Episode)
final class Episode : NSManagedObject, ResponseObjectSerializable, ResponseCollectionSerializable {

    // MARK: - Episode members

    @NSManaged var title: String
    @NSManaged var subtitle: String
    @NSManaged var explicit: Bool
    @NSManaged var pubdate: NSDate
    @NSManaged var duration: NSTimeInterval
    @NSManaged var episodeDescription: String
    @NSManaged var id: Int

    // MARK: - ResponseObjectSerializable functions

    required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        super.init(entity: NSEntityDescription.entityForName("Episode", inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)

        self.title = representation.valueForKeyPath("title") as! String
        self.subtitle = representation.valueForKeyPath("subtitle") as! String
        self.explicit = representation.valueForKeyPath("explicit") as! Bool
        self.episodeDescription = representation.valueForKeyPath("description") as! String
        self.id = representation.valueForKeyPath("id") as! Int
        self.duration = (representation.valueForKeyPath("duration") as! String).toNSTimeInterval()
        self.pubdate = (representation.valueForKeyPath("pubdate") as! String).toNSDate()!
    }

    // MARK: - ResponseCollectionSerializable functions

    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Episode] {
        var episodes: [Episode] = []

        if let representation = representation as? [[String: AnyObject]] {
            for episodeRepresentation in representation {
                if let episode = Episode(response: response, representation: episodeRepresentation) {
                    episodes.append(episode)
                }
            }
        }
        
        return episodes
    }
}
