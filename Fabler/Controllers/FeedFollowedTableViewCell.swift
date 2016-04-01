//
//  FeedSubscribedTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 3/29/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import SwiftDate

public class FeedFollowedTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var profileImage: UIImageView?
    @IBOutlet weak var userButton: UIButton?
    @IBOutlet weak var eventLabel: UILabel?
    @IBOutlet weak var followedButton: UIButton?
    @IBOutlet weak var followedImage: UIImageView?
    @IBOutlet weak var followedLargeButton: UIButton?
    @IBOutlet weak var followButton: UIButton?

    // MARK: - IBActions

    @IBAction func followerButtonPressed(sender: AnyObject) {
        guard let user = event?.user else {
            return
        }

        self.delegate?.performSegueToUser(user)
    }

    @IBAction func followedButtonPressed(sender: AnyObject) {
        guard let user = event?.followed else {
            return
        }

        self.delegate?.performSegueToUser(user)
    }

    @IBAction func followButtonPressed(sender: AnyObject) {
        guard let user = event?.followed else {
            return
        }

        let service = UserService()
        service.updateFollowing(user, following: true) { [weak self] result in
            if !result {
                self?.followButton?.hidden = false
            }
        }

        self.followButton?.hidden = true
    }

    // MARK: - FeedFollowedTableViewCell properties

    public var event: Event?
    public var delegate: PerformsUserSegueDelegate?

    // MARK: - FeedFollowedTableViewCell methods

    public func setEventInstance(event: Event) {
        guard event.eventType == .Followed else {
            fatalError("\(event.eventTypeRaw) passed to followed cell")
        }

        self.event = event

        guard let follower = event.user, let followed = event.followed else {
            fatalError("Invalid subscribed event passed to followed cell")
        }

        let followedText = followed.currentUser ? "You" : followed.userName

        self.userButton?.setTitle(follower.userName, forState: .Normal)
        self.followedButton?.setTitle(followedText, forState: .Normal)
        self.followedLargeButton?.setTitle(followed.userName, forState: .Normal)

        if followed.followingUser || followed.currentUser {
            self.followButton?.hidden = true
        } else {
            self.followButton?.hidden = false
        }

        follower.profileImage { [weak self] image in
            if let image = image {
                self?.profileImage?.image = image
            }
        }

        followed.profileImage { [weak self] image in
            if let image = image {
                self?.followedImage?.image = image
            }
        }

        if let date = event.time.toNaturalString(NSDate(), inRegion: nil, style: FormatterStyle(style: .Full, max: 1)) {
            self.eventLabel?.text = "\(date) ago"
        } else {
            self.eventLabel?.text = ""
        }
    }
}
