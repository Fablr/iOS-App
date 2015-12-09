//
//  EpisodeHeaderTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class EpisodeHeaderTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var segmentedControl: UISegmentedControl?

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
