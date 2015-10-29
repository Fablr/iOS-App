//
//  FablerClient.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import Foundation

class FablerClient : TokenListenerDelegate {

    // MARK: - Members

    var token:String?

    // MARK: - FablerClient functions

    init() {
        token = nil
    }

    // MARK: - TokenListenerDelegate functions

    func tokenDidChange(token: String) {
        self.token = token
    }
}