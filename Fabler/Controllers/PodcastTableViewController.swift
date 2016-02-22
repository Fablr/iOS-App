//
//  PodcastTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import SlackTextViewController
import Kingfisher
import Hue

class PodcastTableViewController: SLKTextViewController, CollapsibleUITableViewCellDelegate, RepliesToCommentDelegate, ChangesBasedOnSegment, PerformsUserSegueDelegate {

    // MARK: - PodcastTableViewController data members

    var podcast: Podcast?
    var episodes: [Episode] = []
    var filteredEpisodes: [Episode] = []
    var comments: [Comment] = []

    // MARK: - PodcastTableViewController ui members

    var refreshControl: UIRefreshControl?
    var headerImage: UIImageView?
    var blurredHeaderImage: UIImageView?
    var titleLabel: UILabel?
    var settingsButton: UIButton?
    var subscribeButton: UIButton?
    var settingsButtonWidth: NSLayoutConstraint?

    // MARK: - PodcastTableViewController magic members

    let headerHeight: CGFloat = 130.0
    let subHeaderHeight: CGFloat = 70.0
    var headerSwitchOffset: CGFloat = 0.0
    var barAnimationComplete: Bool = false
    var barIsCollapsed: Bool = false

    // MARK: - CollapsibleUITableViewCellDelegate members

    var indexPath: NSIndexPath?
    var collapsed: Bool?

    // MARK: - RepliesToCommentDelegate members

    var replyComment: Comment?
    var editingComment: Bool = false

    // MARK: - ChangesBasedOnSegment members

    var currentSegment: Int = 0

    // MARK: - Colors

    var backgroundColor: UIColor = UIColor.fablerOrangeColor()
    var primaryColor: UIColor = UIColor.fablerOrangeColor()

    // MARK: - PodcastTableViewController functions

