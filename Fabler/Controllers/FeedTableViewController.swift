//
//  FeedTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 3/29/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import SWRevealViewController
import SwiftDate

public class FeedTableViewController: UITableViewController, PerformsUserSegueDelegate {

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
        // RevealView setup
        //
        if revealViewController() != nil {
            let menu = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: revealViewController(), action: #selector(SWRevealViewController.revealToggle))
            self.navigationItem.leftBarButtonItem = menu
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        //
        // Register Nibs for reuse
        //
        self.tableView.registerNib(UINib(nibName: "FeedFollowedCell", bundle: nil), forCellReuseIdentifier: "FollowedCell")

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

        self.refreshData(self)
        self.refreshControl?.beginRefreshing()
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayUserSegue" {
            if let controller = segue.destinationViewController as? UserViewController, let user = sender as? User {
                controller.user = user
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
            break

        case .Listened:
            break

        case .Subscribed:
            break

        case .None:
            fatalError()
        }

        return UITableViewCell()
    }

    // MARK: - PerformsUserSegue methods

    public func performSegueToUser(user: User) {
        performSegueWithIdentifier("displayUserSegue", sender: user)
    }
}
