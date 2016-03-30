//
//  FeedTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 3/29/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import SWRevealViewController

public class FeedTableViewController: UITableViewController {

    // MARK: - UIViewController methods

    override public func viewDidLoad() {
        super.viewDidLoad()

        if revealViewController() != nil {
            let menu = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: revealViewController(), action: #selector(SWRevealViewController.revealToggle))
            self.navigationItem.leftBarButtonItem = menu
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
    }
}
