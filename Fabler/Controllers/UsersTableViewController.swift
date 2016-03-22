//
//  UsersTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/23/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class UsersTableViewController: UITableViewController {

    // MARK: - UsersTableViewController properties

    var user: User?
    var users: [User] = []
    var following: Bool = false

    // MARK: - UsersTableViewController methods

    func refreshData(sender: AnyObject) {
        guard let user = self.user else {
            return
        }

        let service = UserService()

        if following {
            service.getFollowing(user) { [weak self] (result) in
                guard result else {
                    return
                }

                if let user = self?.user {
                    self?.users = Array(user.following)
                    self?.tableView.reloadData()
                }

                if let refresher = self?.refreshControl where refresher.refreshing {
                    refresher.endRefreshing()
                }
            }
        } else {
            service.getFollowers(user) { [weak self] (result) in
                guard result else {
                    return
                }

                if let user = self?.user {
                    self?.users = Array(user.followers)
                    self?.tableView.reloadData()
                }

                if let refresher = self?.refreshControl where refresher.refreshing {
                    refresher.endRefreshing()
                }
            }
        }
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        self.tableView.allowsMultipleSelection = false
        self.tableView.allowsSelection = true

        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: #selector(UsersTableViewController.refreshData), forControlEvents: .ValueChanged)
            refresher.backgroundColor = .fablerOrangeColor()
            refresher.tintColor = .whiteColor()
            self.tableView.addSubview(refresher)
        }

        if following {
            self.navigationItem.title = "Following"
        } else {
            self.navigationItem.title = "Followers"
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayUserSegue" {
            if let controller = segue.destinationViewController as? UserViewController, let user = sender as? User {
                controller.user = user
                controller.root = false
            }
        }
    }

    // MARK: - UITableViewController methods

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result = self.users.count

        if result > 0 {
            self.tableView?.backgroundView = nil
            self.tableView?.separatorStyle = .SingleLine
        } else {
            let frame = CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
            let label = UILabel(frame: frame)

            if following {
                label.text = "Not following anyone"
            } else {
                label.text = "No followers"
            }
            label.textAlignment = NSTextAlignment.Center

            self.tableView?.backgroundView = label
            self.tableView?.separatorStyle = .None
        }

        return result
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("UserCell", forIndexPath: indexPath)

        if let cell = cell as? UserTableViewCell {
            let user = self.users[indexPath.row]
            cell.setUserInstance(user)
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let user = self.users[indexPath.row]

        performSegueWithIdentifier("displayUserSegue", sender: user)
    }
}
