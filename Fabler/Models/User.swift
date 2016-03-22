//
//  User.swift
//  Fabler
//
//  Created by Christopher Day on 11/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift

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

    // MARK: - Realm methods

    override public static func primaryKey() -> String? {
        return "userId"
    }
}
