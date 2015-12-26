//
//  UserViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/21/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Kingfisher
import Eureka

class UserViewController: FormViewController {

    // MARK: - UserViewController members

    var user: User?
    var root: Bool = false

    // MARK: - UserViewController functions

    func editButtonPushed() {
        if let user = self.user {
            performSegueWithIdentifier("editProfileSegue", sender: user)
        }
    }

    func updateUserElements() {
        guard self.user != nil else {
            Log.info("Expected a user initiated via previous controller.")
            return
        }

        self.navigationItem.title = user!.userName
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        guard self.user != nil else {
            Log.info("Expected a user initiated via previous controller.")
            return
        }

        let service = UserService()

        service.getFollowers(self.user!, completion: { _ in })
        service.getFollowing(self.user!, completion: { _ in })

        if self.root {
            if revealViewController() != nil {
                let menu = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: revealViewController(), action: "revealToggle:")
                self.navigationItem.leftBarButtonItem = menu
                view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            }
        }

        self.updateUserElements()

        self.tableView?.bounces = false

        ButtonRow.defaultCellSetup = { cell, row in cell.tintColor = .fablerOrangeColor() }

        self.form +++= Section() {
            var header = HeaderFooterView<UserHeaderView>(HeaderFooterProvider.NibFile(name: "UserHeader", bundle: nil))
            header.onSetupView = { [weak self] (view, section, form) -> () in
                if let user = self?.user, let url = NSURL(string: user.image) {
                    let manager = KingfisherManager.sharedManager
                    let cache = manager.cache

                    let key = "\(user.userId)-profile"

                    if let circle = cache.retrieveImageInDiskCacheForKey(key) {
                        view.profileImage?.image = circle
                    } else {
                        manager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, url) in
                            if error == nil, let image = image {
                                let circle = image.imageRoundedIntoCircle()
                                cache.storeImage(circle, forKey: key)

                                dispatch_async(dispatch_get_main_queue(), {
                                    view.profileImage?.image = circle
                                })
                            }
                        })
                    }
                }
            }

            $0.header = header
        }

        self.form +++= Section(header: "Social", footer: "")
            <<< ButtonRow("Followers") {
                $0.title = "\(self.user!.followers.count) Followers"
                $0.presentationMode = .SegueName(segueName: "displayFollowersSegue", completionCallback: nil)
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .Left
            }
            <<< ButtonRow("Following") {
                $0.title = "\(self.user!.following.count) Following"
                $0.presentationMode = .SegueName(segueName: "displayFollowingSegue", completionCallback: nil)
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .Left
            }
            <<< ButtonRow() {
                $0.title = "Subscribed"
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .Left
            }

        if user!.currentUser {
            self.form +++= Section(header: "Account Control", footer: "")
                <<< ButtonRow() {
                    $0.title = "Logout"
                }.cellUpdate { cell, row in
                    cell.textLabel?.textAlignment = .Left
                }

            let button = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: "editButtonPushed")
            self.navigationItem.rightBarButtonItem = button
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editProfileSegue" {
            if let controller = segue.destinationViewController as? UserEditViewController, let user = sender as? User {
                controller.user = user
            }
        } else if segue.identifier == "displayFollowersSegue" {
            if let controller = segue.destinationViewController as? UsersTableViewController {
                controller.following = false
                controller.user = self.user

                if let followers = self.user?.followers {
                    controller.users = Array(followers)
                }
            }
        } else if segue.identifier == "displayFollowingSegue" {
            if let controller = segue.destinationViewController as? UsersTableViewController {
                controller.following = true
                controller.user = self.user

                if let following = self.user?.following {
                    controller.users = Array(following)
                }
            }
        }
    }

    func performLogoutSegue() {
        if let window = UIApplication.sharedApplication().delegate?.window {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            let viewController = storyboard.instantiateViewControllerWithIdentifier("login")

            window?.rootViewController = viewController
            window?.makeKeyAndVisible()
        }
    }
}

class UserHeaderView: UIView {

    // MARK: - IBOutlets

    @IBOutlet weak var profileImage: UIImageView?

}
