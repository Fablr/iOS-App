//
//  TokenManager.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import Foundation
import FBSDKLoginKit

protocol TokenListenerDelegate {
    func tokenDidChange(token:String)
}

class TokenListener : NSObject {

    // MARK: - Members

    var delegate:TokenListenerDelegate?

    // MARK: - TokenListener functions

    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "facebookTokenDidChange", name: FBSDKAccessTokenDidChangeNotification, object: nil)
    }

    // MARK: - NSNotificationCenter selectors

    func facebookTokenDidChange() {
        if let facebookToken = FBSDKAccessToken.currentAccessToken() {
            delegate?.tokenDidChange(facebookToken.tokenString)
        }
    }
}
