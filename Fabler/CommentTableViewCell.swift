//
//  CommentTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import MMMarkdown

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

    // MARK: - CommentTableViewCell members

    var comment: Comment?

    // MARK: - CommentTableViewCell functions

    func setComment(comment: Comment) {
        self.comment = comment

        if let comment = self.comment {
            comment.parentId == nil ? self.styleCellAsParent() : self.styleCellAsChild()

            let localTimeZone = NSTimeZone.localTimeZone()
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeZone = localTimeZone
            dateFormatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
            let date = dateFormatter.stringFromDate(comment.submitDate)

            do {
                let html = try MMMarkdown.HTMLStringWithMarkdown(comment.comment, extensions: MMMarkdownExtensions.GitHubFlavored)
                let styledHTML = "<html><head><style>body {font-family: Helvetica Neue; font-size: 15;}</style></head><body>\(html)</body></html>"

                if let data = styledHTML.dataUsingEncoding(NSUnicodeStringEncoding, allowLossyConversion: true) {
                    let attributed = try NSMutableAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil)
                    self.commentTextView?.attributedText = attributed
                } else {
                    throw TextConversionError.DataConversionFailed
                }
            } catch {
                self.commentTextView?.text = comment.comment
            }
            self.commentTextView?.sizeToFit()

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
