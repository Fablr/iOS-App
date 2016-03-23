//
//  PodcastTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import SlackTextViewController
import ChameleonFramework
import RxSwift
import RxCocoa
import SwiftDate

class PodcastTableViewController: SLKTextViewController, CollapsibleUITableViewCellDelegate, RepliesToCommentDelegate, ChangesBasedOnSegment, PerformsUserSegueDelegate, PresentAlertControllerDelegate, PerformsEpisodeSegueDelegate {

    // MARK: - PodcastTableViewController properties

    var podcast: Podcast?
    var episodes: [Episode] = []
    var filteredEpisodes: [Episode] = []
    var comments: [Comment] = []

    var bag: DisposeBag! = DisposeBag()
    var refreshControl: UIRefreshControl?
    var headerImage: UIImageView?

    let headerHeight: CGFloat = 160.0

    // MARK: - CollapsibleUITableViewCellDelegate properties

    var indexPath: NSIndexPath?
    var collapsed: Bool?

    // MARK: - RepliesToCommentDelegate properties

    var replyComment: Comment?
    var editingComment: Bool = false

    // MARK: - ChangesBasedOnSegment properties

    var currentSegment: Int = 0

    // MARK: - PodcastTableViewController methods

    func updateImages() {
        guard let podcast = self.podcast else {
            return
        }

        podcast.image { [weak self] (image) in
            self?.headerImage?.image = image

            guard let primary = self?.podcast?.primaryColor else {
                return
            }

            self?.navigationController?.navigationBar.barTintColor = primary
            self?.navigationController?.navigationBar.translucent = false
            self?.navigationController?.navigationBar.tintColor = UIColor(contrastingBlackOrWhiteColorOn: primary, isFlat: true)
            self?.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(contrastingBlackOrWhiteColorOn: primary, isFlat: true)]
            self?.navigationController?.navigationBar.clipsToBounds = false
            self?.setStatusBarStyle(UIStatusBarStyleContrast)
        }
    }

    func filterEpisodes() {
        switch self.currentSegment {
        case 0:
            self.filteredEpisodes = self.episodes.filter { $0.download != nil }
        case 1:
            self.filteredEpisodes = self.episodes
        default:
            break
        }

        self.sortEpisodes()
    }

    func sortEpisodes() {
        guard let order = self.podcast?.sortOrder else {
            return
        }

        switch order {
        case .NewestOldest:
            self.filteredEpisodes.sortInPlace { $0.pubdate > $1.pubdate }
        case .OldestNewest:
            self.filteredEpisodes.sortInPlace { $1.pubdate > $0.pubdate }
        }
    }

    func refreshData(sender: AnyObject?) {
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

    func refreshEpisodeData(sender: AnyObject?) {
        guard let podcast = self.podcast else {
            return
        }

        let service = EpisodeService()
        self.episodes = service.getEpisodesForPodcast(podcast) { [weak self] (episodes) in
            self?.episodes = episodes
            self?.filterEpisodes()
            self?.tableView?.reloadData()

            if let refresher = self?.refreshControl where refresher.refreshing {
                refresher.endRefreshing()
            }
        }

        self.filterEpisodes()
    }

    func refreshCommentData(sender: AnyObject?) {
        guard let podcast = self.podcast else {
            return
        }

        let service = CommentService()

        service.getCommentsForPodcast(podcast) { [weak self] (comments) in
            self?.comments = comments
            self?.tableView.reloadData()

            if let refresher = self?.refreshControl where refresher.refreshing {
                refresher.endRefreshing()
            }
        }
    }

    func subscribeButtonPressed() {
        guard let podcast = self.podcast else {
            return
        }

        let service = PodcastService()
        let subscribed = !(podcast.subscribed)

        service.subscribeToPodcast(podcast, subscribe: subscribed, completion: nil)
    }

    func commentButtonPressed(sender: AnyObject) {
        self.replyComment = nil
        self.didRequestKeyboard()
    }

    func settingsButtonPressed() {
        performSegueWithIdentifier("displaySettingsSegue", sender: self.podcast)
    }

    // MARK: - SLKTextViewController methods

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
        return .Plain
    }

    override func didPressLeftButton(sender: AnyObject!) {
        self.didDismissKeyboard()
    }

    override func didPressRightButton(sender: AnyObject!) {
        guard let message = self.textView.text.copy() as? String, let podcast = self.podcast else {
            super.didPressRightButton(sender)
            self.didDismissKeyboard()

            return
        }

        let service = CommentService()

        if !self.editingComment {
            let id = self.replyComment?.commentId

            service.addCommentForPodcast(podcast, comment: message, parentCommentId: id) { [weak self] (result) in
                if result {
                    self?.refreshData(nil)
                }
            }
        } else {
            if let comment = self.replyComment {
                let service = CommentService()

                service.editComment(comment, newComment: message) { [weak self] result in
                        if result {
                            self?.refreshData(nil)
                        }
                }
            }
        }

        super.didPressRightButton(sender)
        self.didDismissKeyboard()
    }

    // MARK: - UIViewController methods

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
        self.headerImage?.backgroundColor = .fablerOrangeColor()
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

        self.leftButton.setImage(UIImage(named: "delete"), forState: .Normal)
        self.leftButton.tintColor = .fablerOrangeColor()
        self.rightButton.setTitle("Post", forState: .Normal)
        self.rightButton.tintColor = .fablerOrangeColor()

        self.podcast?
        .rx_observeWeakly(Bool.self, "primarySet")
        .subscribeNext { [weak self] (set) in
            if let primary = self?.podcast?.primaryColor {
                self?.leftButton.tintColor = primary
                self?.rightButton.tintColor = primary
            }
        }
        .addDisposableTo(self.bag)

        self.textInputbar.autoHideRightButton = true

        self.textView.placeholder = "Add a comment."
        self.textView.placeholderColor = .lightGrayColor()

        self.textView.registerMarkdownFormattingSymbol("**", withTitle: "Bold")
        self.textView.registerMarkdownFormattingSymbol("_", withTitle: "Italics")
        self.textView.registerMarkdownFormattingSymbol("~~", withTitle: "Strike")

        self.setTextInputbarHidden(true, animated: false)

        //
        // Static element setup
        //
        self.podcast?
        .rx_observeWeakly(Bool.self, "subscribed")
        .subscribeNext { subscribed in
            if let subscribed = subscribed {
                if subscribed {
                    let button = UIBarButtonItem(title: "Settings", style: .Plain, target: self, action: #selector(PodcastTableViewController.settingsButtonPressed))
                    self.navigationItem.rightBarButtonItem = button
                } else {
                    let button = UIBarButtonItem(title: "Subscribe", style: .Plain, target: self, action: #selector(PodcastTableViewController.subscribeButtonPressed))
                    self.navigationItem.rightBarButtonItem = button
                }
            }

        }
        .addDisposableTo(self.bag)

        self.podcast?
        .rx_observeWeakly(String.self, "sortOrderRaw")
        .subscribeNext { [weak self] (_) in
            self?.sortEpisodes()
            self?.tableView.reloadData()
        }
        .addDisposableTo(self.bag)

        //
        // RefreshControl setup
        //
        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: #selector(PodcastTableViewController.refreshData), forControlEvents: UIControlEvents.ValueChanged)
            refresher.backgroundColor = .clearColor()
            refresher.tintColor = .whiteColor()
            self.tableView.addSubview(refresher)
        }
    }
    // swiftlint:enable function_body_length

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.updateImages()

        //
        // Refresh data
        //
        self.refreshEpisodeData(self)
        self.refreshCommentData(self)
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

    // MARK: - UITableViewController methods

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

    // MARK: - PodcastTableViewController episode table methods

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
            self.tableView?.separatorStyle = .None
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
            self.tableView?.separatorStyle = .None
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

        let detailAction = UITableViewRowAction(style: .Normal, title: "Details") { [weak self] (action: UITableViewRowAction, indexPath: NSIndexPath) in
            if let controller = self {
                let episode = controller.filteredEpisodes[indexPath.row]
                controller.performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
            }
        }

        if let primary = self.podcast?.primaryColor {
            detailAction.backgroundColor = primary
        } else {
            detailAction.backgroundColor = .fablerOrangeColor()
        }

        results.append(detailAction)

        let episode = filteredEpisodes[indexPath.row]

        if let download = episode.download where download.state == .Completed {
            let deleteAction = UITableViewRowAction(style: .Destructive, title: "Delete") { [weak self] (action: UITableViewRowAction, indexPath: NSIndexPath) in
                if let controller = self, let download = controller.filteredEpisodes[indexPath.row].download {
                    download.remove()
                    controller.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                }
            }

            results.append(deleteAction)
        }

        return results
    }

    // MARK: - PodcastTableViewController comment table methods

    func setupTableForComments() {
        self.tableView.allowsSelection = false
    }

    func commentsDidSelectRowAtIndexPath(indexPath: NSIndexPath) {
        return
    }

    func commentsNumberOfSectionsInTableView() -> Int {
        if self.comments.count > 0 {
            self.tableView.backgroundView = nil
            self.tableView?.separatorStyle = .None
        } else {
            //
            // Display empty view message but, still display section header
            //
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)

            let button = UIButton(type: .System)
            button.frame = frame
            button.setTitle("Be the first to comment!", forState: .Normal)
            button.addTarget(self, action: #selector(PodcastTableViewController.didRequestKeyboard), forControlEvents: .TouchUpInside)
            if let primary = self.podcast?.primaryColor {
                button.tintColor = primary
            } else {
                button.tintColor = .fablerOrangeColor()
            }

            self.tableView?.backgroundView = button
            self.tableView?.separatorStyle = .None
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

    // MARK: - CollapsibleUITableViewCellDelegate methods

    func setCollapseState(cell: UITableViewCell, collapsed: Bool) {
        guard let indexPath = self.tableView.indexPathForCell(cell) else {
            return
        }

        self.indexPath = indexPath
        self.collapsed = collapsed

        self.tableView.beginUpdates()
        self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
        self.tableView.endUpdates()
    }

    // MARK: - RepliesToCommentDelegate methods

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

    // MARK: - ChangesBasedOnSegment methods

    func segmentDidChangeTo(index: Int) {
        let refresh: Bool = (index != self.currentSegment)

        self.currentSegment = index

        if refresh {
            self.didDismissKeyboard()
            self.refreshData(self)

            self.tableView.reloadData()
        }
    }

    // MARK: - PerformsUserSegue methods

    func performSegueToUser(user: User) {
        performSegueWithIdentifier("displayUserSegue", sender: user)
    }

    // MARK: - PresentAlertController methods

    func presentAlert(controller: UIAlertController) {
        self.presentViewController(controller, animated: true, completion: nil)
    }

    // MARK: - PerformsEpisodeSegue methods

    func performSegueToEpisode(episode: Episode) {
        performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
    }
}
