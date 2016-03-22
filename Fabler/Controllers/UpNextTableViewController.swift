//
//  UpNextTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 3/3/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit

public class UpNextTableViewController: UITableViewController, PresentAlertControllerDelegate, PerformsEpisodeSegueDelegate {

    // MARK: - UpNextTableViewController methods

    @objc public func backButtonPressed() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - UIViewController methods

    override public func viewDidLoad() {
        let blurEffect = UIBlurEffect(style: .Light)
        let veView = UIVisualEffectView(effect: blurEffect)
        veView.frame = self.view.bounds
        self.view.backgroundColor = .clearColor()
        self.view.insertSubview(veView, atIndex: 0)

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 120.0

        self.tableView.editing = true

        self.tableView.registerNib(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: "EpisodeCell")
        self.tableView.registerNib(UINib(nibName: "UpNextSectionHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "SectionHeader")
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayEpisodeSegue" {
            if let navigator = segue.destinationViewController as? FablerNavigationController, let episode = sender as? Episode, let controller = navigator.topViewController as? EpisodeTableViewController {
                navigator.showPlayer = false
                controller.episode = episode
                controller.root = true
            }
        }
    }

    // MARK: - UITableViewController methods

    override public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FablerPlayer.sharedInstance.upNext.count
    }

    override public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterViewWithIdentifier("SectionHeader")

        if let cell = cell as? UpNextSectionHeaderView {
            cell.backButton.addTarget(self, action: #selector(UpNextTableViewController.backButtonPressed), forControlEvents: .TouchUpInside)
        }

        return cell
    }

    override public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 65.0
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EpisodeCell", forIndexPath: indexPath)

        let episode = FablerPlayer.sharedInstance.upNext[indexPath.row]

        if let cell = cell as? EpisodeTableViewCell {
            cell.setEpisodeInstance(episode, dynamicColor: false)

            cell.presentDelegate = self
            cell.segueDelegate = self

            cell.upNextEnabled = false
        }

        return cell
    }

    override public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let episode = FablerPlayer.sharedInstance.upNext.removeAtIndex(indexPath.row)

        FablerPlayer.sharedInstance.startPlayback(episode)

        self.tableView.reloadData()
    }

    override public func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
        let episode = FablerPlayer.sharedInstance.upNext.removeAtIndex(fromIndexPath.row)
        FablerPlayer.sharedInstance.upNext.insert(episode, atIndex: toIndexPath.row)
    }

    override public func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            FablerPlayer.sharedInstance.upNext.removeAtIndex(indexPath.row)
        }
    }

    // MARK: - PresentAlertControllerDelegate methods

    func presentAlert(controller: UIAlertController) {
        self.presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - PerformsEpisodeSegueDelegate methods

    func performSegueToEpisode(episode: Episode) {
        performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
    }
}
