//
//  CommentTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/3/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class CommentTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var bodyLabel: UILabel?
    @IBOutlet weak var subLabel: UILabel?
    @IBOutlet weak var commentIndent: NSLayoutConstraint?

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func styleCellAsParent() {
        self.commentIndent?.constant = 5
        self.backgroundColor = UIColor.whiteColor()
    }

    func styleCellAsChild() {
        self.commentIndent?.constant = 45
        self.backgroundColor = UIColor(red: 250.0/255.0, green: 250.0/255.0, blue: 250.0/255.0, alpha: 1.0)
    }
}
