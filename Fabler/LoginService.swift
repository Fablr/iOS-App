//
//  LoginService.swift
//  Fabler
//
//  Created by Christopher Day on 10/29/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import Alamofire

class LoginService : TokenListenerDelegate {

    // MARK: - LoginService functions

    init() {
        
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
                    }
                case .Failure(let error):
                    print(error)
                }
            }
    }
}