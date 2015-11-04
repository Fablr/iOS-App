//
//  ShowViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 AppCoda. All rights reserved.
//

import UIKit

class ShowViewController: UITableViewController {

    // MARK: - IBOutlets

    // MARK: - ShowViewController members

    var podcast: Podcast?
    var episodes: [Episode]?
    
    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = podcast?.title

        let service = EpisodeService()
        service.getEpisodesForPodcast(podcast!.id, completion: { episodes in
            self.episodes = episodes
            self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
