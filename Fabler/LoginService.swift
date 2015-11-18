//
//  LoginService.swift
//  Fabler
//
//  Created by Christopher Day on 10/29/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

public let CurrentUserDidChangeNotification = "com.Fabler.CurrentUserDidChange"

import FBSDKLoginKit
import Alamofire
import SwiftyJSON
import CoreData

class LoginService {

    // MARK: - CoreData context

    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

    // MARK: - LoginService functions

    init() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(FBSDKAccessTokenDidChangeNotification, object: nil, queue: mainQueue) { _ in
            if let facebookToken = FBSDKAccessToken.currentAccessToken() {
                Alamofire
                    .request(FablerClient.Router.FacebookLogin(token: facebookToken.tokenString))
                    .validate()
                    .responseJSON { response in
                        switch response.result {
                        case .Success(let data):
                            if let token = data.valueForKeyPath("access_token") as? String {
                                FablerClient.Router.OAuthToken = token
                                self.getCurrentUser()
                            }
                        case .Failure(let error):
                            print(error)
                        }
                    }
            }
        }
    }

    // MARK: - LoginService API functions

    func getCurrentUser() {
        let request = NSFetchRequest(entityName: "User")
        request.predicate = NSPredicate(format: "currentUser == YES")

        do {
            let result = try context.executeFetchRequest(request) as! [User]
            if result.count == 1 {
                User.currentUser = result[0]
                NSNotificationCenter.defaultCenter().postNotificationName(CurrentUserDidChangeNotification, object: self)
            }
        } catch _ {
            print("Error fetching current user.")
        }

        Alamofire
            .request(FablerClient.Router.ReadCurrentUser())
            .validate()
            .responseSwiftyJSON { response in
                switch response.result {
                case .Success(let json):
                    if let server_user = self.serializeUserObject(json) {
                        User.currentUser = server_user
                        NSNotificationCenter.defaultCenter().postNotificationName(CurrentUserDidChangeNotification, object: self)
                    }
                case .Failure(let error):
                    print(error)
                }
            }
    }

    // MARK: - TokenListenerDelegate functions

    func tokenDidChange(token: String) {

    }

    // MARK: - UserService serialize functions

    private func serializeUserObject(data: JSON) -> User? {
        var user: User?

        if let id = data["id"].int {
            let request = NSFetchRequest(entityName: "User")
            let predicate = NSPredicate(format: "id == %d", id)
            request.predicate = predicate

            do {
                let result = try context.executeFetchRequest(request) as! [User]
                switch result.count {
                case 1:
                    user = result[0]
                case 0:
                    break
                default:
                    assert(false, "Invalid data returned from Core Data.")
                }
            } catch _ {
                print("Unable to find returned User in store.")
            }
        }

        if user == nil {
            user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.context) as? User
        }

        if let id = data["id"].int {
            user?.id = id
        }

        if let userName = data["username"].string {
            user?.userName = userName
        }

        if let firstName = data["first_name"].string {
            user?.firstName = firstName
        }

        if let lastName = data["last_name"].string {
            user?.lastName = lastName
        }

        if let email = data["email"].string {
            user?.email = email
        }

        if let currentUser = data["currentUser"].bool {
            user?.currentUser = currentUser
        }

        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print(nserror)
                user = nil
            }
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
