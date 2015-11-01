//
//  LoginViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/23/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class LoginViewController : UIViewController, FBSDKLoginButtonDelegate {

    // MARK: - IBOutlets

    @IBOutlet var loginButton: FBSDKLoginButton!

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        loginButton = FBSDKLoginButton()
        loginButton.readPermissions = ["public_profile", "email", "user_friends"]
        loginButton.delegate = self
    }

    override func viewDidAppear(animated: Bool) {
        if FBSDKAccessToken.currentAccessToken() != nil {
            performSegueWithIdentifier("loggedInSegue", sender: nil)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - FBSDKLoginButtonDelegate functions

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if error == nil {
            //update facebook token
            performSegueWithIdentifier("loggedInSegue", sender: nil)
        } else {
            print(error.localizedDescription)
        }
    }

    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {

    }
}
