//
//  EpisodeViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class EpisodeViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    // MARK: - EpisodeViewController members

    var episode: Episode?

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        titleLabel.text = episode!.title
        subtitleLabel.text = episode!.subtitle
        descriptionLabel.text = episode!.description
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
