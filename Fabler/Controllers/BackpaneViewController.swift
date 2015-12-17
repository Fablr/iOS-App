//
//  BackpaneViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class BackpaneViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var userButton: UIButton?

    @IBAction func userButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("pushUserSegue", sender: self.user)
    }

    // MARK: - BackpaneViewController members

    private var user: User?

    // MARK: - BackpaneViewController functions

    func updateUserElements() {
        if let title = self.user?.userName {
            self.userButton?.setTitle(title, forState: .Normal)
        }
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "pushUserSegue" {
            if let controller = segue.destinationViewController as? FablerNavigationController, let root = controller.viewControllers.first as? UserTableViewController, let user = sender as? User {
                root.user = user
                root.root = true
            }
        }
    }
}
