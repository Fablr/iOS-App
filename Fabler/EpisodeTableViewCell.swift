//
//  EpisodeTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 11/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class EpisodeTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subLabel: UILabel?

    // MARK: - EpisodeTableViewCell members

    var episode: Episode?

    // MARK: - EpisodeTableViewCell functions

    func setEpisodeInstance(episode: Episode) {
        self.episode = episode

        if let episode = self.episode {
            let localTimeZone = NSTimeZone.localTimeZone()
            let dateFormatter = NSDateFormatter()
            dateFormatter.timeZone = localTimeZone
            dateFormatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
            let date = dateFormatter.stringFromDate(episode.pubdate)

            self.titleLabel?.text = episode.title
            self.subLabel?.text = date
        }
    }

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
