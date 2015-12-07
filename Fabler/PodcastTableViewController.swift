//
//  ShowViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import AlamofireImage
import SlackTextViewController

class PodcastTableViewController: SLKTextViewController {

    // MARK: - PodcastViewController members

    var podcast: Podcast?
    var episodes: [Episode] = []
    var filteredEpisodes: [Episode] = []
    var comments: [Comment] = []

    var refreshControl: UIRefreshControl?
    var headerController: PodcastHeaderViewController?

    var currentSegment: Int = 0

    // MARK: - PodcastTableViewController functions

    func filterEpisodes() {
        switch self.currentSegment {
        case 0:
            self.filteredEpisodes = self.episodes.filter({!($0.completed)})
        case 1:
            self.filteredEpisodes = self.episodes
        default:
            break
        }
    }

    func refreshData(sender: AnyObject) {
        switch self.currentSegment {
        case 0:
            self.refreshEpisodeData(sender)
        case 1:
            self.refreshEpisodeData(sender)
        case 2:
            self.refreshCommentData(sender)
        default:
            break
        }
    }

    func refreshEpisodeData(sender: AnyObject) {
        let service = EpisodeService()
        self.episodes = service.getEpisodesForPodcast(podcast!.podcastId, completion: { [weak self] (episodes) in
            if let controller = self {
                controller.episodes = episodes
                controller.filterEpisodes()
                controller.tableView?.reloadData()

                if let refresher = controller.refreshControl {
                    if refresher.refreshing {
                        refresher.endRefreshing()
                    }
                }
            }
        })

        self.filterEpisodes()
    }

    func refreshCommentData(sender: AnyObject) {
        if let podcast = self.podcast {
            let service = CommentService()

            service.getCommentsForPodcast(podcast.podcastId, completion: { [weak self] (comments) in
                if let controller = self {
                    controller.comments = comments
                    controller.tableView.reloadData()

                    if let refresher = controller.refreshControl {
                        if refresher.refreshing {
                            refresher.endRefreshing()
                        }
                    }
                }
            })
        }
    }

    func subscribeButtonPressed(sender: AnyObject) {
        if let podcast = self.podcast {
            let service = PodcastService()
            let subscribed = !(podcast.subscribed)

            self.headerController?.subscribeButton?.setTitle(subscribed ? "Unsubscribe" : "Subscribe", forState: .Normal)

            service.subscribeToPodcast(podcast, subscribe: subscribed, completion: { [weak self] (result) in
                if let controller = self {
                    if !result {
                        controller.headerController?.subscribeButton?.setTitle(!subscribed ? "Unsubscribe" : "Subscribe", forState: .Normal)
                    }
                }
            })
        }
    }

