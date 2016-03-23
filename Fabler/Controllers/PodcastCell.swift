//
//  PodcastCell.swift
//  Fabler
//
//  Created by Christopher Day on 11/2/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

public class PodcastCell: UICollectionViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var tileImage: UIImageView?

    // MARK: - PodcastCell properties

    var podcast: Podcast?

    // MARK: - PodcastCell methods

    public func setPodcastInstance(podcast: Podcast) {
        self.podcast = podcast

        podcast.image { [weak self] (image) in
            self?.tileImage?.image = image
        }
    }
}
