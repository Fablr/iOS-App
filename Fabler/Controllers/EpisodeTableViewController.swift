//
//  EpisodeTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import SlackTextViewController

class EpisodeTableViewController: SLKTextViewController, CollapsibleUITableViewCellDelegate, RepliesToCommentDelegate, PerformsUserSegueDelegate {

    // MARK: - EpisodeTableViewController members

    var episode: Episode?
    var comments: [Comment] = []

    var refreshControl: UIRefreshControl?
    var headerController: EpisodeHeaderViewController?

    // MARK: - CollapsibleUITableViewCellDelegate members

    var indexPath: NSIndexPath?
    var collapsed: Bool?

    // MARK: - RepliesToCommentDelegate members

    var replyComment: Comment?
    var editingComment: Bool = false

    // MARK: - EpisodeTableViewController functions

    func refreshData(sender: AnyObject) {
        if let episode = self.episode {
            let service = CommentService()

            service.getCommentsForEpisode(episode, completion: { [weak self] (comments) in
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

    func addMessage(message: String, parent: Int?) {

    }

    func commentButtonPressed(sender: AnyObject) {
        self.replyComment = nil
        self.didRequestKeyboard()
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
        if let message = self.textView.text.copy() as? String, let episode = self.episode {
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
        }

        super.didPressRightButton(sender)
        self.didDismissKeyboard()
    }

    // MARK: - UIViewController functions

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
            frame.size = CGSizeMake(header.view.frame.size.width, 70.0)
            header.view.frame = frame
        }

        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 120.0

        self.tableView.allowsSelection = false
        self.tableView.allowsMultipleSelection = false

        self.edgesForExtendedLayout = UIRectEdge.None

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
        self.navigationItem.title = episode!.title
        self.headerController?.descriptionLabel?.text = episode!.episodeDescription

        //
        // RefreshControl setup
        //
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

        //
        // Refresh data
        //
        self.refreshData(self)
        self.refreshControl?.beginRefreshing()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        self.didDismissKeyboard()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayUserSegue" {
            if let controller = segue.destinationViewController as? UserTableViewController, let user = sender as? User {
                controller.user = user
            }
        }
    }

    // MARK: - UITableView functions

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.comments.count > 0 {
            self.tableView.backgroundView = nil
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        } else {
            //
            // Display empty view message but, still display section header
            //
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            let label = UILabel(frame: frame)

            label.text = "No comments for this episode."
            label.textAlignment = NSTextAlignment.Center

            self.tableView?.backgroundView = label
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        }

        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.comments.count
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier("CommentSectionFooter") as? CommentSectionFooterView {
            view.delegate = self
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

    // MARK: - CollapsibleUITableViewCellDelegate functions

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

    // MARK: - PerformsUserSegue functions

    func performSegueTo(user: User) {
        performSegueWithIdentifier("displayUserSegue", sender: user)
    }
}