    func setupImages() {
        if let podcast = self.podcast, let url = NSURL(string: podcast.image) {
            let manager = KingfisherManager.sharedManager
            let cache = manager.cache

            let id = podcast.podcastId
            let key = "\(id)-header-blurred"

            if let image = cache.retrieveImageInDiskCacheForKey(url.absoluteString), let blurred = cache.retrieveImageInDiskCacheForKey(key) {
                let service = PodcastService()

                if !podcast.primarySet || !podcast.backgroundSet {
                    let colors = image.colors()
                    service.setPrimaryColorForPodcast(podcast, color: colors.primary)
                    service.setBackgroundColorForPodcast(podcast, color: colors.background)
                }

                self.updateImages(image, blurred: blurred)
            } else {
                manager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { [weak self] (image, error, cacheType, url) in
                    if error == nil, let image = image {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [weak self] in
                            let service = PodcastService()

                            if let podcast = service.readPodcastFor(id, completion: nil) {
                                if !podcast.primarySet || !podcast.backgroundSet {
                                    let colors = image.colors()
                                    service.setPrimaryColorForPodcast(podcast, color: colors.primary)
                                    service.setBackgroundColorForPodcast(podcast, color: colors.background)
                                }
                            }

                            Log.debug("Attempting to blur image.")

                            if let blurred = image.imageWithAppliedCoreImageFilter("CIGaussianBlur", filterParameters: ["inputRadius": 25.0]) {
                                Log.debug("Caching blurred header image.")
                                cache.storeImage(blurred, forKey: key)

                                dispatch_async(dispatch_get_main_queue(), { [weak self] in
                                    Log.debug("Setting blurred header image.")

                                    if let controller = self {
                                        controller.updateImages(image, blurred: blurred)
                                    }
                                })
                            }
                        })
                    }
                })
            }
        }
    }

    func updateImages(image: UIImage, blurred: UIImage) {
        self.blurredHeaderImage?.image = blurred
        self.headerImage?.image = image

        if let podcast = self.podcast, let primary = podcast.primaryColor, var background = podcast.backgroundColor {
            self.navigationController?.navigationBar.tintColor = primary
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: primary]

            if !background.isDark {
                background = primary
            }

            self.subscribeButton?.tintColor = background
            self.settingsButton?.tintColor = background
            self.titleLabel?.textColor = background

            self.backgroundColor = background
            self.primaryColor = primary

            self.tableView.reloadData()
        }
    }

    func filterEpisodes() {
        switch self.currentSegment {
        case 0:
            self.filteredEpisodes = self.episodes.filter({ $0.download != nil })
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
        if let podcast = self.podcast {
            let service = EpisodeService()
            self.episodes = service.getEpisodesForPodcast(podcast, completion: { [weak self] (episodes) in
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
    }

    func refreshCommentData(sender: AnyObject) {
        if let podcast = self.podcast {
            let service = CommentService()

            service.getCommentsForPodcast(podcast, completion: { [weak self] (comments) in
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

            self.updateSubscribeButton(subscribed)

            service.subscribeToPodcast(podcast, subscribe: subscribed, completion: { [weak self] (result) in
                if let controller = self {
                    if !result {
                        controller.updateSubscribeButton(!subscribed)
                    }
                }
            })
        }
    }

    func commentButtonPressed(sender: AnyObject) {
        self.replyComment = nil
        self.didRequestKeyboard()
    }

    func updateSubscribeButton(override: Bool?) {
        if let override = override {
            if override {
                self.subscribeButton?.setTitle("Unsubscribe", forState: .Normal)
                self.settingsButtonWidth?.constant = 70.0
            } else {
                self.subscribeButton?.setTitle("Subscribe", forState: .Normal)
                self.settingsButtonWidth?.constant = 0.0
            }
        } else if let podcast = self.podcast {
            if podcast.subscribed {
                self.subscribeButton?.setTitle("Unsubscribe", forState: .Normal)
                self.settingsButtonWidth?.constant = 70.0
            } else {
                self.subscribeButton?.setTitle("Subscribe", forState: .Normal)
                self.settingsButtonWidth?.constant = 0.0
            }
        }
    }

    func settingsButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("displaySettingsSegue", sender: self.podcast)
    }

    // MARK: - SLKTextViewController functions

    func didDismissKeyboard() {
        if let navigationController = self.navigationController as? FablerNavigationController {
            navigationController.displaySmallPlayer()
        }

        self.replyComment = nil
        self.editingComment = false
        self.setTextInputbarHidden(true, animated: true)
    }

    func didRequestKeyboard() {
        if let navigationController = self.navigationController as? FablerNavigationController {
            navigationController.dismissSmallPlayer()
        }

        self.setTextInputbarHidden(false, animated: true)
        self.textView.becomeFirstResponder()
    }

    override class func tableViewStyleForCoder(decoder: NSCoder) -> UITableViewStyle {
        return UITableViewStyle.Plain;
    }

    override func didPressLeftButton(sender: AnyObject!) {
        self.didDismissKeyboard()
    }

    override func didPressRightButton(sender: AnyObject!) {
        if let message = self.textView.text.copy() as? String, let podcast = self.podcast {
            let service = CommentService()

            if !self.editingComment {
                let id = self.replyComment?.commentId

                service.addCommentForPodcast(podcast, comment: message, parentCommentId: id, completion: { [weak self] (result) in
                    if let controller = self {
                        if result {
                            controller.refreshData(controller)
                        }
                    }
                })
            } else {
                if let comment = self.replyComment {
                    let service = CommentService()
                    service.editComment(comment, newComment: message, completion: { [weak self] result in
                        if let controller = self {
                            if result {
                                controller.refreshData(controller)
                            }
                        }
                    })
                }
            }
        }

        super.didPressRightButton(sender)
        self.didDismissKeyboard()
    }

    // MARK: - UIViewController functions

    // swiftlint:disable function_body_length
    override func viewDidLoad() {
        guard self.podcast != nil else {
            Log.error("expected a podcast initiated via previous controller")
            return
        }

        super.viewDidLoad()

        //
        // TableView setup
        //
        let statusBarHeight = UIApplication.sharedApplication().statusBarFrame.size.height
        let navBarHeight: CGFloat
        if let navigationController = self.navigationController {
            navBarHeight = navigationController.navigationBar.frame.size.height
        } else {
            navBarHeight = 0.0
        }

        self.headerSwitchOffset = self.headerHeight - (statusBarHeight + navBarHeight) - statusBarHeight - navBarHeight

        self.headerImage = UIImageView()
        self.blurredHeaderImage?.backgroundColor = UIColor(red: 225.0/255.0, green: 225.0/255.0, blue: 225.0/255.0, alpha: 1.0)
        self.headerImage?.translatesAutoresizingMaskIntoConstraints = false
        self.headerImage?.contentMode = .ScaleAspectFill
        self.headerImage?.clipsToBounds = true

        self.blurredHeaderImage = UIImageView()
        self.blurredHeaderImage?.backgroundColor = UIColor(red: 225.0/255.0, green: 225.0/255.0, blue: 225.0/255.0, alpha: 1.0)
        self.blurredHeaderImage?.translatesAutoresizingMaskIntoConstraints = false
        self.blurredHeaderImage?.contentMode = .ScaleAspectFill
        self.blurredHeaderImage?.clipsToBounds = true

        let header = UIView(frame: CGRectMake(0, 0, self.view.frame.size.width, self.headerHeight - (statusBarHeight + navBarHeight) + self.subHeaderHeight))

        let sub = self.createSubHeader()
        sub.translatesAutoresizingMaskIntoConstraints = false

        if let image = self.headerImage, let blurredImage = self.blurredHeaderImage {
            header.addSubview(image)
            header.insertSubview(blurredImage, belowSubview: image)
            header.insertSubview(sub, belowSubview: blurredImage)

            self.tableView.tableHeaderView = header

            let views = ["super": self.view, "tableView": self.tableView, "image": image, "blurredImage": blurredImage, "sub": sub]
            let metrics = ["headerHeight": (self.headerHeight - (statusBarHeight + navBarHeight)), "minHeaderHeight": (statusBarHeight + navBarHeight), "subHeaderHeight": self.subHeaderHeight]

            var format = "V:[image(>=minHeaderHeight)]-(subHeaderHeight@750)-|"
            var constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: metrics, views: views)
            self.view.addConstraints(constraint)

            format = "V:[blurredImage(>=minHeaderHeight)]-(subHeaderHeight@750)-|"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: metrics, views: views)
            self.view.addConstraints(constraint)

            format = "V:|-(headerHeight)-[sub(subHeaderHeight)]"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: metrics, views: views)
            self.view.addConstraints(constraint)

            format = "|-0-[image]-0-|"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: metrics, views: views)
            self.view.addConstraints(constraint)

            format = "|-0-[blurredImage]-0-|"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: metrics, views: views)
            self.view.addConstraints(constraint)

            format = "|-0-[sub]-0-|"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: metrics, views: views)
            self.view.addConstraints(constraint)

            var magic = NSLayoutConstraint(item: image, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 0.0)
            self.view.addConstraint(magic)

            magic = NSLayoutConstraint(item: blurredImage, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 0.0)
            self.view.addConstraint(magic)
        }

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 120.0

        self.tableView.allowsMultipleSelection = false

        self.edgesForExtendedLayout = UIRectEdge.Top

        self.automaticallyAdjustsScrollViewInsets = true

        //
        // Register Nibs for reuse
        //
        self.tableView.registerNib(UINib(nibName: "EpisodeCell", bundle: nil), forCellReuseIdentifier: "EpisodeCell")
        self.tableView.registerNib(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
        self.tableView.registerNib(UINib(nibName: "EpisodeSectionHeader", bundle: nil), forHeaderFooterViewReuseIdentifier: "EpisodeSectionHeader")
        self.tableView.registerNib(UINib(nibName: "CommentSectionFooter", bundle: nil), forHeaderFooterViewReuseIdentifier: "CommentSectionFooter")

        //
        // SLKTextViewController setup
        //
        self.bounces = true
        self.shakeToClearEnabled = true
        self.keyboardPanningEnabled = false
        self.inverted = false

        self.leftButton.setImage(UIImage(named: "delete"), forState: UIControlState.Normal)
        self.leftButton.tintColor = UIColor.fablerOrangeColor()
        self.rightButton.setTitle("Send", forState: UIControlState.Normal)
        self.rightButton.tintColor = UIColor.fablerOrangeColor()

        self.textInputbar.autoHideRightButton = true

        self.textView.placeholder = "Add a comment."
        self.textView.placeholderColor = UIColor.lightGrayColor()

        self.textView.registerMarkdownFormattingSymbol("**", withTitle: "Bold")
        self.textView.registerMarkdownFormattingSymbol("_", withTitle: "Italics")
        self.textView.registerMarkdownFormattingSymbol("~~", withTitle: "Strike")

        self.setTextInputbarHidden(true, animated: false)

        //
        // Static element setup
        //
        self.titleLabel?.text = podcast?.title

        self.settingsButton?.addTarget(self, action: "settingsButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)

        self.updateSubscribeButton(nil)
        self.subscribeButton?.addTarget(self, action: "subscribeButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)

        //
        // RefreshControl setup
        //
        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: "refreshData:", forControlEvents: UIControlEvents.ValueChanged)
            refresher.backgroundColor = UIColor.clearColor()
            refresher.tintColor = UIColor.whiteColor()
            self.tableView.addSubview(refresher)
        }
    }
    // swiftlint:enable function_body_length

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        //
        // Setup navigation bar
        //
        self.navigationController?.navigationBar.barStyle = .Black
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = true
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController?.navigationBar.clipsToBounds = true
        self.navigationItem.title = ""

        self.setupImages()

        self.barAnimationComplete = false

        //
        // Refresh data
        //
        self.refreshEpisodeData(self)
        self.refreshCommentData(self)
        self.refreshControl?.beginRefreshing()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.didDismissKeyboard()

        //
        // Reset navigation var
        //
        self.navigationController?.navigationBar.clipsToBounds = false

        if let navigationController = self.navigationController as? FablerNavigationController {
            navigationController.setDefaultNavigationBar()
        }
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidAppear(animated)

        //
        // Reset navigation var
        //
        if let navigationController = self.navigationController as? FablerNavigationController {
            navigationController.setDefaultNavigationBar()
        }
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
            if let controller = segue.destinationViewController as? PodcastSettingsViewController, let podcast = sender as? Podcast {
                controller.podcast = podcast
            }
        } else if segue.identifier == "displayUserSegue" {
            if let controller = segue.destinationViewController as? UserViewController, let user = sender as? User {
                controller.user = user
            }
        }
    }

    // MARK: - UITableViewController functions

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier("EpisodeSectionHeader") as? EpisodeSectionHeaderView {
            view.delegate = self
            view.segmentControl?.selectedSegmentIndex = self.currentSegment
            view.setColors(self.primaryColor, background: self.backgroundColor)

            return view
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

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier("CommentSectionFooter") as? CommentSectionFooterView {
            view.delegate = self
            return view
        }

        return UIView()
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let result: CGFloat

        switch self.currentSegment {
        case 2:
            result = 40.0
        default:
            result = 0.0
        }

        return result
    }

    // MARK: - PodcastTableViewController episode table functions

    func setupTableForEpisodes() {
        self.tableView.allowsSelection = true
    }

    func episodesDidSelectRowAtIndexPath(indexPath: NSIndexPath) {
        let episode = filteredEpisodes[indexPath.row]

        let player = FablerPlayer.sharedInstance
        player.startPlayback(episode)

        performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
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
        var results: [UITableViewRowAction] = []

        let detailAction = UITableViewRowAction(style: .Normal, title: "Details" , handler: { [weak self] (action: UITableViewRowAction, indexPath: NSIndexPath) in
            if let controller = self {
                let episode = controller.filteredEpisodes[indexPath.row]
                controller.performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
            }
        })

        if let color = self.podcast?.backgroundColor {
            if color.isDark {
                detailAction.backgroundColor = color
            } else {
                detailAction.backgroundColor = self.podcast?.primaryColor
            }
        }

        results.append(detailAction)

        let episode = filteredEpisodes[indexPath.row]

        if let download = episode.download where download.state == .Completed {
            let title = episode.saved ? "Unsave" : "Save"

            let saveAction = UITableViewRowAction(style: .Normal, title: title, handler: { [weak self] (action: UITableViewRowAction, indexPath: NSIndexPath) in
                if let controller = self {
                    let episode = controller.filteredEpisodes[indexPath.row]
                    let service = EpisodeService()

                    service.flipSaveForEpisode(episode)
                    controller.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            })

            saveAction.backgroundColor = UIColor.fablerOrangeColor()

            results.append(saveAction)

            let deleteAction = UITableViewRowAction(style: .Destructive, title: "Delete", handler: { [weak self] (action: UITableViewRowAction, indexPath: NSIndexPath) in
                if let controller = self, let download = controller.filteredEpisodes[indexPath.row].download {
                    download.remove()
                    controller.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            })

            results.append(deleteAction)
        }

        return results
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
            cell.collapseDelegate = self
            cell.replyDelegate = self
            cell.segueDelegate = self

            if let collapseIndexPath = self.indexPath, let collapsed = self.collapsed {
                if collapseIndexPath == indexPath {
                    cell.barCollapsed = collapsed
                    self.indexPath = nil
                    self.collapsed = nil
                }
            } else {
                cell.barCollapsed = true
            }

            cell.setCommentInstance(comment)
        }

        return cell
    }

    func commentsEditActions(indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        return nil
    }

    // MARK: - PodcastTableViewController magic functions

    func createSubHeader() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false

        self.titleLabel = UILabel()
        self.titleLabel?.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel?.numberOfLines = 1
        self.titleLabel?.font = UIFont.systemFontOfSize(18.0)
        self.titleLabel?.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        self.titleLabel?.text = "Title"

        self.subscribeButton = UIButton(type: UIButtonType.System)
        self.subscribeButton?.translatesAutoresizingMaskIntoConstraints = false
        self.subscribeButton?.tintColor = UIColor.fablerOrangeColor()
        self.subscribeButton?.setTitle("Subscribe", forState: .Normal)

        self.settingsButton = UIButton(type: UIButtonType.System)
        self.settingsButton?.translatesAutoresizingMaskIntoConstraints = false
        self.settingsButton?.tintColor = UIColor.fablerOrangeColor()
        self.settingsButton?.setTitle("Settings", forState: .Normal)

        if let title = self.titleLabel, let subscribe = self.subscribeButton, let settings = self.settingsButton {
            view.addSubview(title)
            view.addSubview(subscribe)
            view.addSubview(settings)

            let views = ["title": title, "subscribe": subscribe, "settings": settings]

            var format = "V:|-0-[title]-0-|"
            var constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: nil, views: views)
            view.addConstraints(constraint)

            format = "V:|-0-[subscribe]-0-|"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: nil, views: views)
            view.addConstraints(constraint)

            format = "V:|-0-[settings]-0-|"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: nil, views: views)
            view.addConstraints(constraint)

            format = "|-5-[title]"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: nil, views: views)
            view.addConstraints(constraint)

            format = "[subscribe][settings]|"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: nil, views: views)
            view.addConstraints(constraint)

            format = "[title]-(0@900)-[subscribe]"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: nil, views: views)
            view.addConstraints(constraint)

            var widthConstraint = NSLayoutConstraint(item: subscribe, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 90.0)
            view.addConstraint(widthConstraint)

            widthConstraint = NSLayoutConstraint(item: settings, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 70.0)
            self.settingsButtonWidth = widthConstraint
            view.addConstraint(widthConstraint)
        }

        return view
    }

    override func scrollViewDidScroll(scrollView: UIScrollView) {
        super.scrollViewDidScroll(scrollView)

        let y = scrollView.contentOffset.y

        if y > self.headerSwitchOffset && !self.barIsCollapsed {
            self.barAnimationComplete = false
            self.navigationItem.title = self.podcast?.title
            self.barIsCollapsed = true
        } else if y < self.headerSwitchOffset && self.barIsCollapsed {
            self.navigationItem.title = ""
            self.barAnimationComplete = false
            self.barIsCollapsed = false
        }

        if y > (self.headerSwitchOffset) && y <= (self.headerSwitchOffset + 40) {
            let delta = 40 - (y - self.headerSwitchOffset)

            Log.verbose("Delta at \(delta).")

            self.navigationController?.navigationBar.setTitleVerticalPositionAdjustment(delta, forBarMetrics: UIBarMetrics.Default)

            if let image = self.headerImage, let _ = self.blurredHeaderImage?.image {
                let alpha = (1.0 - (1.0 * ((40.0 - delta) / 40.0)))
                image.alpha = alpha
            }
        }

        if !self.barAnimationComplete && y > (self.headerSwitchOffset + 40) {
            self.navigationController?.navigationBar.setTitleVerticalPositionAdjustment(0.0, forBarMetrics: UIBarMetrics.Default)

            if let image = self.headerImage, let _ = self.blurredHeaderImage?.image {
                image.alpha = 0.0
            }

            self.barAnimationComplete = true
        }
    }

    // MARK: - CollapsibleUITableViewCellDelegate functions

    func setCollapseState(cell: UITableViewCell, collapsed: Bool) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            self.indexPath = indexPath
            self.collapsed = collapsed

            self.tableView.beginUpdates()
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }
    }

    // MARK: - RepliesToCommentDelegate functions

    func replyToComment(comment: Comment?) {
        self.replyComment = comment
        self.didRequestKeyboard()
    }

    func showActionSheet(menu: UIAlertController) {
        self.presentViewController(menu, animated: true, completion: nil)
    }

    func editComment(comment: Comment) {
        self.didRequestKeyboard()
        self.textView.text = comment.comment
        self.replyComment = comment
        self.editingComment = true
    }

    // MARK: - ChangesBasedOnSegment functions

    func segmentDidChangeTo(index: Int) {
        let refresh: Bool = (index != self.currentSegment)

        self.currentSegment = index

        if refresh {
            self.didDismissKeyboard()
            self.refreshData(self)
            self.refreshControl?.beginRefreshing()

            self.tableView.reloadData()
        }
    }

    // MARK: - PerformsUserSegue functions

    func performSegueTo(user: User) {
        performSegueWithIdentifier("displayUserSegue", sender: user)
    }
}
