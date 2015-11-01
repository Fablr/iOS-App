//
//  DiscoveryViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import UIKit

class DiscoveryViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var menuButton:UIBarButtonItem!

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        if revealViewController() != nil {
            menuButton.target = revealViewController()
            menuButton.action = "revealToggle:"
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
