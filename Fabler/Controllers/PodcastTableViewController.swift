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
import ChameleonFramework
import RxSwift
import RxCocoa

class PodcastTableViewController: SLKTextViewController, CollapsibleUITableViewCellDelegate, RepliesToCommentDelegate, ChangesBasedOnSegment, PerformsUserSegueDelegate, PresentAlertControllerDelegate, PerformsEpisodeSegueDelegate {

    // MARK: - PodcastTableViewController data members

    var podcast: Podcast?
    var episodes: [Episode] = []
    var filteredEpisodes: [Episode] = []
    var comments: [Comment] = []
    var bag: DisposeBag! = DisposeBag()

    // MARK: - PodcastTableViewController ui members

    var refreshControl: UIRefreshControl?
    var headerImage: UIImageView?

    // MARK: - PodcastTableViewController magic members

    let headerHeight: CGFloat = 160.0

    // MARK: - CollapsibleUITableViewCellDelegate members

    var indexPath: NSIndexPath?
    var collapsed: Bool?

    // MARK: - RepliesToCommentDelegate members

    var replyComment: Comment?
    var editingComment: Bool = false

    // MARK: - ChangesBasedOnSegment members

    var currentSegment: Int = 0

    // MARK: - PodcastTableViewController functions

    func setColorFor(podcast: Podcast, image: UIImage) {
        let service = PodcastService()

        let average = UIColor(averageColorFromImage: image).flatten()

        var potentials: [UIColor] = []
        potentials.append(average)

        let colors = image.colors()
        potentials.append(colors.background.flatten())
        potentials.append(colors.primary.flatten())
        potentials.append(colors.secondary.flatten())
        potentials.append(colors.detail.flatten())

        var colorSet: Bool = false

        for color in potentials {
            if color.isContrastingWith(.whiteColor()) {
                service.setPrimaryColorForPodcast(podcast, color: color)
                colorSet = true
                break
            }
        }

        if !colorSet {
            service.setPrimaryColorForPodcast(podcast, color: average)
        }
    }

