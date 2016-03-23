//
//  User.swift
//  Fabler
//
//  Created by Christopher Day on 11/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift
import Kingfisher
import AlamofireImage

final public class User: Object {

    // MARK: - User static properties

    static func getCurrentUser() -> User? {
        let user: User?

        do {
            let realm = try Realm()
            user = realm.objects(User).filter("currentUser == YES").first
        } catch {
            user = nil
        }

        return user
    }

    // MARK: - User properties

    dynamic var userName: String = ""
    dynamic var firstName: String = ""
    dynamic var lastName: String = ""
    dynamic var email: String = ""
    dynamic var userId: Int = 0
    dynamic var currentUser: Bool = false
    dynamic var image: String = ""
    dynamic var birthday: NSDate?
    dynamic var followingUser: Bool = false

    let followers = List<User>()
    let following = List<User>()
    let subscribed = List<Podcast>()

    // MARK: - User methods

    public func profileImage(completion: (image: UIImage?) -> ()) {
        guard let url = NSURL(string: self.image) else {
            return
        }

        let key = "\(self.userId)-profile"

        let manager = KingfisherManager.sharedManager
        let cache = manager.cache

        if let cached = cache.retrieveImageInDiskCacheForKey(key) {
            completion(image: cached)
        } else {
            manager.retrieveImageWithURL(url, optionsInfo: [.CallbackDispatchQueue(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0))], progressBlock: nil) { (image, error, cacheType, url) in
                let circle: UIImage?

                if let image = image where error == nil {
                    circle = image.af_imageRoundedIntoCircle()
                    cache.storeImage(circle!, forKey: key)
                } else {
                    circle = nil
                }

                dispatch_async(dispatch_get_main_queue()) {
                    completion(image: circle)
                }
            }
        }
    }

    // MARK: - Realm methods

    override public static func primaryKey() -> String? {
        return "userId"
    }
}
