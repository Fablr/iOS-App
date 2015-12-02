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

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        if revealViewController() != nil {
            self.menuButton?.target = revealViewController()
            self.menuButton?.action = "revealToggle:"
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        let service = PodcastService()
        self.podcasts = service.readSubscribedPodcasts { podcasts in
            self.podcasts = podcasts
            self.tableView.reloadData()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.orangeColor()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayShowSegue" {
            if let controller = segue.destinationViewController as? ShowViewController, let podcast = sender as? Podcast {
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

        performSegueWithIdentifier("displayShowSegue", sender: podcasts![indexPath.row])
    }

    // MARK: - UITableViewDataSource functions

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard podcasts != nil else {
            return 0
        }

        return podcasts!.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)

        if let cell = cell as? ShowTableViewCell, let podcast = podcasts?[indexPath.row] {
            cell.titleLabel?.text = podcast.title

            if let url = NSURL(string: podcast.image) {
                let placeholder = UIImage(named: "logo-launch")
                cell.tileImage?.af_setImageWithURL(url, placeholderImage: placeholder)
            }
        }

        return cell
    }
}
