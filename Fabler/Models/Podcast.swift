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

    // MARK: - Color members

    dynamic var primaryRed: Float = 0.0
    dynamic var primaryGreen: Float = 0.0
    dynamic var primaryBlue: Float = 0.0
    dynamic var primarySet: Bool = false

    var primaryColor: UIColor? {
        get {
            if self.primarySet {
                return UIColor(red: CGFloat(self.primaryRed), green: CGFloat(self.primaryGreen), blue: CGFloat(self.primaryBlue), alpha: 1.0)
            }

            return nil
        }
    }

    dynamic var backgroundRed: Float = 0.0
    dynamic var backgroundGreen: Float = 0.0
    dynamic var backgroundBlue: Float = 0.0
    dynamic var backgroundSet: Bool = false

    var backgroundColor: UIColor? {
        get {
            if self.backgroundSet {
                return UIColor(red: CGFloat(self.backgroundRed), green: CGFloat(self.backgroundGreen), blue: CGFloat(self.backgroundBlue), alpha: 1.0)
            }

            return nil
        }
    }

    // MARK: - Realm methods

    override static func primaryKey() -> String? {
        return "podcastId"
    }
}

// MARK: - Podcast helper functions

func == (lhs: Podcast, rhs: Podcast) -> Bool {
    return lhs.podcastId == rhs.podcastId
}
