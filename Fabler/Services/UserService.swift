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

    // MARK: - UserService members

    static var currentFacebookToken: FBSDKAccessToken?

    private let queueIdentifier: String
    private let pendingRequestQueue: dispatch_queue_t
    private var pendingRequests: [Request] = []

    // MARK: - UserService functions

    init() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        self.queueIdentifier = NSUUID().UUIDString
        self.pendingRequestQueue = dispatch_queue_create(self.queueIdentifier, nil)

        notificationCenter.addObserverForName(FBSDKAccessTokenDidChangeNotification, object: nil, queue: mainQueue) { notification in
            Log.info("Facebook token updated.")

            if let facebookToken = FBSDKAccessToken.currentAccessToken() {
                let updateToken: Bool

                //
                // Debounce the notification
                //
                if let oldToken = UserService.currentFacebookToken where facebookToken.isEqualToAccessToken(oldToken) {
                    updateToken = false
                } else {
                    updateToken = true
                    UserService.currentFacebookToken = facebookToken
                }

                if updateToken {
                    let request = Alamofire
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

                        if let request = response.request {
                            self.removeRequestFromPending(request)
                        }
                    }

                    self.addRequestToPending(request)

                    Log.info("Login request made.")
                } else {
                    Log.info("New Facebook token is same as old Facebook token.")
                }
            } else {
                Log.warning("No current Facebook token.")
                UserService.currentFacebookToken = nil
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

                if let request = response.request {
                    self.removeRequestFromPending(request)
                }

                dispatch_async(queue, {completion(result: self.getUserFromRealm(userId))})
            }

            self.addRequestToPending(request)

            Log.debug("Read user request: \(request).")
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

            if let request = response.request {
                self.removeRequestFromPending(request)
            }
        }

        self.addRequestToPending(request)

        Log.debug("Current user request: \(request).")
    }

    func updateProfile(firstName: String?, lastName: String?, birthday: NSDate?, user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        if let currentUser = User.getCurrentUser() {
            guard currentUser.userId == user.userId else {
                Log.error("Attempted to edit profile of user other than current user.")
                return
            }
        }

        let request = Alamofire
        .request(FablerClient.Router.UpdateUser(user: user.userId, userName: nil, email: nil, firstName: firstName, lastName: lastName, birthday: birthday))
        .validate()
        .responseSwiftyJSON { response in
            let result: Bool

            switch response.result {
            case .Success(let json):
                self.serializeUserObject(json)
                result = true
            case .Failure(let error):
                Log.error("Update user profile request error occured: \(error).")
                result = false
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }

            dispatch_async(queue, {completion(result: result)})
        }

        self.addRequestToPending(request)

        Log.debug("Update user profile: \(request).")
    }

    func updateEmail(email: String, user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        if let currentUser = User.getCurrentUser() {
            guard currentUser.userId == user.userId else {
                Log.error("Attempted to edit profile of user other than current user.")
                return
            }
        }

        let request = Alamofire
        .request(FablerClient.Router.UpdateUser(user: user.userId, userName: nil, email: email, firstName: nil, lastName: nil, birthday: nil))
        .validate()
        .responseSwiftyJSON { response in
            let result: Bool

            switch response.result {
            case .Success(let json):
                self.serializeUserObject(json)
                result = true
            case .Failure(let error):
                Log.error("Update user email request error occured: \(error).")
                result = false
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }

            dispatch_async(queue, {completion(result: result)})
        }

        self.addRequestToPending(request)

        Log.debug("Update user email: \(request).")
    }

    func updateUsername(userName: String, user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        if let currentUser = User.getCurrentUser() {
            guard currentUser.userId == user.userId else {
                Log.error("Attempted to edit profile of user other than current user.")
                return
            }
        }

        let request = Alamofire
        .request(FablerClient.Router.UpdateUser(user: user.userId, userName: userName, email: nil, firstName: nil, lastName: nil, birthday: nil))
        .validate()
        .responseSwiftyJSON { response in
            let result: Bool

            switch response.result {
            case .Success(let json):
                self.serializeUserObject(json)
                result = true
            case .Failure(let error):
                Log.error("Update user username request error occured: \(error).")
                result = false
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }

            dispatch_async(queue, {completion(result: result)})
        }

        self.addRequestToPending(request)

        Log.debug("Update user username: \(request).")
    }

    func outstandingRequestCount() -> Int {
        var result: Int = 0

        dispatch_sync(self.pendingRequestQueue) {
            result = self.pendingRequests.count
        }

        return result
    }

    private func addRequestToPending(request: Request) {
        dispatch_sync(self.pendingRequestQueue) {
            self.pendingRequests.append(request)
        }
    }

    private func removeRequestFromPending(request: NSURLRequest) {
        dispatch_sync(self.pendingRequestQueue) {
            self.pendingRequests = self.pendingRequests.filter({
                !(($0.request != nil) && ($0.request! === request))
            })
        }
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

        if let image = data["image"].string {
            user.image = image
        }

        if let birthday = (data["birthday"].string)?.toNSDate() {
            user.birthday = birthday
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
