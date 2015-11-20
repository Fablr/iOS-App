//
//  ShowViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class ShowViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - IBOutlets

    @IBOutlet weak var showTableView: UITableView!
    @IBOutlet weak var showLabel: UILabel!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!

    // MARK: - ShowTableViewController members

    var podcast: Podcast?
    var episodes: [Episode]?

    var header: UIView?

    // MARK: - IBActions

    @IBAction func subscribeButtonPressed(sender: AnyObject) {
        let service = PodcastService()
        let subscribed = !(podcast?.subscribed)!

        self.subscribeButton.setTitle(subscribed ? "Unsubscribe" : "Subscribe", forState: .Normal)

        service.subscribeToPodcast(podcast!, subscribe: subscribed, completion: { result in
            if result {
                self.podcast?.subscribed = subscribed
            } else {
                self.subscribeButton.setTitle(!subscribed ? "Unsubscribe" : "Subscribe", forState: .Normal)
            }
        })
    }

    @IBAction func settingsButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("displaySettingsSegue", sender: self.podcast)
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()
        self.showLabel.text = podcast?.title

        showTableView.delegate = self
        showTableView.dataSource = self

        self.automaticallyAdjustsScrollViewInsets = true

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()

        let service = EpisodeService()
        self.episodes = service.getEpisodesForPodcast(podcast!.id, completion: { episodes in
            self.episodes = episodes
            self.showTableView.reloadData()
        })

        if !(podcast!.subscribed) {
            self.settingsButton.hidden = true
            self.settingsButton.removeConstraints(self.settingsButton.constraints)
        }

        self.subscribeButton.setTitle(self.podcast!.subscribed ? "Unsubscribe" : "Subscribe", forState: .Normal)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayEpisodeSegue" {
            (segue.destinationViewController as! EpisodeViewController).episode = (sender as! Episode)
        } else if segue.identifier == "displaySettingsSegue" {
            (segue.destinationViewController as! ShowSettingsTableViewController).podcast = (sender as! Podcast)
        }
    }
    
    // MARK: - UITableViewController functions

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            print("Unexpected section selected.")
            return
        }

        let player = (UIApplication.sharedApplication().delegate as! AppDelegate).player!
        player.startPlayback(episodes![indexPath.row])

        performSegueWithIdentifier("displayEpisodeSegue", sender: episodes![indexPath.row])
    }

    // MARK: - UITableViewDataSource functions

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard episodes != nil else {
            return 0
        }

        return (episodes?.count)!
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! EpisodeTableViewCell

        if let episode = episodes?[indexPath.row] {
            cell.titleLabel.text = episode.title
        }
        
        return cell
    }
}
