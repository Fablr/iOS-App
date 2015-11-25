//
//  ShowTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class ShowTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var postImageView:UIImageView?
    @IBOutlet weak var authorImageView:UIImageView?
    @IBOutlet weak var postTitleLabel:UILabel?
    @IBOutlet weak var authorLabel:UILabel?

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
