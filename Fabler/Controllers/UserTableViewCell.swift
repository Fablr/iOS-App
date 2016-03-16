//
//  UserTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/23/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Kingfisher
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

        service.updateFollowing(user, following: !user.followingUser, completion: { [weak self] (result) in
            self?.setupFollowButton(user.followingUser)

            if !result {
                let warningText = !user.followingUser ? "follow" : "unfollow"
                SCLAlertView().showWarning("Warning", subTitle: "Unable to \(warningText) \(user.userName).")
            }
        })
    }

    // MARK: - EpisodeTableViewCell properties

    var user: User?

    // MARK: - EpisodeTableViewCell methods

    func setupFollowButton(following: Bool) {
        if following {
            self.followButton?.setImage(UIImage(named: "user-remove"), forState: .Normal)
            self.followButton?.tintColor = .washedOutFablerOrangeColor()
        } else {
            self.followButton?.setImage(UIImage(named: "user-add"), forState: .Normal)
            self.followButton?.tintColor = .fablerOrangeColor()
        }
    }

    func setUserInstance(user: User) {
        self.user = user

        var title = "\(user.firstName) \(user.lastName)"

        if title == " " {
            title = "\(user.userName)"
        }

        self.setupFollowButton(user.followingUser)

        if let url = NSURL(string: user.image) {
            let manager = KingfisherManager.sharedManager
            let cache = manager.cache

            let key = "\(user.userId)-profile"

            if let circle = cache.retrieveImageInDiskCacheForKey(key) {
                self.profileImage?.image = circle
            } else {
                manager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { [weak self] (image, error, cacheType, url) in
                    guard let cell = self, let image = image where error == nil else {
                        return
                    }

                    let circle = image.imageRoundedIntoCircle()
                    cache.storeImage(circle, forKey: key)

                    dispatch_async(dispatch_get_main_queue(), {
                        cell.profileImage?.image = circle
                    })
                })
            }
        }

        self.userLabel?.text = title

        if user.currentUser {
            self.followButton?.hidden = true
        } else {
            self.followButton?.hidden = false
        }
    }
}
