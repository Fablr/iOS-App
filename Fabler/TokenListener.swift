//
//  TokenManager.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import FBSDKLoginKit

protocol TokenListenerDelegate {
    func tokenDidChange(token:String)
}

class TokenListener {

    // MARK: - Members

    var delegate:TokenListenerDelegate?

    // MARK: - TokenListener functions

    init() {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(FBSDKAccessTokenDidChangeNotification, object: nil, queue: mainQueue) { _ in
            if let facebookToken = FBSDKAccessToken.currentAccessToken() {
                self.delegate?.tokenDidChange(facebookToken.tokenString)
            }
        }
    }
}
