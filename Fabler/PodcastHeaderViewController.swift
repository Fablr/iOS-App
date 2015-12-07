//
//  PodcastHeaderViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class PodcastHeaderViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var titleImage: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subscribeButton: UIButton?
    @IBOutlet weak var settingsButton: UIButton?

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
