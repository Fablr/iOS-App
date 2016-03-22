//
//  CollectionTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Kingfisher
import SWRevealViewController

class CollectionTableViewController: UITableViewController {

    // MARK: - IBOutlets

    @IBOutlet var menuButton: UIBarButtonItem?

    // MARK: - CollectionTableViewController properties

    var podcasts: [Podcast]?

    // MARK: - CollectionTableViewController methods

    func refreshData(sender: AnyObject) {
        let service = PodcastService()
        self.podcasts = service.getSubscribedPodcasts { [weak self] (podcasts) in
            if let controller = self {
                controller.podcasts = podcasts
                controller.tableView.reloadData()

                if let refresher = controller.refreshControl {
                    if refresher.refreshing {
                        refresher.endRefreshing()
                    }
                }
            }
        }
    }

    func discoverButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("displayDiscoverySegue", sender: self)
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        if revealViewController() != nil {
            self.menuButton?.target = revealViewController()
            self.menuButton?.action = #selector(SWRevealViewController.revealToggle)
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        self.tableView.registerNib(UINib(nibName: "PodcastCell", bundle: nil), forCellReuseIdentifier: "PodcastCell")

        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: #selector(CollectionTableViewController.refreshData), forControlEvents: .ValueChanged)
            refresher.backgroundColor = .fablerOrangeColor()
            refresher.tintColor = .whiteColor()
            self.tableView.addSubview(refresher)
        }
    }

    override func viewWillAppear(animated: Bool) {
        if let navigation = self.navigationController as? FablerNavigationController {
            navigation.setDefaultNavigationBar()
        }

        super.viewWillAppear(animated)

        self.refreshData(self)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayPodcastSegue" {
            if let controller = segue.destinationViewController as? PodcastTableViewController, let podcast = sender as? Podcast {
                controller.podcast = podcast
            }
        }
    }

    // MARK: - UITableViewController functions

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            Log.warning("Unexpected section selected.")
            return
        }

        performSegueWithIdentifier("displayPodcastSegue", sender: podcasts![indexPath.row])
    }

    // MARK: - UITableViewDataSource functions

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count: Int = 0

        if let podcasts = self.podcasts {
            if podcasts.count > 0 {
                count = 1
                self.tableView.backgroundView = nil
            }
        }

        if count == 0 {
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            let button = UIButton(type: .System)

            button.tintColor = .fablerOrangeColor()
            button.setTitle("Click here to discover podcasts.", forState: .Normal)
            button.frame = frame
            button.addTarget(self, action: #selector(CollectionTableViewController.discoverButtonPressed), forControlEvents: .TouchUpInside)

            self.tableView.backgroundView = button
            self.tableView.separatorStyle = .None
        }

        return count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let podcasts = self.podcasts else {
            return 0
        }

        return podcasts.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PodcastCell", forIndexPath: indexPath)

        if let cell = cell as? PodcastTableViewCell, let podcast = podcasts?[indexPath.row] {
            cell.setPodcastInstance(podcast)
        }

        return cell
    }
}
