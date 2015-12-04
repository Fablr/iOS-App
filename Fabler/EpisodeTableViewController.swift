//
//  EpisodeViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class EpisodeTableViewController: UITableViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?

    // MARK: - EpisodeTableViewController members

    var episode: Episode?
    var comments: [Comment]?

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

    func rootReplyButtonPressed(sender: AnyObject) {
        if let episode = self.episode {
            let service = CommentService()
            service.addCommentForEpisode(episode.episodeId, comment: "This is a test.", parentCommentId: nil, completion: { [weak self] (result) in
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

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        guard self.episode != nil else {
            print("expected a episode initiated via previous controller")
            return
        }

        super.viewDidLoad()

        self.navigationItem.title = episode!.title

        self.titleLabel?.text = episode!.title
        self.subtitleLabel?.text = episode!.subtitle
        self.descriptionLabel?.text = episode!.episodeDescription

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
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.orangeColor()

        self.refreshData(self)
        self.refreshControl?.beginRefreshing()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UITableViewDataSource functions

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count: Int = 0

        if let comments = self.comments {
            if comments.count > 0 {
                count = 1
                self.tableView.backgroundView = nil
                self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
            }
        }

        if count == 0 {
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            let label = UILabel(frame: frame)

            label.text = "No comments for this episode."
            label.textAlignment = NSTextAlignment.Center

            self.tableView?.backgroundView = label
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        }

        return count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard self.comments != nil else {
            return 0
        }

        return self.comments!.count
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let cell = tableView.dequeueReusableCellWithIdentifier("HeaderCell") as? CommentHeaderTableViewCell {
            cell.replyButton?.addTarget(self, action: "rootReplyButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            return cell.contentView
        }

        return UIView()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RowCell", forIndexPath: indexPath)

        if let cell = cell as? CommentTableViewCell, let comment = comments?[indexPath.row] {
            cell.bodyLabel?.text = comment.comment
            cell.subLabel?.text = "by \(comment.userName) on \(comment.submitDate)"

            if comment.parentId != nil {
                let constraints = cell.contentView.constraints

                for constraint in constraints {
                    if constraint.identifier == "CommentIndent" {
                        constraint.constant += 40
                    }
                }

                cell.backgroundColor = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
            }
        }

        return cell
    }
}
