//
//  EpisodeHeaderTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

protocol ChangesBasedOnSegment {
    func segmentDidChangeTo(index: Int)
}

class EpisodeSectionHeaderView: UITableViewHeaderFooterView {

    // MARK: - IBOutlets

    @IBOutlet weak var segmentControl: UISegmentedControl?

    // MARK: - IBActions

    @IBAction func segmentValueChanged(sender: AnyObject) {
        if let control = self.segmentControl {
            self.delegate?.segmentDidChangeTo(control.selectedSegmentIndex)
        }
    }

    // MARK: - EpisodeSectionHeaderView members

    var delegate: ChangesBasedOnSegment?
}
