//
//  User.swift
//  Fabler
//
//  Created by Christopher Day on 11/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import CoreData

@objc(User)
final class User : NSManagedObject {

    // MARK: - User static members

    static var currentUser: User?

    // MARK: - User members

    @NSManaged var userName: String
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var email: String
    @NSManaged var id: Int
    @NSManaged var currentUser: Bool
}
