//
//  YouViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/26/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class YouViewController: UIViewController, FBSDKLoginButtonDelegate {

    // MARK: - IBOutlets

    @IBOutlet weak var menuButton: UIBarButtonItem?
    @IBOutlet weak var loginButton: FBSDKLoginButton?
    @IBOutlet weak var userNameLabel: UILabel?
    @IBOutlet weak var firstNameLabel: UILabel?
    @IBOutlet weak var lastNameLabel: UILabel?

    // MARK: - YouViewController members

    private var user: User?

    // MARK: - YouViewController functions

    func updateUserElements() {
        if let user = self.user {
            self.userNameLabel?.text = user.userName
            self.firstNameLabel?.text = user.firstName
            self.lastNameLabel?.text = user.lastName
        }
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        self.loginButton = FBSDKLoginButton()
        self.loginButton?.readPermissions = ["public_profile", "email", "user_friends"]
        self.loginButton?.delegate = self

        if revealViewController() != nil {
            menuButton?.target = revealViewController()
            menuButton?.action = "revealToggle:"
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(CurrentUserDidChangeNotification, object: nil, queue: mainQueue) { [weak self] (_) in
            if let controller = self {
                controller.user = User.getCurrentUser()
                controller.updateUserElements()
            }
        }

        self.user = User.getCurrentUser()
        updateUserElements()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - FBSDKLoginButtonDelegate functions

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if error != nil {
            Log.error(error.localizedDescription)
        }
    }

    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        performSegueWithIdentifier("loggedOutSegue", sender: nil)
    }
}
