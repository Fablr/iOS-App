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

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?

    // MARK: - EpisodeViewController members

    var episode: Episode?

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        self.titleLabel?.text = episode!.title
        self.subtitleLabel?.text = episode!.subtitle
        self.descriptionLabel?.text = episode!.episodeDescription
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.orangeColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
