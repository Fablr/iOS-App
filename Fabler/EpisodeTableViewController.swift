//
//  EpisodeViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Keyboardy

class EpisodeTableViewController: UITableViewController, KeyboardStateDelegate, UITextFieldDelegate {

    // MARK: - IBOutlets

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subtitleLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?

    // MARK: - EpisodeTableViewController members

    var episode: Episode?
    var comments: [Comment] = []

    var showTextField: Bool = false
    var currentTextField: UITextField?

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

    func rootReplyButtonPressed(sender: AnyObject) {
        self.displayKeyboard(self)
    }

    func displayKeyboard(sender: AnyObject) {
        guard self.showTextField == false else {
            return
        }

        self.showTextField = true
        self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)

        self.currentTextField?.text = ""
        self.currentTextField?.becomeFirstResponder()

        self.tableView.bounces = false
    }

    func dismissKeyboard(sender: AnyObject) {
        if self.showTextField, let textField = self.currentTextField {
            textField.resignFirstResponder()

            textField.text = ""

            self.showTextField = false
            self.tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Fade)

            self.tableView.bounces = true
        }
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        guard self.episode != nil else {
            print("expected a episode initiated via previous controller")
            return
        }

        super.viewDidLoad()

        //
        // Static labels setup
        //
        self.navigationItem.title = episode!.title
        self.titleLabel?.text = episode!.title
        self.subtitleLabel?.text = episode!.subtitle
        self.descriptionLabel?.text = episode!.episodeDescription

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

        //
        // Dismiss Gesture Recognizer setup
        //
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard:")
        view.addGestureRecognizer(tap)
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

        //
        // Setup Keyboard
        //
        registerForKeyboardNotifications(self)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        unregisterFromKeyboardNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UITableViewDataSource functions

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        var count: Int = 0

        if self.comments.count > 0 {
            count = 1
            self.tableView.backgroundView = nil
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
        }

        //
        // Display empty view message
        //
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
        return self.comments.count
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let cell = tableView.dequeueReusableCellWithIdentifier("HeaderCell") as? CommentHeaderTableViewCell {
            cell.replyButton?.addTarget(self, action: "rootReplyButtonPressed:", forControlEvents: UIControlEvents.TouchUpInside)
            return cell.contentView
        }

        return UIView()
    }

    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.showTextField, let cell = tableView.dequeueReusableCellWithIdentifier("TextFieldCell") as? TextFieldTableViewCell {
            self.currentTextField = cell.textField
            return cell.contentView
        }

        self.currentTextField = nil
        return nil
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let height: CGFloat

        //
        // Only show footers if keyboard is showing.
        //
        if self.showTextField {
            height = 40.0
        } else {
            height = 0.0
        }

        return height
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RowCell", forIndexPath: indexPath)

        if let cell = cell as? CommentTableViewCell {
            let comment = comments[indexPath.row]

            let localTimeZone = NSTimeZone.localTimeZone()
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeZone = localTimeZone
            dateFormatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
            let date = dateFormatter.stringFromDate(comment.submitDate)

            cell.bodyLabel?.text = comment.comment
            cell.subLabel?.text = "by \(comment.userName) on \(date)"

            comment.parentId == nil ? cell.styleCellAsParent() : cell.styleCellAsChild()
        }

        return cell
    }

    // MARK: - KeyboardStateDelegate functions

    func keyboardWillTransition(state: KeyboardState) {
    }

    func keyboardTransitionAnimation(state: KeyboardState) {
        //
        // Minimize the toolbar for soft-keyboard
        //
        switch state {
        case .ActiveWithHeight(_):
            self.navigationController?.setToolbarHidden(true, animated: false)
        case .Hidden:
            self.navigationController?.setToolbarHidden(false, animated: false)
            break
        }
    }

    func keyboardDidTransition(state: KeyboardState) {
    }

    // MARK: - UITextFieldDelegate functions

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let message = textField.text {
            self.addMessage(message, parent: nil)
        }

        self.dismissKeyboard(self)

        return true
    }
}
