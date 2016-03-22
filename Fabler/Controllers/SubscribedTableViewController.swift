//
//  SubscribedTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 3/22/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import RealmSwift

public class SubscribedTableViewController: UITableViewController {

    // MARK: - SubscribedTableViewController properties

    public var user: User?
    private var podcasts: [Podcast] = []

    // MARK: - SubscribedTableViewController methods

    public func refreshData(sender: AnyObject) {
        guard let user = self.user else {
            return
        }

        let service = UserService()
        service.getSubscribed(user) { [weak self] (result) in
            guard let controller = self else {
                return
            }

            if let user = controller.user {
                controller.podcasts = Array(user.subscribed)
                controller.tableView.reloadData()
            }

            if let refresher = controller.refreshControl where refresher.refreshing {
                refresher.endRefreshing()
            }
        }
    }

    // MARK: - UIViewController methods

    override public func viewDidLoad() {
        guard let user = self.user else {
            return
        }

        self.podcasts = Array(user.subscribed)

        let suffix: String
        if let lastCharacter = user.userName.characters.last where lastCharacter == "s" {
            suffix = "' Podcasts"
        } else {
            suffix = "'s Podcasts"
        }

        self.navigationItem.title = "\(user.userName)\(suffix)"

        self.tableView.registerNib(UINib(nibName: "PodcastCell", bundle: nil), forCellReuseIdentifier: "PodcastCell")

        self.tableView.separatorStyle = .None

        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: #selector(SubscribedTableViewController.refreshData), forControlEvents: .ValueChanged)
            refresher.backgroundColor = .fablerOrangeColor()
            refresher.tintColor = .whiteColor()
            self.tableView.addSubview(refresher)
        }

        if self.podcasts.isEmpty {
            self.refreshData(self)
        }

        super.viewDidLoad()
    }

    override public func viewWillAppear(animated: Bool) {
        if let navigation = self.navigationController as? FablerNavigationController {
            navigation.setDefaultNavigationBar()
        }

        super.viewWillAppear(animated)
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? PodcastTableViewController, let podcast = sender as? Podcast where segue.identifier == "displayPodcastSegue" {
            controller.podcast = podcast
        }
    }

    // MARK: - UITableViewController methods

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.podcasts.count
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("PodcastCell", forIndexPath: indexPath)

        if let cell = cell as? PodcastTableViewCell {
            let podcast = self.podcasts[indexPath.row]

            cell.setPodcastInstance(podcast)
        }

        return cell
    }

    override public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 115.0
    }

    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let podcast = self.podcasts[indexPath.row]

        self.performSegueWithIdentifier("displayPodcastSegue", sender: podcast)
    }
}
