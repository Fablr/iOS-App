//
//  LoginViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/23/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {

    // MARK: - IBOutlets

    @IBOutlet var loginButton: FBSDKLoginButton?

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loginButton = FBSDKLoginButton()
        self.loginButton?.readPermissions = ["public_profile", "email", "user_friends"]
        self.loginButton?.delegate = self
    }

    override func viewDidAppear(animated: Bool) {
        if FBSDKAccessToken.currentAccessToken() != nil {
            performSegueWithIdentifier("loggedInSegue", sender: nil)
        }
    }

    // MARK: - FBSDKLoginButtonDelegate methods

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if error == nil {
            performSegueWithIdentifier("loggedInSegue", sender: nil)
        } else {
            Log.error(error.localizedDescription)
        }
    }

    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {

    }
}
