//
//  LoginService.swift
//  Fabler
//
//  Created by Christopher Day on 10/29/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

public let CurrentUserDidChangeNotification = "com.Fabler.CurrentUserDidChange"

import Alamofire

class LoginService : TokenListenerDelegate {

    // MARK: - LoginService functions

    init() {        
    }

    func getCurrentUser() {
        Alamofire
            .request(FablerClient.Router.ReadCurrentUser())
            .validate()
            .responseObject { (response: Response<User, NSError>) in
                switch response.result {
                case .Success(let value):
                    User.currentUser = value
                    NSNotificationCenter.defaultCenter().postNotificationName(CurrentUserDidChangeNotification, object: self)
                case .Failure(let error):
                    print(error)
                    break
                }
            }
    }

    // MARK: - TokenListenerDelegate functions

    func tokenDidChange(token: String) {
        Alamofire
            .request(FablerClient.Router.FacebookLogin(token: token))
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