    func setupImages() {
        if let podcast = self.podcast, let url = NSURL(string: podcast.image) {
            let manager = KingfisherManager.sharedManager
            let cache = manager.cache

            let id = podcast.podcastId

            if let image = cache.retrieveImageInDiskCacheForKey(url.absoluteString) {
                if !podcast.primarySet {
                    self.setColorFor(podcast, image: image)
                }

                self.updateImages(image)
            } else {
                manager.retrieveImageWithURL(url, optionsInfo: [.CallbackDispatchQueue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))], progressBlock: nil, completionHandler: { [weak self] (image, error, cacheType, url) in
                    if error == nil, let image = image {
                        let service = PodcastService()

                        if let podcast = service.readPodcastFor(id, completion: nil), let controller = self {
                            if !podcast.primarySet {
                                controller.setColorFor(podcast, image: image)
                            }
                        }

                        dispatch_async(dispatch_get_main_queue(), { [weak self] in
                            Log.debug("Setting header image.")

                            if let controller = self {
                                controller.updateImages(image)
                            }
                        })
                    }
                })
            }
        }
    }

    func updateImages(image: UIImage) {
        self.headerImage?.image = image

        if let podcast = self.podcast, let primary = podcast.primaryColor {
            //
            // Setup navigation bar
            //
            self.navigationController?.navigationBar.barTintColor = primary
            self.navigationController?.navigationBar.translucent = false
            self.navigationController?.navigationBar.tintColor = UIColor(contrastingBlackOrWhiteColorOn: primary, isFlat: true)
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(contrastingBlackOrWhiteColorOn: primary, isFlat: true)]
            self.navigationController?.navigationBar.clipsToBounds = false
            self.setStatusBarStyle(UIStatusBarStyleContrast)

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

    func subscribeButtonPressed() {
        if let podcast = self.podcast {
            let service = PodcastService()
            let subscribed = !(podcast.subscribed)

            service.subscribeToPodcast(podcast, subscribe: subscribed, completion: nil)
        }
    }

    func commentButtonPressed(sender: AnyObject) {
        self.replyComment = nil
        self.didRequestKeyboard()
    }

    func settingsButtonPressed() {
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
        return UITableViewStyle.Plain
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

    deinit {
        self.bag = nil
    }

    // swiftlint:disable function_body_length
    override func viewDidLoad() {
        guard self.podcast != nil else {
            Log.error("expected a podcast initiated via previous controller")
            return
        }

        super.viewDidLoad()

        self.navigationItem.title = self.podcast?.title

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

        self.headerImage = UIImageView()
        self.headerImage?.backgroundColor = UIColor.fablerOrangeColor()
        self.headerImage?.translatesAutoresizingMaskIntoConstraints = false
        self.headerImage?.contentMode = .ScaleAspectFill
        self.headerImage?.clipsToBounds = true

        let header = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.headerHeight - (statusBarHeight + navBarHeight)))

        if let image = self.headerImage {
            header.addSubview(image)

            self.tableView.tableHeaderView = header

            let views = ["super": self.view, "tableView": self.tableView, "image": image]

            var format = "V:[image]-(0@750)-|"
            var constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: nil, views: views)
            self.view.addConstraints(constraint)

            format = "|-0-[image]-0-|"
            constraint = NSLayoutConstraint.constraintsWithVisualFormat(format, options: .DirectionLeadingToTrailing, metrics: nil, views: views)
            self.view.addConstraints(constraint)

            let magic = NSLayoutConstraint(item: image, attribute: .Top, relatedBy: .Equal, toItem: self.view, attribute: .Top, multiplier: 1.0, constant: 0.0)
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
        self.rightButton.setTitle("Post", forState: UIControlState.Normal)
        self.rightButton.tintColor = UIColor.fablerOrangeColor()

        self.podcast?
        .rx_observe(Bool.self, "primarySet")
        .subscribeNext({ [weak self] (set) in
            if let primary = self?.podcast?.primaryColor {
                self?.leftButton.tintColor = primary
                self?.rightButton.tintColor = primary
            }
        })
        .addDisposableTo(self.bag)

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
        self.podcast?
        .rx_observe(Bool.self, "subscribed")
        .subscribeNext({ subscribed in
            if let subscribed = subscribed {
                if subscribed {
                    let button = UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.Plain, target: self, action: "settingsButtonPressed")
                    self.navigationItem.rightBarButtonItem = button
                } else {
                    let button = UIBarButtonItem(title: "Subscribe", style: UIBarButtonItemStyle.Plain, target: self, action: "subscribeButtonPressed")
                    self.navigationItem.rightBarButtonItem = button
                }
            }

        })
        .addDisposableTo(self.bag)

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

        self.setupImages()

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
            view.setColors(self.podcast?.primaryColor)

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

            if let primary = self.podcast?.primaryColor {
                view.commentButton?.tintColor = primary
            }

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

            let text: String

            if self.currentSegment == 0 {
                text = "No episodes downloaded for this podcast."
            } else {
                text = "No episodes avaliable for this podcast."
            }

            label.text = text
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

            cell.presentDelegate = self
            cell.segueDelegate = self
        }

        return cell
    }

    func episodesEditActions(indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var results: [UITableViewRowAction] = []

        let detailAction = UITableViewRowAction(style: .Normal, title: "Details", handler: { [weak self] (action: UITableViewRowAction, indexPath: NSIndexPath) in
            if let controller = self {
                let episode = controller.filteredEpisodes[indexPath.row]
                controller.performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
            }
        })

        if let primary = self.podcast?.primaryColor {
            detailAction.backgroundColor = primary
        } else {
            detailAction.backgroundColor = .fablerOrangeColor()
        }

        results.append(detailAction)

        let episode = filteredEpisodes[indexPath.row]

        if let download = episode.download where download.state == .Completed {
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

            let button = UIButton(type: .System)
            button.frame = frame
            button.setTitle("Be the first to comment!", forState: .Normal)
            button.tintColor = .fablerOrangeColor()
            button.addTarget(self, action: "didRequestKeyboard", forControlEvents: .TouchUpInside)

            self.podcast?
            .rx_observe(Bool.self, "primarySet")
            .subscribeNext({ [weak self] (set) in
                if let primary = self?.podcast?.primaryColor {
                    button.tintColor = primary
                }
            })
            .addDisposableTo(self.bag)

            self.tableView?.backgroundView = button
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

            if let primary = self.podcast?.primaryColor {
                cell.tint = primary
            }

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

    func performSegueToUser(user: User) {
        performSegueWithIdentifier("displayUserSegue", sender: user)
    }

    // MARK: - PresentAlertController functions

    func presentAlert(controller: UIAlertController) {
        self.presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - PerformsEpisodeSegue functions

    func performSegueToEpisode(episode: Episode) {
        performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
    }
}
