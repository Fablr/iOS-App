//
//  EpisodeViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import SlackTextViewController

class EpisodeTableViewController: SLKTextViewController {

    // MARK: - EpisodeTableViewController members

    var episode: Episode?
    var comments: [Comment] = []

    var refreshControl: UIRefreshControl?
    var headerController: EpisodeHeaderViewController?

    // MARK: - EpisodeTableViewController functions

    func refreshData(sender: AnyObject) {
        if let episode = self.episode {
            let service = CommentService()

            service.getCommentsForEpisode(episode.episodeId, completion: { [weak self] (comments) in
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
        if let episode = self.episode {
            let service = CommentService()
            service.addCommentForEpisode(episode.episodeId, comment: message, parentCommentId: parent, completion: { [weak self] (result) in
                if let controller = self {
                    if result {
                        controller.refreshData(controller)
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

    func commentButtonPressed(sender: AnyObject) {
        self.setTextInputbarHidden(false, animated: true)
        self.textView.becomeFirstResponder()
    }

    func userTapped(sender: AnyObject) {
        self.setTextInputbarHidden(true, animated: true)
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
        guard self.episode != nil else {
            print("expected a episode initiated via previous controller")
            return
        }

        super.viewDidLoad()

        //
        // Register Nibs for reuse
        //
        self.tableView.registerNib(UINib(nibName: "CommentCell", bundle: nil), forCellReuseIdentifier: "CommentCell")
        self.tableView.registerNib(UINib(nibName: "CommentHeaderCell", bundle: nil), forCellReuseIdentifier: "CommentHeaderCell")

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
        self.tableView.estimatedRowHeight = 50.0

        self.tableView.allowsSelection = false
        self.tableView.allowsMultipleSelection = false

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
        // Static labels setup
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
            refresher.backgroundColor = UIColor.orangeColor()
            refresher.tintColor = UIColor.whiteColor()
            self.tableView.addSubview(refresher)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        // Create global style class and move this in there
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.orangeColor()

        //
        // Refresh data
        //
        self.refreshData(self)
        self.refreshControl?.beginRefreshing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UITableViewDataSource functions

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

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let cell = tableView.dequeueReusableCellWithIdentifier("CommentHeaderCell") as? CommentHeaderTableViewCell {
            cell.commentButton?.addTarget(self, action: "commentButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            return cell.contentView
        }

        return UIView()
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CommentCell", forIndexPath: indexPath)

        if let cell = cell as? CommentTableViewCell {
            cell.setComment(comments[indexPath.row])
        }

        return cell
    }
}
