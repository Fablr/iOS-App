//
//  EpisodeTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import SlackTextViewController
import RxSwift
import RxCocoa
import ChameleonFramework

class EpisodeTableViewController: SLKTextViewController, CollapsibleUITableViewCellDelegate, RepliesToCommentDelegate, PerformsUserSegueDelegate {

    // MARK: - EpisodeTableViewController properties

    var episode: Episode?
    var comments: [Comment] = []

    var refreshControl: UIRefreshControl?
    var headerController: EpisodeHeaderViewController?

    var root: Bool = false

    var bag: DisposeBag! = DisposeBag()

    // MARK: - CollapsibleUITableViewCellDelegate properties

    var indexPath: NSIndexPath?
    var collapsed: Bool?

    // MARK: - RepliesToCommentDelegate properties

    var replyComment: Comment?
    var editingComment: Bool = false

    // MARK: - EpisodeTableViewController methods

    func refreshData(sender: AnyObject) {
        guard let episode = self.episode else {
            return
        }

        let service = CommentService()

        service.getCommentsForEpisode(episode, completion: { [weak self] (comments) in
            self?.comments = comments
            self?.tableView.reloadData()

            if let refresher = self?.refreshControl where refresher.refreshing {
                refresher.endRefreshing()
            }
        })
    }

    func commentButtonPressed(sender: AnyObject) {
        self.replyComment = nil
        self.didRequestKeyboard()
    }

    @objc func doneButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
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
        guard let message = self.textView.text.copy() as? String, let episode = self.episode else {
            super.didPressRightButton(sender)
            self.didDismissKeyboard()

            return
        }

        let service = CommentService()

        if !self.editingComment {
            let id = self.replyComment?.commentId

            service.addCommentForEpisode(episode, comment: message, parentCommentId: id, completion: { [weak self] (result) in
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

        super.didPressRightButton(sender)
        self.didDismissKeyboard()
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        guard self.episode != nil else {
            Log.error("expected a episode initiated via previous controller")
            return
        }

        super.viewDidLoad()

        //
        // Register Nibs for reuse
        //
        self.tableView.registerNib(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
        self.tableView.registerNib(UINib(nibName: "CommentSectionFooter", bundle: nil), forHeaderFooterViewReuseIdentifier: "CommentSectionFooter")

        //
        // TableView setup
        //
        self.headerController = EpisodeHeaderViewController(nibName: "EpisodeHeader", bundle: nil)
        self.tableView.tableHeaderView = self.headerController?.view

        if let header = self.headerController {
            var frame = header.view.frame
            frame.size = CGSize(width: header.view.frame.size.width, height: 70.0)
            header.view.frame = frame
        }

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 120.0

        self.tableView.allowsSelection = false
        self.tableView.allowsMultipleSelection = false

        self.edgesForExtendedLayout = .None

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
        self.navigationItem.title = episode!.title
        self.headerController?.descriptionLabel?.text = episode!.episodeDescription

        //
        // RefreshControl setup
        //
        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: #selector(EpisodeTableViewController.refreshData), forControlEvents: .ValueChanged)
            refresher.backgroundColor = .fablerOrangeColor()
            refresher.tintColor = .whiteColor()
            self.tableView.addSubview(refresher)
        }

        //
        // Dynamic change colors
        //
        self.episode?.podcast?
        .rx_observeWeakly(Bool.self, "primarySet")
        .subscribeNext({ [weak self] (set) in
            if let primary = self?.episode?.podcast?.primaryColor {
                self?.refreshControl?.backgroundColor = primary
                self?.leftButton.tintColor = primary
                self?.rightButton.tintColor = primary

                self?.navigationController?.navigationBar.barTintColor = primary
                self?.navigationController?.navigationBar.translucent = false
                self?.navigationController?.navigationBar.tintColor = UIColor(contrastingBlackOrWhiteColorOn: primary, isFlat: true)
                self?.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(contrastingBlackOrWhiteColorOn: primary, isFlat: true)]
                self?.setStatusBarStyle(UIStatusBarStyleContrast)

                self?.tableView.reloadData()
            }
        })
        .addDisposableTo(self.bag)

        //
        // Show dismiss button if we are the root of a navigation controller
        //
        if self.root {
            let done = UIBarButtonItem(title: "Done", style: .Done, target: self, action: #selector(EpisodeTableViewController.doneButtonPressed))
            self.navigationItem.leftBarButtonItem = done
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        //
        // Refresh data
        //
        self.refreshData(self)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.didDismissKeyboard()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayUserSegue" {
            if let controller = segue.destinationViewController as? UserViewController, let user = sender as? User {
                controller.user = user
            }
        }
    }

    deinit {
        self.bag = nil
    }

    // MARK: - UITableView methods

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None

        if self.comments.count > 0 {
            self.tableView.backgroundView = nil
        } else {
            //
            // Display empty view message but, still display section header
            //
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            let button = UIButton(type: .System)

            button.frame = frame
            button.setTitle("Be the first to comment!", forState: .Normal)
            button.addTarget(self, action: #selector(EpisodeTableViewController.didRequestKeyboard), forControlEvents: .TouchUpInside)
            if let primary = self.episode?.podcast?.primaryColor {
                button.tintColor = primary
            } else {
                button.tintColor = .fablerOrangeColor()
            }

            self.tableView?.backgroundView = button
            self.tableView?.separatorStyle = .None
        }

        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier("CommentSectionFooter") as? CommentSectionFooterView {
            view.delegate = self

            if let primary = self.episode?.podcast?.primaryColor {
                view.commentButton?.tintColor = primary
            }

            return view
        }

        return UIView()
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40.0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        Log.verbose("Building cell.")

        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath)

        if let cell = cell as? CommentTableViewCell {
            cell.replyDelegate = self
            cell.collapseDelegate = self
            cell.segueDelegate = self

            if let primary = self.episode?.podcast?.primaryColor {
                cell.tint = primary
            }

            if let collapseIndexPath = self.indexPath, let collapsed = self.collapsed {
                if collapseIndexPath.row == indexPath.row {
                    cell.barCollapsed = collapsed

                    Log.verbose("Resetting indexPath.")
                    self.indexPath = nil
                    self.collapsed = nil
                }
            } else {
                cell.barCollapsed = true
            }

            cell.setCommentInstance(comments[indexPath.row])
        }

        return cell
    }

    // MARK: - CollapsibleUITableViewCellDelegate methods

    func setCollapseState(cell: UITableViewCell, collapsed: Bool) {
        if let indexPath = self.tableView.indexPathForCell(cell) {
            Log.verbose("Setting index path to \(indexPath).")

            self.indexPath = indexPath
            self.collapsed = collapsed

            self.tableView.beginUpdates()
            self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
            self.tableView.endUpdates()
        }
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

    // MARK: - PerformsUserSegue methods

    func performSegueToUser(user: User) {
        performSegueWithIdentifier("displayUserSegue", sender: user)
    }
}
