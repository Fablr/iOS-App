//
//  ShowViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class ShowTableViewController: UITableViewController {

    // MARK: - ShowTableViewController members

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

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayEpisodeSegue" {
            (segue.destinationViewController as! EpisodeViewController).episode = (sender as! Episode)
        }
    }

    // MARK: - UITableViewController functions

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            print("Unexpected section selected.")
            return
        }

        performSegueWithIdentifier("displayEpisodeSegue", sender: episodes![indexPath.row])
    }

    // MARK: - UITableViewDataSource functions

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard episodes != nil else {
            return 0
        }

        return (episodes?.count)!
    }


    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodeTableViewCell

        if let episode = episodes?[indexPath.row] {
            cell.titleLabel.text = episode.title
        }
        
        return cell
    }
}
