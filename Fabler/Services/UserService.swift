//
//  UserService.swift
//  Fabler
//
//  Created by Christopher Day on 10/29/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

// swiftlint:disable variable_name

public let CurrentUserDidChangeNotification = "com.Fabler.CurrentUserDidChange"
public let TokenDidChangeNotification = "com.Fabler.TokenDidChange"

// swiftlint:enable variable_name

import FBSDKLoginKit
import Alamofire
import SwiftyJSON
import RealmSwift

class UserService {

    // MARK: - UserService functions

    init() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(FBSDKAccessTokenDidChangeNotification, object: nil, queue: mainQueue) { _ in
            Log.info("Facebook token updated.")

            if let facebookToken = FBSDKAccessToken.currentAccessToken() {
                _ = Alamofire
                .request(FablerClient.Router.FacebookLogin(token: facebookToken.tokenString))
                .validate()
                .responseJSON { response in
                    switch response.result {
                    case .Success(let data):
                        if let token = data.valueForKeyPath("access_token") as? String {
                            FablerClient.Router.token = token
                            NSNotificationCenter.defaultCenter().postNotificationName(TokenDidChangeNotification, object: self)
                            self.updateCurrentUser()
                        }
                    case .Failure(let error):
                        Log.error("Login error occured: \(error).")
                    }
                }

                Log.debug("Login request made.")
            } else {
                Log.warning("No current Facebook token.")
            }
        }
    }

    // MARK: - UserService API functions

    func getUserFor(userId: Int, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: User?) -> Void)?) -> User? {
        if let completion = completion {
            let request = Alamofire
            .request(FablerClient.Router.ReadUser(user: userId))
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    self.serializeUserObject(json)
                case .Failure(let error):
                    Log.error("User request failed with \(error).")
                }

                dispatch_async(queue, {completion(result: self.getUserFromRealm(userId))})
            }

            Log.debug("Read user request: \(request)")
        }

        return self.getUserFromRealm(userId)
    }

    private func getUserFromRealm(userId: Int) -> User? {
        var user: User? = nil

        do {
            let realm = try Realm()

            user = realm.objectForPrimaryKey(User.self, key: userId)
        } catch {
            Log.error("Realm read failed.")
        }

        return user
    }

    func updateCurrentUser() {
        let request = Alamofire
        .request(FablerClient.Router.ReadCurrentUser())
        .validate()
        .responseSwiftyJSON { response in
            switch response.result {
            case .Success(let json):
                self.serializeUserObject(json)
                NSNotificationCenter.defaultCenter().postNotificationName(CurrentUserDidChangeNotification, object: self)
            case .Failure(let error):
                Log.error("User request error occured: \(error).")
            }
        }

        Log.debug("Current user request: \(request)")
    }

    // MARK: - UserService serialize functions

    private func serializeUserObject(data: JSON) -> User? {
        let user = User()

        if let id = data["id"].int {
            user.userId = id
        }

        if let userName = data["username"].string {
            user.userName = userName
        }

        if let firstName = data["first_name"].string {
            user.firstName = firstName
        }

        if let lastName = data["last_name"].string {
            user.lastName = lastName
        }

        if let email = data["email"].string {
            user.email = email
        }

        if let currentUser = data["currentUser"].bool {
            user.currentUser = currentUser
        }

        do {
            let realm = try Realm()

            try realm.write {
                realm.add(user, update: true)
            }
        } catch {
            Log.error("Realm write failed.")
        }

        return user
    }

    private func serializeUserCollection(data: JSON) -> [User] {
        var users: [User] = []

        for (_, subJson):(String, JSON) in data {
            do {
                if let user = serializeUserObject(subJson) {
                    users.append(user)
                }
            }
        }

        return users
    }
}
