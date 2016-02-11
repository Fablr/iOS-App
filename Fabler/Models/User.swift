//
//  User.swift
//  Fabler
//
//  Created by Christopher Day on 11/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift

final public class User: Object {

    // MARK: - User static members

    static func getCurrentUser() -> User? {
        let realm = try! Realm()
        return realm.objects(User).filter("currentUser == YES").first
    }

    // MARK: - User members

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

    // MARK: - Realm methods

    override public static func primaryKey() -> String? {
        return "userId"
    }
}
