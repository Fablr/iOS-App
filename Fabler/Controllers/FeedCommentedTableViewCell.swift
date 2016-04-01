//
//  FeedCommentedTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 3/31/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import SwiftDate

public class FeedCommentedTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var userButton: UIButton?
    @IBOutlet weak var objectButton: UIButton?
    @IBOutlet weak var commentTextView: UITextView?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var userImage: UIImageView?

    // MARK: - IBActions

    @IBAction func userButtonPressed(sender: AnyObject) {
        guard let user = self.event?.user else {
            return
        }

        self.userDelegate?.performSegueToUser(user)
    }

    @IBAction func objectButtonPressed(sender: AnyObject) {
        guard let comment = self.event?.comment else {
            return
        }

        switch comment.commentType {
        case .Podcast:
            guard let podcast = comment.podcast else {
                return
            }

            self.podcastDelegate?.performSegueToPodcast(podcast)

        case .Episode:
            guard let episode = comment.episode else {
                return
            }

            self.episodeDelegate?.performSegueToEpisode(episode)

        case .None:
            break
        }
    }

    // MARK: - FeedListenedTableViewCell properties

    public var event: Event?
    public var userDelegate: PerformsUserSegueDelegate?
    public var podcastDelegate: PerformsPodcastSegueDelegate?
    public var episodeDelegate: PerformsEpisodeSegueDelegate?

    // MARK: - FeedFollowedTableViewCell methods

    public func setEventInstance(event: Event) {
        guard event.eventType == .Commented else {
            fatalError("\(event.eventTypeRaw) passed to commented cell")
        }

        self.event = event

        guard let user = event.user, let comment = event.comment else {
            fatalError("Invalid event passed to commented cell")
        }

        self.userButton?.setTitle(user.userName, forState: .Normal)

        user.profileImage { [weak self] image in
            if let image = image {
                self?.userImage?.image = image
            }
        }

        if let date = event.time.toNaturalString(NSDate(), inRegion: nil, style: FormatterStyle(style: .Full, max: 1)) {
            self.timeLabel?.text = "\(date) ago"
        } else {
            self.timeLabel?.text = ""
        }

        if let formattedComment = comment.formattedComment {
            self.commentTextView?.attributedText = formattedComment
        } else {
            self.commentTextView?.text = comment.comment
        }

        switch comment.commentType {
        case .Episode:
            guard let episode = comment.episode else {
                fatalError("Invalid episode comment passed to commented cell")
            }

            self.objectButton?.setTitle(episode.title, forState: .Normal)

        case .Podcast:
            guard let podcast = comment.podcast else {
                fatalError("Invalid podcast comment passed to commented cell")
            }

            self.objectButton?.setTitle(podcast.title, forState: .Normal)

        case .None:
            fatalError("Invalid comment passed to commented cell")
        }
    }
}
