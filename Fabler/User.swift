//
//  User.swift
//  Fabler
//
//  Created by Christopher Day on 11/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import CoreData

@objc(User)
final class User : NSManagedObject, ResponseObjectSerializable, ResponseCollectionSerializable {

    // MARK: - User static members

    static var currentUser: User?

    // MARK: - User members

    @NSManaged var userName: String
    @NSManaged var firstName: String
    @NSManaged var lastName: String
    @NSManaged var email: String

    // MARK: - ResponseObjectSerializable functions

    required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        super.init(entity: NSEntityDescription.entityForName("User", inManagedObjectContext: context)!, insertIntoManagedObjectContext: context)

        self.userName = representation.valueForKeyPath("username") as! String
        self.firstName = representation.valueForKeyPath("first_name") as! String
        self.lastName = representation.valueForKeyPath("last_name") as! String
        self.email = representation.valueForKeyPath("email") as! String
    }

    // MARK: - ResponseCollectionSerializable static functions

    static func collection(response response: NSHTTPURLResponse, representation: AnyObject) -> [User] {
        var users: [User] = []

        if let representation = representation as? [[String: AnyObject]] {
            for userRepresentation in representation {
                if let user = User(response: response, representation: userRepresentation) {
                    users.append(user)
                }
            }
        }

        return users
    }
}
