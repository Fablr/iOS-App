//
//  PodcastTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class PodcastTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var tileImage: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
