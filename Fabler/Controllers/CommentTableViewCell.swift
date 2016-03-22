//
//  CommentTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import ChameleonFramework

protocol CollapsibleUITableViewCellDelegate {
    func setCollapseState(cell: UITableViewCell, collapsed: Bool)
}

protocol RepliesToCommentDelegate {
    func replyToComment(comment: Comment?)
    func editComment(comment: Comment)
    func showActionSheet(menu: UIAlertController)
}

protocol PerformsUserSegueDelegate {
    func performSegueToUser(user: User)
}

enum TextConversionError: ErrorType {
    case DataConversionFailed
}

class CommentTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var commentTextView: UITextView?
    @IBOutlet weak var userButton: UIButton?
    @IBOutlet weak var voteLabel: UILabel?
    @IBOutlet weak var subLabel: UILabel?
    @IBOutlet weak var subBar: UIView?
    @IBOutlet weak var replyButton: UIButton?
    @IBOutlet weak var upButton: UIButton?
    @IBOutlet weak var downButton: UIButton?
    @IBOutlet weak var moreButton: UIButton?

    @IBOutlet weak var commentIndent: NSLayoutConstraint?

    // MARK: - IBActions

    @IBAction func userButtonPressed(sender: AnyObject) {
        if let user = self.comment?.user {
            self.segueDelegate?.performSegueToUser(user)
        } else if let id = self.comment?.userId {
            let service = UserService()
            service.getUserFor(id) { [weak self] (user) in
                if let controller = self, let user = user {
                    controller.segueDelegate?.performSegueToUser(user)
                }
            }
        }
    }

    @IBAction func replyButtonPressed(sender: AnyObject) {
        guard let comment = self.comment else {
            return
        }

        let parent: Comment?

        if comment.parent == nil {
            parent = comment
        } else {
            parent = comment.parent
        }

        self.replyDelegate?.replyToComment(parent)
    }

    @IBAction func upButtonPressed(sender: AnyObject) {
        guard let comment = self.comment else {
            return
        }

        let service = CommentService()
        let vote: Vote

        if comment.userVote == .Up {
            vote = .None
        } else {
            vote = .Up
        }

        service.voteOnComment(comment, vote: vote, completion: self.voteDidFinish)
        self.voteDidUpdate()
    }

    @IBAction func downButtonPressed(sender: AnyObject) {
        guard let comment = self.comment else {
            return
        }

        let service = CommentService()
        let vote: Vote

        if comment.userVote == .Down {
            vote = .None
        } else {
            vote = .Down
        }

        service.voteOnComment(comment, vote: vote, completion: self.voteDidFinish)
        self.voteDidUpdate()
    }

    @IBAction func moreButtonPressed(sender: AnyObject) {
        let menu = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let delete = UIAlertAction(title: "Delete", style: .Destructive) { [weak self] (action) in
            guard let controller = self, let comment = controller.comment else {
                return
            }

            let service = CommentService()

            service.deleteComment(comment) { [weak self] (result) in
                guard result else {
                    return
                }

                self?.collapseDelegate?.setCollapseState(controller, collapsed: !controller.barCollapsed)
            }
        }

        let edit = UIAlertAction(title: "Edit", style: .Default) { [weak self] (action) in
            guard let comment = self?.comment else {
                return
            }

            self?.replyDelegate?.editComment(comment)
        }

        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)

        menu.addAction(delete)
        menu.addAction(edit)
        menu.addAction(cancel)

        self.replyDelegate?.showActionSheet(menu)
    }

    // MARK: - CommentTableViewCell properties

    var comment: Comment?
    var barCollapsed: Bool = true

    var tint: UIColor = .fablerOrangeColor()

    var collapseDelegate: CollapsibleUITableViewCellDelegate?
    var replyDelegate: RepliesToCommentDelegate?
    var segueDelegate: PerformsUserSegueDelegate?

    // MARK: - CommentTableViewCell methods

    func barTapped() {
        Log.verbose("User tapped comment.")
        self.collapseDelegate?.setCollapseState(self, collapsed: !self.barCollapsed)
    }

    func voteDidUpdate() {
        guard let comment = self.comment else {
            return
        }

        switch comment.userVote {
        case .Down:
            self.downButton?.tintColor = tint.lightenByPercentage(0.25)
            self.upButton?.tintColor = tint
        case .Up:
            self.downButton?.tintColor = tint
            self.upButton?.tintColor = tint.lightenByPercentage(0.25)
        default:
            self.downButton?.tintColor = tint
            self.upButton?.tintColor = tint
        }

        self.voteLabel?.text = "\(comment.voteCount)"
    }

    func voteDidFinish(result: Bool) {
        if !result {
            self.voteDidUpdate()
        }
    }

    func setCommentInstance(comment: Comment) {
        self.comment = comment

        comment.parent == nil ? self.styleCellAsParent() : self.styleCellAsChild()

        let localTimeZone = NSTimeZone.localTimeZone()
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = localTimeZone
        dateFormatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
        let date = dateFormatter.stringFromDate(comment.submitDate)
        self.subLabel?.text = "on \(date)"

        self.userButton?.setTitle(comment.userName, forState: .Normal)
        self.userButton?.tintColor = self.tint

        if let formattedComment = comment.formattedComment {
            self.commentTextView?.attributedText = formattedComment
        } else {
            self.commentTextView?.text = comment.comment
        }

        if self.barCollapsed {
            self.subBar?.hidden = true
        } else {
            self.subBar?.hidden = false
        }

        self.voteDidUpdate()

        if let user = User.getCurrentUser() {
            if comment.userId == user.userId {
                self.moreButton?.enabled = true
            }
        }

        if comment.removed {
            self.upButton?.enabled = false
            self.downButton?.enabled = false
            self.moreButton?.enabled = false
            self.userButton?.enabled = false
        } else {
            self.upButton?.enabled = true
            self.downButton?.enabled = true
            self.userButton?.enabled = true
        }

        self.replyButton?.tintColor = tint
        self.moreButton?.tintColor = tint

        let tapRec = UITapGestureRecognizer()
        tapRec.addTarget(self, action: #selector(CommentTableViewCell.barTapped))
        self.contentView.addGestureRecognizer(tapRec)
    }

    func styleCellAsParent() {
        self.commentIndent?.constant = 2
        self.backgroundColor = .whiteColor()
    }

    func styleCellAsChild() {
        self.commentIndent?.constant = 42
        self.backgroundColor = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
    }
}
