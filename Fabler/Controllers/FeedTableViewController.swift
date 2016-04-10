//
//  FeedTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 3/29/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import SwiftDate

public class FeedTableViewController: UITableViewController, PerformsUserSegueDelegate, PerformsPodcastSegueDelegate, PerformsEpisodeSegueDelegate {

    // MARK: - FeedTableViewController properties

    var events: [Event] = []

    // MARK: - FeedTableViewController methods

    public func refreshData(sender: AnyObject) {
        guard let user = User.getCurrentUser() else {
            return
        }

        let service = FeedService()

        service.getFeedFor(user) { [weak self] (events) in
            let sortedEvents = events.sort { $0.time > $1.time }

            self?.events = sortedEvents
            self?.tableView.reloadData()

            if let refresher = self?.refreshControl where refresher.refreshing {
                refresher.endRefreshing()
            }
        }
    }

    // MARK: - UIViewController methods

    override public func viewDidLoad() {
        super.viewDidLoad()

        //
        // Register Nibs for reuse
        //
        self.tableView.registerNib(UINib(nibName: "FeedFollowedCell", bundle: nil), forCellReuseIdentifier: "FollowedCell")
        self.tableView.registerNib(UINib(nibName: "FeedSubscribedCell", bundle: nil), forCellReuseIdentifier: "SubscribedCell")
        self.tableView.registerNib(UINib(nibName: "FeedListenedCell", bundle: nil), forCellReuseIdentifier: "ListenedCell")
        self.tableView.registerNib(UINib(nibName: "FeedCommentedCell", bundle: nil), forCellReuseIdentifier: "CommentedCell")

        //
        // RefreshControl setup
        //
        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: #selector(FeedTableViewController.refreshData), forControlEvents: .ValueChanged)
            refresher.backgroundColor = FablerColors.Orange.Regular
            refresher.tintColor = .whiteColor()
            self.tableView.addSubview(refresher)
        }

        //
        // TableView setup
        //
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 120.0
    }

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let navigation = self.navigationController as? FablerNavigationController {
            navigation.setDefaultNavigationBar()
        }

        self.refreshData(self)
        self.refreshControl?.beginRefreshing()
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayUserSegue" {
            if let controller = segue.destinationViewController as? UserViewController, let user = sender as? User {
                controller.user = user
            }
        } else if segue.identifier == "displayPodcastSegue" {
            if let controller = segue.destinationViewController as? PodcastTableViewController, let podcast = sender as? Podcast {
                controller.podcast = podcast
            }
        } else if segue.identifier == "displayEpisodeSegue" {
            if let controller = segue.destinationViewController as? EpisodeTableViewController, let episode = sender as? Episode {
                controller.episode = episode
            }
        }
    }

    // MARK: - UITableViewController methods

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let event = events[indexPath.row]

        switch event.eventType {
        case .Followed:
            let cell = tableView.dequeueReusableCellWithIdentifier("FollowedCell", forIndexPath: indexPath)

            if let cell = cell as? FeedFollowedTableViewCell {
                cell.delegate = self
                cell.setEventInstance(event)
            }

            return cell

        case .Commented:
            let cell = tableView.dequeueReusableCellWithIdentifier("CommentedCell", forIndexPath: indexPath)

            if let cell = cell as? FeedCommentedTableViewCell {
                cell.userDelegate = self
                cell.podcastDelegate = self
                cell.episodeDelegate = self
                cell.setEventInstance(event)
            }

            return cell

        case .Listened:
            let cell = tableView.dequeueReusableCellWithIdentifier("ListenedCell", forIndexPath: indexPath)

            if let cell = cell as? FeedListenedTableViewCell {
                cell.userDelegate = self
                cell.podcastDelegate = self
                cell.episodeDelegate = self
                cell.setEventInstance(event)
            }

            return cell

        case .Subscribed:
            let cell = tableView.dequeueReusableCellWithIdentifier("SubscribedCell", forIndexPath: indexPath)

            if let cell = cell as? FeedSubscribedTableViewCell {
                cell.userDelegate = self
                cell.podcastDelegate = self
                cell.setEventInstance(event)
            }

            return cell

        case .None:
            fatalError("Invalid feed event")
        }
    }

    // MARK: - PerformsUserSegue methods

    public func performSegueToUser(user: User) {
        performSegueWithIdentifier("displayUserSegue", sender: user)
    }

    // MARK: - PerformsPodcastSegue methods

    public func performSegueToPodcast(podcast: Podcast) {
        performSegueWithIdentifier("displayPodcastSegue", sender: podcast)
    }

    // MARK: - PerformsEpisodeSegue methods

    public func performSegueToEpisode(episode: Episode) {
        performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
    }
}
