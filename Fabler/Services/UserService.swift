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

public final class UserService {

    // MARK: - singleton

    public static let sharedInstance = UserService()

    // MARK: - UserService properties

    static var currentFacebookToken: FBSDKAccessToken?

    private let queueIdentifier: String
    private let pendingRequestQueue: dispatch_queue_t
    private var pendingRequests: [Request] = []

    // MARK: - UserService methods

    public init() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        self.queueIdentifier = NSUUID().UUIDString
        self.pendingRequestQueue = dispatch_queue_create(self.queueIdentifier, nil)

        notificationCenter.addObserverForName(FBSDKAccessTokenDidChangeNotification, object: nil, queue: mainQueue) { notification in
            Log.info("Facebook token updated")

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
                            Log.error("Login error occured: \(error)")
                        }

                        if let request = response.request {
                            self.removeRequestFromPending(request)
                        }
                    }

                    self.addRequestToPending(request)

                    Log.info("Login request made")
                } else {
                    Log.info("New Facebook token is same as old Facebook token")
                }
            } else {
                Log.warning("No current Facebook token")
                UserService.currentFacebookToken = nil
            }
        }
    }

    // MARK: - UserService API methods

    public func getUserFor(userId: Int, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: User?) -> Void)?) -> User? {
        if let completion = completion {
            let request = Alamofire
            .request(FablerClient.Router.ReadUser(user: userId))
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    self.serializeUserObject(json)
                case .Failure(let error):
                    Log.error("User request failed with \(error)")
                }

                if let request = response.request {
                    self.removeRequestFromPending(request)
                }

                dispatch_async(queue) {
                    completion(result: self.getUserFromRealm(userId))
                }
            }

            self.addRequestToPending(request)

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
            Log.error("Realm read failed")
        }

        return user
    }

    public func updateCurrentUser() {
        let request = Alamofire
        .request(FablerClient.Router.ReadCurrentUser())
        .validate()
        .responseSwiftyJSON { response in
            switch response.result {
            case .Success(let json):
                self.serializeUserObject(json)
                NSNotificationCenter.defaultCenter().postNotificationName(CurrentUserDidChangeNotification, object: self)
            case .Failure(let error):
                Log.error("User request error occured: \(error)")
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }
        }

        self.addRequestToPending(request)

        Log.debug("Current user request: \(request).")
    }

    public func updateProfile(firstName: String?, lastName: String?, birthday: NSDate?, user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        if let currentUser = User.getCurrentUser() {
            guard currentUser.userId == user.userId else {
                Log.error("Attempted to edit profile of user other than current user")
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
                Log.error("Update user profile request error occured: \(error)")
                result = false
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }

            dispatch_async(queue) {
                completion(result: result)
            }
        }

        self.addRequestToPending(request)

        Log.debug("Update user profile: \(request).")
    }

    public func updateEmail(email: String, user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        if let currentUser = User.getCurrentUser() {
            guard currentUser.userId == user.userId else {
                Log.error("Attempted to edit profile of user other than current user")
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
                Log.error("Update user email request error occured: \(error)")
                result = false
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }

            dispatch_async(queue) {
                completion(result: result)
            }
        }

        self.addRequestToPending(request)

        Log.debug("Update user email: \(request)")
    }

    public func updateUsername(userName: String, user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        if let currentUser = User.getCurrentUser() {
            guard currentUser.userId == user.userId else {
                Log.error("Attempted to edit profile of user other than current user")
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
                Log.error("Update user username request error occured: \(error)")
                result = false
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }

            dispatch_async(queue) {
                completion(result: result)
            }
        }

        self.addRequestToPending(request)

        Log.debug("Update user username: \(request)")
    }

    public func getFollowers(user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: Bool) -> Void)?) {
        let id = user.userId

        let request = Alamofire
        .request(FablerClient.Router.ReadFollowers(user: id))
        .validate()
        .responseSwiftyJSON { response in
            var result: Bool = false

            switch response.result {
            case .Success(let json):
                let followers = self.serializeUserCollection(json)
                if let responseUser = self.getUserFor(id, completion: nil) {
                    do {
                        let realm = try Realm()

                        try realm.write {
                            responseUser.followers.removeAll()
                            responseUser.followers.appendContentsOf(followers)
                            result = true
                        }
                    } catch {
                        Log.error("Realm write failed")
                    }
                }
            case .Failure(let error):
                Log.error("Follower request error occured: \(error)")
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }

            if let completion = completion {
                dispatch_async(queue) {
                    completion(result: result)
                }
            }
        }

        self.addRequestToPending(request)

        Log.debug("Read followers request: \(request)")
    }

    public func getFollowing(user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: Bool) -> Void)?) {
        let id = user.userId

        let request = Alamofire
        .request(FablerClient.Router.ReadFollowing(user: id))
        .validate()
        .responseSwiftyJSON { response in
            var result: Bool = false

            switch response.result {
            case .Success(let json):
                let following = self.serializeUserCollection(json)
                if let responseUser = self.getUserFor(id, completion: nil) {
                    do {
                        let realm = try Realm()

                        try realm.write {
                            responseUser.following.removeAll()
                            responseUser.following.appendContentsOf(following)
                            result = true
                        }
                    } catch {
                        Log.error("Realm write failed")
                    }
                }
            case .Failure(let error):
                Log.error("Follower request error occured: \(error)")
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }

            if let completion = completion {
                dispatch_async(queue) {
                    completion(result: result)
                }
            }
        }

        self.addRequestToPending(request)

        Log.debug("Read following request: \(request)")
    }

    public func updateFollowing(user: User, following: Bool, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: (result: Bool) -> Void) {
        let id = user.userId

        self.updateRealmUserFollowing(user, following: following)

        let urlRequest: URLRequestConvertible

        if following {
            urlRequest = FablerClient.Router.SetFollowing(user: id)
        } else {
            urlRequest = FablerClient.Router.SetUnfollow(user: id)
        }

        let request = Alamofire
        .request(urlRequest)
        .validate()
        .response { request, response, data, error in
            var result: Bool = false

            if error == nil {
                do {
                    let realm = try Realm()
                    if let responseUser = realm.objectForPrimaryKey(User.self, key: id) {
                        try realm.write {
                            responseUser.followingUser = following
                        }

                        result = true
                    }
                } catch {
                    Log.error("Realm write failed")
                }
            } else {
                Log.error("Follow failed with \(error).")

                do {
                    let realm = try Realm()

                    if let responseUser = realm.objectForPrimaryKey(User.self, key: id) {
                        self.updateRealmUserFollowing(responseUser, following: !following)
                    }
                } catch {
                    Log.error("Realm write failed")
                }
            }

            dispatch_async(queue) {
                completion(result: result)
            }
        }

        self.addRequestToPending(request)

        Log.debug("Set following request: \(request)")
    }

    private func updateRealmUserFollowing(user: User, following: Bool) {
        guard let currentUser = User.getCurrentUser() else {
            return
        }

        if following {
            do {
                let realm = try Realm()

                try realm.write {
                    user.followers.append(currentUser)
                }
            } catch {
                Log.error("Realm write failed.")
            }
        } else if let index = user.followers.indexOf(currentUser) {
            do {
                let realm = try Realm()

                try realm.write {
                    user.followers.removeAtIndex(index)
                }
            } catch {
                Log.error("Realm write failed.")
            }
        }
    }

    public func getSubscribed(user: User, queue: dispatch_queue_t = dispatch_get_main_queue(), completion: ((result: Bool) -> Void)?) {
        let id = user.userId

        let request = Alamofire
        .request(FablerClient.Router.ReadSubscribed(user: id))
        .validate()
        .responseSwiftyJSON { response in
            var result: Bool = false

            switch response.result {
            case .Success(let json):
                let service = PodcastService()
                let subscribed = service.serializePodcastCollection(json)
                if let responseUser = self.getUserFor(id, completion: nil) {
                    do {
                        let realm = try Realm()

                        try realm.write {
                            responseUser.subscribed.removeAll()
                            responseUser.subscribed.appendContentsOf(subscribed)
                            result = true
                        }
                    } catch {
                        Log.error("Realm write failed")
                    }
                }
            case .Failure(let error):
                Log.error("Follower request error occured: \(error)")
            }

            if let request = response.request {
                self.removeRequestFromPending(request)
            }

            if let completion = completion {
                dispatch_async(queue) {
                    completion(result: result)
                }
            }
        }

        self.addRequestToPending(request)

        Log.debug("Read subscribed request: \(request)")
    }

    // MARK: UserService request functions

    public func outstandingRequestCount() -> Int {
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
            self.pendingRequests = self.pendingRequests.filter {
                !(($0.request != nil) && ($0.request! === request))
            }
        }
    }

    // MARK: - UserService serialize methods

    private func serializeUserObject(data: JSON) -> User? {
        var user: User?

        do {
            let realm = try Realm()

            if let id = data["id"].int {
                if let existingUser = realm.objectForPrimaryKey(User.self, key: id) {
                    user = existingUser
                } else {
                    user = User()
                    user?.userId = id

                    try realm.write {
                        realm.add(user!)
                    }
                }

                Log.verbose("Serializing user \(id).")
            }

            if let user = user {
                try realm.write {
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

                    if let following = data["following"].bool {
                        user.followingUser = following
                    }
                }
            }
        } catch {
            Log.error("Realm write failed")
            user = nil
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
