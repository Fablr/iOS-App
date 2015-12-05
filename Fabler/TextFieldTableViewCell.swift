//
//  TextFieldTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/4/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class TextFieldTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var textField: UITextField?

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
