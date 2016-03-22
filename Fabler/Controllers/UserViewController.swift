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
import RxSwift
import RxCocoa
import SCLAlertView
import RealmSwift
import SWRevealViewController

class UserViewController: FormViewController {

    // MARK: - UserViewController properties

    var user: User?
    var root: Bool = false

    var bag: DisposeBag! = DisposeBag()
    var token: NotificationToken?

    // MARK: - UserViewController properties

    func editButtonPushed() {
        guard let user = self.user else {
            return
        }

        performSegueWithIdentifier("editProfileSegue", sender: user)
    }

    func followButtonPressed() {
        guard let user = self.user else {
            return
        }

        let service = UserService()

        service.updateFollowing(user, following: !user.followingUser) { (result) in
            if !result {
                let warningText = !user.followingUser ? "follow" : "unfollow"
                SCLAlertView().showWarning("Warning", subTitle: "Unable to \(warningText) \(user.userName).")
            }
        }
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let user = self.user else {
            Log.info("Expected a user initiated via previous controller.")
            return
        }

        token = user.realm?.addNotificationBlock { [weak self] (_, _) in
            guard let user = self?.user else {
                return
            }

            if let row = self?.form.rowByTag("Following") {
                row.title = "\(user.following.count) Following"
            }

            if let row = self?.form.rowByTag("Followers") {
                row.title = "\(user.followers.count) Followers"
            }

            self?.tableView?.reloadData()
        }

        let service = UserService()

        service.getFollowers(user, completion: nil)
        service.getFollowing(user, completion: nil)
        service.getSubscribed(user, completion: nil)

        if self.root {
            if revealViewController() != nil {
                let menu = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: revealViewController(), action: #selector(SWRevealViewController.revealToggle))
                self.navigationItem.leftBarButtonItem = menu
                view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            }
        }

        self.tableView?.bounces = false

        ButtonRow.defaultCellSetup = { cell, row in cell.tintColor = .fablerOrangeColor() }

        self.form +++= Section() {
            var header = HeaderFooterView<UserHeaderView>(HeaderFooterProvider.NibFile(name: "UserHeader", bundle: nil))
            header.onSetupView = { (view, section, form) -> () in
                if let url = NSURL(string: user.image) {
                    let manager = KingfisherManager.sharedManager
                    let cache = manager.cache

                    let key = "\(user.userId)-profile"

                    if let circle = cache.retrieveImageInDiskCacheForKey(key) {
                        view.profileImage?.image = circle
                    } else {
                        manager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil) { (image, error, cacheType, url) in
                            if error == nil, let image = image {
                                let circle = image.imageRoundedIntoCircle()
                                cache.storeImage(circle, forKey: key)

                                dispatch_async(dispatch_get_main_queue()) {
                                    view.profileImage?.image = circle
                                }
                            }
                        }
                    }
                }
            }

            $0.header = header
        }

        self.form +++= Section(header: "Social", footer: "")
            <<< ButtonRow("Followers") {
                $0.title = "\(user.followers.count) Followers"
                $0.presentationMode = .SegueName(segueName: "displayFollowersSegue", completionCallback: nil)
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .Left
            }
            <<< ButtonRow("Following") {
                $0.title = "\(user.following.count) Following"
                $0.presentationMode = .SegueName(segueName: "displayFollowingSegue", completionCallback: nil)
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .Left
            }
            <<< ButtonRow() {
                $0.title = "Subscribed Podcasts"
                $0.presentationMode = .SegueName(segueName: "displaySubscribedSegue", completionCallback: nil)
            }.cellUpdate { cell, row in
                cell.textLabel?.textAlignment = .Left
            }

        if user.currentUser {
            self.form +++= Section(header: "Account Control", footer: "")
                <<< ButtonRow() {
                    $0.title = "Logout"
                }.cellUpdate { cell, row in
                    cell.textLabel?.textAlignment = .Left
                }

            let button = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(UserViewController.editButtonPushed))
            self.navigationItem.rightBarButtonItem = button
        }

        if !user.currentUser {
            self.user!
            .rx_observeWeakly(Bool.self, "followingUser")
            .subscribeNext { [ weak self] (following) in
                if let following = following {
                    let title: String
                    if following {
                        title = "Unfollow"
                    } else {
                        title = "Follow"
                    }

                    let button = UIBarButtonItem(title: title, style: .Plain, target: self, action: #selector(UserViewController.followButtonPressed))
                    self?.navigationItem.rightBarButtonItem = button
                }
            }
            .addDisposableTo(self.bag)
        }

        self.user!
        .rx_observeWeakly(String.self, "userName")
        .subscribeNext { [weak self] (name) in
            self?.navigationItem.title = name
        }
        .addDisposableTo(self.bag)
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
        } else if segue.identifier == "displaySubscribedSegue" {
            if let controller = segue.destinationViewController as? SubscribedTableViewController {
                controller.user = self.user
            }
        }

        if let topItem = self.navigationController?.navigationBar.topItem {
            topItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        }
    }

    override func viewWillAppear(animated: Bool) {
        if let navigation = self.navigationController as? FablerNavigationController {
            navigation.setDefaultNavigationBar()
        }

        super.viewWillAppear(animated)
    }

    deinit {
        self.bag = nil
        self.token?.stop()
    }

    // MARK: - UserViewController methods

    func performLogoutSegue() {
        guard let window = UIApplication.sharedApplication().delegate?.window else {
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let viewController = storyboard.instantiateViewControllerWithIdentifier("login")

        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }
}

class UserHeaderView: UIView {

    // MARK: - IBOutlets

    @IBOutlet weak var profileImage: UIImageView?
}
