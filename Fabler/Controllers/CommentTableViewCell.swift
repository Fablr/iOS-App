//
//  CommentTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

protocol CollapsibleUITableViewCellDelegate {
    func setCollapseState(cell: UITableViewCell, collapsed: Bool)
}

protocol RepliesToCommentDelegate {
    func replyToComment(comment: Comment?)
}

enum TextConversionError: ErrorType {
    case DataConversionFailed
}


class CommentTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var commentTextView: UITextView?
    @IBOutlet weak var voteLabel: UILabel?
    @IBOutlet weak var subLabel: UILabel?
    @IBOutlet weak var subBar: UIView?
    @IBOutlet weak var replyButton: UIButton?
    @IBOutlet weak var upButton: UIButton?
    @IBOutlet weak var downButton: UIButton?
    @IBOutlet weak var moreButton: UIButton?

    @IBOutlet weak var commentIndent: NSLayoutConstraint?

    // MARK: - IBActions

    @IBAction func replyButtonPressed(sender: AnyObject) {
        if let comment = self.comment {
            let parent: Comment?

            if comment.parent == nil {
                parent = comment
            } else {
                parent = comment.parent
            }

            self.replyDelegate?.replyToComment(parent)
        }
    }

    @IBAction func upButtonPressed(sender: AnyObject) {
        if let comment = self.comment {
            let service = CommentService()

            // CHRIS move this logic into service
            switch comment.userVote {
            case .Up:
                service.voteOnComment(comment, vote: Vote.None, completion: self.voteDidFinish)
                comment.userVoteRaw = Vote.None.rawValue
                comment.voteCount--
            case .Down:
                service.voteOnComment(comment, vote: Vote.Up, completion: self.voteDidFinish)
                comment.userVoteRaw = Vote.Up.rawValue
                comment.voteCount += 2
            case .None:
                service.voteOnComment(comment, vote: Vote.Up, completion: self.voteDidFinish)
                comment.userVoteRaw = Vote.Up.rawValue
                comment.voteCount++
            }

            self.voteDidUpdate()
        }
    }

    @IBAction func downButtonPressed(sender: AnyObject) {
        if let comment = self.comment {
            let service = CommentService()

            // CHRIS move this logic into service
            switch comment.userVote {
            case .Up:
                service.voteOnComment(comment, vote: Vote.Down, completion: self.voteDidFinish)
                comment.userVoteRaw = Vote.Down.rawValue
                comment.voteCount -= 2
            case .Down:
                service.voteOnComment(comment, vote: Vote.None, completion: self.voteDidFinish)
                comment.userVoteRaw = Vote.None.rawValue
                comment.voteCount++
            case .None:
                service.voteOnComment(comment, vote: Vote.Down, completion: self.voteDidFinish)
                comment.userVoteRaw = Vote.Down.rawValue
                comment.voteCount--
            }

            self.voteDidUpdate()
        }
    }

    @IBAction func moreButtonPressed(sender: AnyObject) {
        Log.debug("More button pressed.")
    }

    // MARK: - CommentTableViewCell members

    var comment: Comment?
    var barCollapsed: Bool = true

    var collapseDelegate: CollapsibleUITableViewCellDelegate?
    var replyDelegate: RepliesToCommentDelegate?

    // MARK: - CommentTableViewCell functions

    func barTapped() {
        Log.verbose("User tapped comment.")
        self.collapseDelegate?.setCollapseState(self, collapsed: !self.barCollapsed)
    }

    func voteDidUpdate() {
        if let comment = self.comment {
            switch comment.userVote {
            case .Down:
                self.downButton?.tintColor = UIColor.washedOutFablerOrangeColor()
                self.upButton?.tintColor = UIColor.fablerOrangeColor()
            case .Up:
                self.downButton?.tintColor = UIColor.fablerOrangeColor()
                self.upButton?.tintColor = UIColor.washedOutFablerOrangeColor()
            default:
                self.downButton?.tintColor = UIColor.fablerOrangeColor()
                self.upButton?.tintColor = UIColor.fablerOrangeColor()
            }

            self.voteLabel?.text = "\(comment.voteCount)"
        }
    }

    func voteDidFinish(result: Bool) {
        Log.debug("Vote did finish.")
    }

    func setCommentInstance(comment: Comment) {
        self.comment = comment

        if let comment = self.comment {
            comment.parent == nil ? self.styleCellAsParent() : self.styleCellAsChild()

            let localTimeZone = NSTimeZone.localTimeZone()
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeZone = localTimeZone
            dateFormatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
            let date = dateFormatter.stringFromDate(comment.submitDate)
            self.subLabel?.text = "by \(comment.userName) on \(date)"

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

            let tapRec = UITapGestureRecognizer()
            tapRec.addTarget(self, action: "barTapped")
            self.contentView.addGestureRecognizer(tapRec)
        }
    }

    func styleCellAsParent() {
        self.commentIndent?.constant = 2
        self.backgroundColor = UIColor.whiteColor()
    }

    func styleCellAsChild() {
        self.commentIndent?.constant = 42
        self.backgroundColor = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
    }

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
