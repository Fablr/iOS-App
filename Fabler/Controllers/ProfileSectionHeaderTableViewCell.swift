//
//  ProfileSectionHeaderTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/16/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class ProfileSectionHeaderTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var headerLabel: UILabel?
    @IBOutlet weak var seperatorHeight: NSLayoutConstraint?

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
