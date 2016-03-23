//
//  UserTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/23/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import SCLAlertView

class UserTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var profileImage: UIImageView?
    @IBOutlet weak var userLabel: UILabel?
    @IBOutlet weak var followButton: UIButton?

    // MARK: - IBActions

    @IBAction func followButtonPressed(sender: AnyObject) {
        guard let user = self.user else {
            return
        }

        self.setupFollowButton(!user.followingUser)

        let service = UserService()

        service.updateFollowing(user, following: !user.followingUser) { [weak self] (result) in
            self?.setupFollowButton(user.followingUser)

            if !result {
                let warningText = !user.followingUser ? "follow" : "unfollow"
                SCLAlertView().showWarning("Warning", subTitle: "Unable to \(warningText) \(user.userName).")
            }
        }
    }

    // MARK: - EpisodeTableViewCell properties

    var user: User?

    // MARK: - EpisodeTableViewCell methods

    func setupFollowButton(following: Bool) {
        if following {
            self.followButton?.setTitle("Unfollow", forState: .Normal)
        } else {
            self.followButton?.setTitle("Follow", forState: .Normal)
        }
    }

    func setUserInstance(user: User) {
        self.user = user

        var title = "\(user.firstName) \(user.lastName)"

        if title == " " {
            title = "\(user.userName)"
        }

        self.setupFollowButton(user.followingUser)

        user.profileImage { [weak self] (image) in
            self?.profileImage?.image = image
        }

        self.userLabel?.text = title

        if user.currentUser {
            self.followButton?.hidden = true
        } else {
            self.followButton?.hidden = false
        }
    }
}
