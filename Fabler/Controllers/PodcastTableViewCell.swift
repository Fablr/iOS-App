//
//  PodcastTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

public class PodcastTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var tileImage: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subscribeButton: UIButton?

    // MARK: - IBActions

    @IBAction func subscribeButtonPressed(sender: AnyObject) {
        guard let podcast = self.podcast else {
            return
        }

        self.subscribeButton?.hidden = true

        let service = PodcastService()
        service.subscribeToPodcast(podcast, subscribe: true, completion: nil)
    }

    // MARK: - PodcastTableViewCell properties

    var podcast: Podcast?

    // MARK: - PodcastTableViewCell methods

    public func setPodcastInstance(podcast: Podcast) {
        self.podcast = podcast

        if podcast.subscribed {
            self.subscribeButton?.hidden = true
        } else {
            self.subscribeButton?.hidden = false
        }

        self.titleLabel?.text = podcast.title

        if let url = NSURL(string: podcast.image) {
            self.tileImage?.kf_setImageWithURL(url, placeholderImage: nil)
        }
    }
}
