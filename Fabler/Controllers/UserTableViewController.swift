//
//  UserTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/15/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class UserTableViewController: UITableViewController {

    // MARK: UserTableViewController members

    var user: User?

    // MARK: UIViewController functions

    override func viewDidLoad() {
        guard self.user != nil else {
            Log.error("Expected a user initiated via previous controller.")
            return
        }

        super.viewDidLoad()

        self.navigationItem.title = user!.userName
    }
}
