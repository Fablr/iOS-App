//
//  CollectionTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import AlamofireImage

class CollectionTableViewController: UITableViewController {

    // MARK: - IBOutlets

    @IBOutlet var menuButton: UIBarButtonItem?

    // MARK: - CollectionTableViewController members

    var podcasts: [Podcast]?

    var downloader: ImageDownloader?

    // MARK: - CollectionTableViewController functions

    func refreshData(sender: AnyObject) {
        let service = PodcastService()
        self.podcasts = service.readSubscribedPodcasts { [weak self] (podcasts) in
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

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate, let downloader = delegate.imageDownloader {
            self.downloader = downloader
        }

        if revealViewController() != nil {
            self.menuButton?.target = revealViewController()
            self.menuButton?.action = "revealToggle:"
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: "refreshData:", forControlEvents: UIControlEvents.ValueChanged)
            refresher.backgroundColor = UIColor.fablerOrangeColor()
            refresher.tintColor = UIColor.whiteColor()
            self.tableView.addSubview(refresher)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.refreshData(self)
        self.refreshControl?.beginRefreshing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
            print("Unexpected section selected.")
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
            let button = UIButton(type: UIButtonType.System) as UIButton

            button.tintColor = UIColor.fablerOrangeColor()
            button.setTitle("Click here to discover podcasts.", forState: .Normal)
            button.frame = frame
            button.addTarget(self, action: "discoverButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)

            self.tableView.backgroundView = button
            self.tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        }

        return count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard podcasts != nil else {
            return 0
        }

        return podcasts!.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if let cell = cell as? PodcastTableViewCell, let podcast = podcasts?[indexPath.row] {
            cell.titleLabel?.text = podcast.title

            if let url = NSURL(string: podcast.image) {
                cell.tileImage?.af_imageDownloader = self.downloader
                cell.tileImage?.af_setImageWithURL(url, placeholderImage: nil)
            }
        }

        return cell
    }
}
