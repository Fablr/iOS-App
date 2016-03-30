//
//  FeedTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 3/29/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import SWRevealViewController

public class FeedTableViewController: UITableViewController {

    // MARK: - FeedTableViewController properties

    var events: [Event] = []

    // MARK: - FeedTableViewController methods

    public func refreshData(sender: AnyObject) {
        guard let user = User.getCurrentUser() else {
            return
        }

        let service = FeedService()

        service.getFeedFor(user) { [weak self] (events) in
            self?.events = events
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
        self.tableView.registerNib(UINib(nibName: "FeedSubscribedCell", bundle: nil), forCellReuseIdentifier: "SubscribedCell")

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

    // MARK: - UITableViewController methods

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SubscribedCell", forIndexPath: indexPath)

        if let cell = cell as? FeedSubscribedTableViewCell {
            let event = events[indexPath.row]

            if let userName = event.user?.userName {
                cell.userButton?.setTitle(userName, forState: .Normal)
            }

            cell.eventLabel?.text = "\(event.eventTypeRaw) at \(event.time)"
        }

        return cell
    }
}
