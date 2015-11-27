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
}
