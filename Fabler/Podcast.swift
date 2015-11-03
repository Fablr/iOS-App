//
//  Podcast.swift
//  Fabler
//
//  Created by Christopher Day on 10/30/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

final class Podcast : ResponseObjectSerializable, ResponseCollectionSerializable {

    // MARK: - Podcast members

    let title: String
    let author: String
    let explicit: Bool
    let id: Int

    // MARK: - Podcast functions

    init (title: String,  author: String, explicit: Bool, id: Int) {
        self.title = title
        self.author = author
        self.explicit = explicit
        self.id = id
    }

    required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.title = representation.valueForKeyPath("title") as! String
        self.author = representation.valueForKeyPath("author") as! String
        self.explicit = (representation.valueForKeyPath("explicit") as! String).toBool()!
        self.id = representation.valueForKeyPath("id") as! Int
    }

    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [Podcast] {
        var podcasts: [Podcast] = []

        if let representation = representation.valueForKeyPath("results") as? [[String: AnyObject]] {
            for podcastRepresentation in representation {
                if let podcast = Podcast(response: response, representation: podcastRepresentation) {
                    podcasts.append(podcast)
                }
            }
        }


        return podcasts
    }
}
