//
//  User.swift
//  Fabler
//
//  Created by Christopher Day on 11/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift

final class User: Object {

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

    // MARK: - Realm methods

    override static func primaryKey() -> String? {
        return "userId"
    }
}
