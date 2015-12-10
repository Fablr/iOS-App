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

// swiftlint:disable nesting

class CommentTableViewCell: UITableViewCell {

    // MARK: - Enums

    private enum TextConversionError: ErrorType {
        case DataConversionFailed
    }

    // MARK: - IBOutlets

    @IBOutlet weak var commentTextView: UITextView?
    @IBOutlet weak var subLabel: UILabel?
    @IBOutlet weak var commentIndent: NSLayoutConstraint?
    @IBOutlet weak var subBar: UIView?
    @IBOutlet weak var subBarHeight: NSLayoutConstraint?

    // MARK: - CommentTableViewCell members

    var comment: Comment?
    var barCollapsed: Bool = true
    var delegate: CollapsibleUITableViewCellDelegate?

    // MARK: - CommentTableViewCell functions

    func barTapped() {
        self.delegate?.setCollapseState(self, collapsed: !self.barCollapsed)
    }

    func setCommentInstance(comment: Comment) {
        self.comment = comment

        if let comment = self.comment {
            comment.parentId == nil ? self.styleCellAsParent() : self.styleCellAsChild()

            let localTimeZone = NSTimeZone.localTimeZone()
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeZone = localTimeZone
            dateFormatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
            let date = dateFormatter.stringFromDate(comment.submitDate)

            if let formattedComment = comment.formattedComment {
                self.commentTextView?.attributedText = formattedComment
            } else {
                self.commentTextView?.text = comment.comment
            }
            self.commentTextView?.sizeToFit()

            if self.barCollapsed {
                self.subBar?.hidden = true
                self.subBarHeight?.constant = 0.0
            } else {
                self.subBar?.hidden = false
                self.subBarHeight?.constant = 25.0
            }

            let tapRec = UITapGestureRecognizer()
            tapRec.addTarget(self, action: "barTapped")
            self.contentView.addGestureRecognizer(tapRec)

            self.subLabel?.text = "by \(comment.userName) on \(date)"
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
