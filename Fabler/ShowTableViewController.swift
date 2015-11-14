//
//  ShowViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class ShowTableViewController: UITableViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var subscribeButton: UIBarButtonItem!

    // MARK: - ShowTableViewController members

    var podcast: Podcast?
    var episodes: [Episode]?

    // MARK: - IBActions

    @IBAction func subscribeButtonPressed(sender: AnyObject) {
        let service = PodcastService()
        let subscribed = !(podcast?.subscribed)!

        self.subscribeButton.title = subscribed ? "Unsubscribe" : "Subscribe"

        service.subscribeToPodcast(podcast!, subscribe: subscribed, completion: { result in
            if result {
                self.podcast?.subscribed = subscribed
            } else {
                self.subscribeButton.title = !subscribed ? "Unsubscribe" : "Subscribe"
            }
        })
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = podcast?.title

        let service = EpisodeService()
        self.episodes = service.getEpisodesForPodcast(podcast!.id, completion: { episodes in
            self.episodes = episodes
            self.tableView.reloadData()
        })

        self.subscribeButton.title = self.podcast!.subscribed ? "Unsubscribe" : "Subscribe"
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

        let player = (UIApplication.sharedApplication().delegate as! AppDelegate).player!
        player.startPlayback(episodes![indexPath.row])

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
