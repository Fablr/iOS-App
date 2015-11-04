//
//  Episode.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

final class Episode : ResponseObjectSerializable, ResponseCollectionSerializable {

    // MARK: - Episode members

    let title: String
    let subtitle: String
    let explicit: Bool
    let pubdate: NSDate
    let duration: String
    let description: String
    let id: Int

    // MARK: - Episode functions

    init (title: String, subtitle: String, pubdate: String, duration: String, description: String, explicit: Bool, id: Int) {
        let dateFormatter = NSDateFormatter()

        self.title = title
        self.subtitle = subtitle
        self.explicit = explicit
        self.pubdate = dateFormatter.dateFromString(pubdate)!
        self.duration = duration
        self.description = description
        self.id = id
    }

    required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let dateFormatter = NSDateFormatter()

        self.title = representation.valueForKeyPath("title") as! String
        self.subtitle = representation.valueForKeyPath("subtitle") as! String
        self.explicit = (representation.valueForKeyPath("explicit") as! String).toBool()!
        self.pubdate = dateFormatter.dateFromString(representation.valueForKeyPath("pubdate") as! String)!
        self.duration = representation.valueForKeyPath("duration") as! String
        self.description = representation.valueForKeyPath("description") as! String
        self.id = representation.valueForKeyPath("id") as! Int
    }

    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Episode] {
        var episodes: [Episode] = []

        if let representation = representation.valueForKeyPath("results") as? [[String: AnyObject]] {
            for episodeRepresentation in representation {
                if let episode = Episode(response: response, representation: episodeRepresentation) {
                    episodes.append(episode)
                }
            }
        }
        
        return episodes
    }
}
