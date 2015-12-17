//
//  UserEditViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/16/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Eureka

class UserEditViewController: FormViewController {

    // MARK: - UserEditViewController members

    var user: User?

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        guard self.user != nil else {
            Log.info("Expected a user initiated via previous controller.")
            return
        }

        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationItem.title = user!.userName
    }
}
