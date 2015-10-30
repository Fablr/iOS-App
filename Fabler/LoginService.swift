//
//  LoginService.swift
//  Fabler
//
//  Created by Christopher Day on 10/29/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import Alamofire
import SwiftyJSON

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
                    let json = JSON(data)
                    FablerClient.Router.OAuthToken = json["access_token"].stringValue
                case .Failure(let error):
                    print(error)
                }
            }
    }
}