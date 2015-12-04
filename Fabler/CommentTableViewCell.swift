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

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
