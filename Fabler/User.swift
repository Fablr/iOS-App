//
//  User.swift
//  Fabler
//
//  Created by Christopher Day on 11/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

final class User : ResponseObjectSerializable, ResponseCollectionSerializable {

    // MARK: - Episode members

    static var currentUser: User?

    let userName: String
    let firstName: String
    let lastName: String
    let email: String

    // MARK: - Episode functions

    init (userName: String, firstName: String, lastName: String, email: String) {
        self.userName = userName
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
    }

    required init?(response: NSHTTPURLResponse, representation: AnyObject) {
        self.userName = representation.valueForKeyPath("username") as! String
        self.firstName = representation.valueForKeyPath("first_name") as! String
        self.lastName = representation.valueForKeyPath("last_name") as! String
        self.email = representation.valueForKeyPath("email") as! String
    }

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
