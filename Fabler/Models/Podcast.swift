//
//  Podcast.swift
//  Fabler
//
//  Created by Christopher Day on 10/30/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift
import Kingfisher
import Hue
import ChameleonFramework

public enum SortOrder: String {
    case NewestOldest = "Newest to oldest"
    case OldestNewest = "Oldest to newest"
}

final public class Podcast: Object, Equatable {

    // MARK: - Podcast properties

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

    // MARK: - Setting properties

    dynamic var notify: Bool = true
    dynamic var download: Bool = true
    dynamic var downloadAmount: Int = 3
    dynamic var sortOrderRaw: String = "Newest to oldest"

    var sortOrder: SortOrder {
        get {
            if let state = SortOrder(rawValue: self.sortOrderRaw) {
                return state
            }

            return .NewestOldest
        }
    }

    // MARK: - Color properties

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

    // MARK: - Podcast methods

    public func image(completion: (image: UIImage?) -> ()) {
        guard let url = NSURL(string: self.image) else {
            return
        }

        let manager = KingfisherManager.sharedManager
        let cache = manager.cache

        let id = self.podcastId
        let calcColors = !self.primarySet

        if let image = cache.retrieveImageInDiskCacheForKey(url.absoluteString) {
            if calcColors {
                let service = PodcastService()
                service.setPrimaryColorForPodcast(self, color: image.f_color())
            }

            completion(image: image)
        } else {
            manager.retrieveImageWithURL(url, optionsInfo: [.CallbackDispatchQueue(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))], progressBlock: nil) { (image, error, cacheType, url) in
                let result: UIImage?

                if let image = image where error == nil {
                    let service = PodcastService()

                    if let podcast = service.readPodcastFor(id, completion: nil) where calcColors {
                        service.setPrimaryColorForPodcast(podcast, color: image.f_color())
                    }

                    result = image
                } else {
                    result = nil
                }

                dispatch_async(dispatch_get_main_queue()) {
                    completion(image: result)
                }
            }
        }
    }

    // MARK: - Realm methods

    override public static func primaryKey() -> String? {
        return "podcastId"
    }
}

// MARK: - Podcast helper methods

public func == (lhs: Podcast, rhs: Podcast) -> Bool {
    return lhs.podcastId == rhs.podcastId
}