    func settingsButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("displaySettingsSegue", sender: self.podcast)
    }

    func userTapped(sender: AnyObject) {
        self.setTextInputbarHidden(true, animated: true)
    }

    func addMessage(message: String, parent: Int?) {
        if let podcast = self.podcast {
            let service = CommentService()
            service.addCommentForPodcast(podcast.podcastId, comment: message, parentCommentId: parent, completion: { [weak self] (result) in
                if let controller = self {
                    if result {
                        controller.refreshCommentData(controller)
                    } else {
                        let alertController = UIAlertController(title: nil, message: "Unable to post comment.", preferredStyle: UIAlertControllerStyle.Alert)
                        let dismissAction = UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.Cancel, handler: nil)
                        alertController.addAction(dismissAction)
                        controller.presentViewController(alertController, animated: true, completion: nil)
                    }
                }
            })
        }
    }

    func segmentSelectionChanged(sender: UISegmentedControl) {
        let refresh: Bool = (sender.selectedSegmentIndex != self.currentSegment)

        self.currentSegment = sender.selectedSegmentIndex

        if refresh {
            self.refreshData(self)
            self.refreshControl?.beginRefreshing()

            self.tableView.reloadData()
        }
    }

    // MARK: - SLKTextViewController functions

    override class func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
        return UITableViewStyle.Plain;
    }

    override func didPressLeftButton(sender: AnyObject!) {
        self.setTextInputbarHidden(true, animated: true)
    }

    override func didPressRightButton(sender: AnyObject!) {
        if let message = self.textView.text.copy() as? String {
            self.addMessage(message, parent: nil)
        }

        super.didPressRightButton(sender)
        self.setTextInputbarHidden(true, animated: true)
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        guard podcast != nil else {
            print("expected a podcast initiated via previous controller")
            return
        }

        super.viewDidLoad()

        //
        // Register Nibs for reuse
        //
        self.tableView.registerNib(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: "EpisodeCell")
        self.tableView.registerNib(UINib(nibName: "EpisodeHeaderCell", bundle: nil), forCellReuseIdentifier: "EpisodeHeaderCell")
        self.tableView.registerNib(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")

        //
        // TableView setup
        //
        self.headerController = PodcastHeaderViewController(nibName: "PodcastHeader", bundle: nil)
        self.tableView.tableHeaderView = self.headerController?.view

        if let header = self.headerController {
            var frame = header.view.frame
            frame.size = CGSizeMake(header.view.frame.size.width, 200.0)
            header.view.frame = frame
        }

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 50.0

        self.tableView.allowsMultipleSelection = false

        self.automaticallyAdjustsScrollViewInsets = false
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0)

        //
        // SLKTextViewController setup
        //
        self.bounces = true
        self.shakeToClearEnabled = true
        self.keyboardPanningEnabled = false
        self.inverted = false

        self.leftButton.setImage(UIImage(named: "delete"), forState: UIControlState.Normal)
        self.leftButton.tintColor = UIColor.orangeColor()
        self.rightButton.setTitle("Send", forState: UIControlState.Normal)
        self.rightButton.tintColor = UIColor.orangeColor()

        self.textInputbar.autoHideRightButton = true

        self.textView.placeholder = "Add a comment."
        self.textView.placeholderColor = UIColor.lightGrayColor()

        self.textView.registerMarkdownFormattingSymbol("**", withTitle: "Bold")
        self.textView.registerMarkdownFormattingSymbol("_", withTitle: "Italics")
        self.textView.registerMarkdownFormattingSymbol("~~", withTitle: "Strike")

        self.singleTapGesture.addTarget(self, action: "userTapped:")
        self.setTextInputbarHidden(true, animated: false)

        //
        // Static element setup
        //
        self.headerController?.titleLabel?.text = podcast?.title

        if let path = podcast?.image, let url = NSURL(string: path) {
            let placeholder = UIImage(named: "logo-launch")
            self.headerController?.titleImage?.af_setImageWithURL(url, placeholderImage: placeholder)
        }

        if !(podcast!.subscribed) {
            self.headerController?.settingsButton?.hidden = true
            if let button = self.headerController?.settingsButton {
                button.removeConstraints(button.constraints)
            }
        } else {
            self.headerController?.settingsButton?.addTarget(self, action: "settingsButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
        }

        self.headerController?.subscribeButton?.setTitle(self.podcast!.subscribed ? "Unsubscribe" : "Subscribe", forState: .Normal)
        self.headerController?.subscribeButton?.addTarget(self, action: "subscribeButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)

        //
        // RefreshControl setup
        //
        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: "refreshData:", forControlEvents: UIControlEvents.ValueChanged)
            refresher.backgroundColor = UIColor.orangeColor()
            refresher.tintColor = UIColor.whiteColor()
            self.tableView.addSubview(refresher)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()

        //
        // Refresh data
        //
        self.refreshEpisodeData(self)
        self.refreshCommentData(self)
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
            if let controller = segue.destinationViewController as? PodcastSettingsTableViewController, let podcast = sender as? Podcast {
                controller.podcast = podcast
            }
        }
    }

    // MARK: - UITableViewController functions

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let cell = tableView.dequeueReusableCellWithIdentifier("EpisodeHeaderCell") as? EpisodeHeaderTableViewCell {
            cell.segmentedControl?.addTarget(self, action: "segmentSelectionChanged:", forControlEvents: UIControlEvents.ValueChanged)
            cell.segmentedControl?.selectedSegmentIndex = self.currentSegment

            return cell.contentView
        }

        return UIView()
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch self.currentSegment {
        case 0:
            self.episodesDidSelectRowAtIndexPath(indexPath)
        case 1:
            self.episodesDidSelectRowAtIndexPath(indexPath)
        case 2:
            self.commentsDidSelectRowAtIndexPath(indexPath)
        default:
            break
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let result: Int

        switch self.currentSegment {
        case 0:
            result = self.episodesNumberOfSectionsInTableView()
        case 1:
            result = self.episodesNumberOfSectionsInTableView()
        case 2:
            result = self.commentsNumberOfSectionsInTableView()
        default:
            result = 1
        }

        return result
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result: Int

        switch self.currentSegment {
        case 0:
            result = self.filteredEpisodes.count
        case 1:
            result = self.filteredEpisodes.count
        case 2:
            result = self.comments.count
        default:
            result = 0
        }

        return result
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let result: UITableViewCell

        switch self.currentSegment {
        case 0:
            result = self.episodesSetupCell(indexPath)
        case 1:
            result = self.episodesSetupCell(indexPath)
        case 2:
            result = self.commentsSetupCell(indexPath)
        default:
            result = UITableViewCell()
        }

        return result
    }

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let result: [UITableViewRowAction]?

        switch self.currentSegment {
        case 0:
            result = self.episodesEditActions(indexPath)
        case 1:
            result = self.episodesEditActions(indexPath)
        case 2:
            result = self.commentsEditActions(indexPath)
        default:
            result = nil
        }

        return result
    }

    // MARK: - PodcastTableViewController episode table functions

    func setupTableForEpisodes() {
        self.tableView.allowsSelection = true
    }

    func episodesDidSelectRowAtIndexPath(indexPath: NSIndexPath) {
        guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }

        let episode = filteredEpisodes[indexPath.row]

        if let player = delegate.player {
            player.startPlayback(episode)
            performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
        }
    }

    func episodesNumberOfSectionsInTableView() -> Int {
        if self.filteredEpisodes.count > 0 {
            self.tableView?.backgroundView = nil
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        } else {
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            let label = UILabel(frame: frame)

            label.text = "No episodes for this podcast."
            label.textAlignment = NSTextAlignment.Center

            self.tableView?.backgroundView = label
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        }

        return 1
    }

    func episodesSetupCell(indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EpisodeCell", forIndexPath: indexPath)

        let episode = filteredEpisodes[indexPath.row]

        if let cell = cell as? EpisodeTableViewCell {
            cell.setEpisodeInstance(episode)
        }

        return cell
    }

    func episodesEditActions(indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let detailAction = UITableViewRowAction(style: .Normal, title: "Details" , handler: { [weak self] (action: UITableViewRowAction, indexPath: NSIndexPath) in
            if let controller = self {
                let episode = controller.filteredEpisodes[indexPath.row]
                controller.performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
            }
        })

        detailAction.backgroundColor = UIColor.orangeColor()

        return [detailAction]
    }

    // MARK: - PodcastTableViewController comment table functions

    func setupTableForComments() {
        self.tableView.allowsSelection = false
    }

    func commentsDidSelectRowAtIndexPath(indexPath: NSIndexPath) {
        return
    }

    func commentsNumberOfSectionsInTableView() -> Int {
        if self.comments.count > 0 {
            self.tableView.backgroundView = nil
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        } else {
            //
            // Display empty view message but, still display section header
            //
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            let label = UILabel(frame: frame)

            label.text = "No comments for this podcast."
            label.textAlignment = NSTextAlignment.Center

            self.tableView?.backgroundView = label
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        }

        return 1
    }

    func commentsSetupCell(indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath)

        let comment = comments[indexPath.row]

        if let cell = cell as? CommentTableViewCell {
            cell.setCommentInstance(comment)
        }

        return cell
    }

    func commentsEditActions(indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        return nil
    }
}
