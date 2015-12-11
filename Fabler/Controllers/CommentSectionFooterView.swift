//
//  CommentHeaderTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class CommentSectionFooterView: UITableViewHeaderFooterView {

    // MARK: - IBOutlets

    @IBOutlet weak var commentButton: UIButton?

    // MARK: - IBActions

    @IBAction func commentButtonPressed(sender: AnyObject) {
        self.delegate?.replyToComment(nil)
    }

    // MARK: - CommentSectionFooterView members

    var delegate: RepliesToCommentDelegate?
}
