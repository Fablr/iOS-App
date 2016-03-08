//
//  EpisodeHeaderTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Hue

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

    // MARK: - EpisodeSectionHeaderView properties

    var delegate: ChangesBasedOnSegment?

    // MARK: - EpisodeSectionHeaderView methods

    func setColors(primary: UIColor?) {
        var foreground: UIColor
        var background: UIColor

        if primary == nil {
            foreground = .fablerOrangeColor()
        } else {
            foreground = primary!
        }

        if foreground.isBlackOrWhite {
            background = foreground
            foreground = UIColor(contrastingBlackOrWhiteColorOn: foreground, isFlat: true)
        } else {
            background = UIColor(contrastingBlackOrWhiteColorOn: foreground, isFlat: true)
        }

        self.segmentControl?.tintColor = foreground
        self.segmentControl?.backgroundColor = background
    }
}
