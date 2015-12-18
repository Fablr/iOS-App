//
//  UserTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/15/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Kingfisher
import RealmSwift

class UserTableViewController: UITableViewController, PerformsLogoutSegueDelegate {

    // MARK: - IBOutlets

    @IBOutlet weak var userImage: UIImageView?

    // MARK: - UserTableViewController members

    var user: User?
    var root: Bool = false

    var token: NotificationToken?

    // MARK: - UserTableViewController functions

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

        if let user = self.user, let url = NSURL(string: user.image) {
            let manager = KingfisherManager.sharedManager
            let cache = manager.cache

            let key = "\(user.userId)-profile"

            if let circle = cache.retrieveImageInDiskCacheForKey(key) {
                self.userImage?.image = circle
            } else {
                manager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { [weak self] (image, error, cacheType, url) in
                    if error == nil, let image = image {
                        let circle = image.imageRoundedIntoCircle()
                        cache.storeImage(circle, forKey: key)

                        dispatch_async(dispatch_get_main_queue(), { [weak self] in
                            self?.userImage?.image = circle
                        })
                    }
                })
            }
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

        if self.root {
            if revealViewController() != nil {
                let menu = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: revealViewController(), action: "revealToggle:")
                self.navigationItem.leftBarButtonItem = menu
                view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
            }
        }

        self.updateUserElements()

        if user!.currentUser {
            let button = UIBarButtonItem(title: "Edit", style: UIBarButtonItemStyle.Plain, target: self, action: "editButtonPushed")
            self.navigationItem.rightBarButtonItem = button

            do {
                let realm = try Realm()

                self.token = realm.addNotificationBlock({ [weak self] (_, _) in
                    self?.updateUserElements()
                })
            } catch {
                Log.warning("Unable to monitor for user value changes.")
            }
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        if let token = self.token {
            do {
                let realm = try Realm()

                realm.removeNotification(token)
            } catch {
                Log.warning("Failed to remove notification.")
            }
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editProfileSegue" {
            if let controller = segue.destinationViewController as? UserEditViewController, let user = sender as? User {
                controller.user = user
            }
        }
    }

    // MARK: - UITableViewController functions

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let result: Int

        if let user = self.user where user.currentUser {
            result = 1
        } else {
            result = 0
        }

        return result
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result: Int

        if section == 0 {
            if let user = self.user where user.currentUser {
                result = 1
            } else {
                result = 0
            }
        } else {
            result = 0
        }

        return result
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        Log.verbose("Building cell.")

        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCellWithIdentifier("FBLogoutCell", forIndexPath: indexPath)

            if let cell = cell as? FBLogoutTableViewCell {
                cell.delegate = self
            }

            return cell
        }

        return UITableViewCell()
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCellWithIdentifier("SectionHeader")

        if let cell = cell as? ProfileSectionHeaderTableViewCell {
            switch section {
            case 0:
                cell.headerLabel?.text = "Account control"
            default:
                cell.headerLabel?.text = ""
            }

            cell.seperatorHeight?.constant = 0.5
        }

        return cell?.contentView
    }

    // MARK: - PerformsLogoutSegueDelegate

    func performLogoutSegue() {
        //performSegueWithIdentifier("loggedOutSegue", sender: nil)
        if let window = UIApplication.sharedApplication().delegate?.window {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            let viewController = storyboard.instantiateViewControllerWithIdentifier("login")

            window?.rootViewController = viewController
            window?.makeKeyAndVisible()
        }
    }
}
