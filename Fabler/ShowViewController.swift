//
//  ShowViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import AlamofireImage

class ShowViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - IBOutlets

    @IBOutlet weak var showTableView: UITableView?
    @IBOutlet weak var showLabel: UILabel?
    @IBOutlet weak var subscribeButton: UIButton?
    @IBOutlet weak var settingsButton: UIButton?
    @IBOutlet weak var imageView: UIImageView?

    // MARK: - ShowViewController members

    var podcast: Podcast?
    var episodes: [Episode]?

    var refreshControl: UIRefreshControl?

    // MARK: - ShowViewController functions

    func refreshData(sender: AnyObject) {
        let service = EpisodeService()
        self.episodes = service.getEpisodesForPodcast(podcast!.podcastId, completion: { [weak self] (episodes) in
            if let controller = self {
                controller.episodes = episodes
                controller.showTableView?.reloadData()

                if let refresher = controller.refreshControl {
                    if refresher.refreshing {
                        refresher.endRefreshing()
                    }
                }
            }
        })
    }

    // MARK: - IBActions

    @IBAction func subscribeButtonPressed(sender: AnyObject) {
        if let podcast = self.podcast {
            let service = PodcastService()
            let subscribed = !(podcast.subscribed)

            self.subscribeButton?.setTitle(subscribed ? "Unsubscribe" : "Subscribe", forState: .Normal)

            service.subscribeToPodcast(podcast, subscribe: subscribed, completion: { [weak self] (result) in
                if let controller = self {
                    if !result {
                        controller.subscribeButton?.setTitle(!subscribed ? "Unsubscribe" : "Subscribe", forState: .Normal)
                    }
                }
            })
        }
    }

    @IBAction func settingsButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("displaySettingsSegue", sender: self.podcast)
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        guard podcast != nil else {
            print("expected a podcast initiated via previous controller")
            return
        }

        super.viewDidLoad()

        self.showLabel?.text = podcast?.title

        self.showTableView?.delegate = self
        self.showTableView?.dataSource = self

        self.automaticallyAdjustsScrollViewInsets = true

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()

        if let path = podcast?.image, let url = NSURL(string: path) {
            let placeholder = UIImage(named: "logo-launch")
            self.imageView?.af_setImageWithURL(url, placeholderImage: placeholder)
        }

        if !(podcast!.subscribed) {
            self.settingsButton?.hidden = true
            if let button = self.settingsButton {
                button.removeConstraints(button.constraints)
            }
        }

        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: "refreshData:", forControlEvents: UIControlEvents.ValueChanged)
            refresher.backgroundColor = UIColor.orangeColor()
            refresher.tintColor = UIColor.whiteColor()
            self.showTableView?.addSubview(refresher)
        }

        self.subscribeButton?.setTitle(self.podcast!.subscribed ? "Unsubscribe" : "Subscribe", forState: .Normal)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()

        self.refreshData(self)
        self.refreshControl?.beginRefreshing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayEpisodeSegue" {
            if let controller = segue.destinationViewController as? EpisodeTableViewController, let episode = sender as? Episode {
                controller.episode = episode
            }
        } else if segue.identifier == "displaySettingsSegue" {
            if let controller = segue.destinationViewController as? ShowSettingsTableViewController, let podcast = sender as? Podcast {
                controller.podcast = podcast
            }
        }
    }

    // MARK: - UITableViewController functions

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            print("Unexpected section selected.")
            return
        }

        guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }

        if let player = delegate.player {
            player.startPlayback(episodes![indexPath.row])
        }

        performSegueWithIdentifier("displayEpisodeSegue", sender: episodes![indexPath.row])
    }

    // MARK: - UITableViewDataSource functions

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count: Int = 0

        if let episodes = self.episodes {
            if episodes.count > 0 {
                count = 1
                self.showTableView?.backgroundView = nil
            }
        }

        if count == 0 {
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            let label = UILabel(frame: frame)

            label.text = "No episodes for this podcast."
            label.textAlignment = NSTextAlignment.Center

            self.showTableView?.backgroundView = label
            self.showTableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        }

        return count
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard episodes != nil else {
            return 0
        }

        return episodes!.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if let cell = cell as? EpisodeTableViewCell, let episode = episodes?[indexPath.row] {
            cell.titleLabel?.text = episode.title
        }

        return cell
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let detailAction = UITableViewRowAction(style: .Normal, title: "Details" , handler: { [weak self] (action: UITableViewRowAction, indexPath: NSIndexPath) in
            if let controller = self, let episode = controller.episodes?[indexPath.row] {
                controller.performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
            }
        })

        detailAction.backgroundColor = UIColor.orangeColor()

        return [detailAction]
    }
}
