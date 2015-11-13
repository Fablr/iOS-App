//
//  LargePlayerViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/13/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class LargePlayerViewController : UIViewController {

    // MARK: - IBActions

    @IBAction func doneButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - UIViewController functions

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
