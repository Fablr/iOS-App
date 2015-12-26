//
//  UsersTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/23/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class UsersTableViewController: UITableViewController {

    // MARK: - UsersTableViewController members

    var user: User?
    var users: [User] = []
    var following: Bool = false

    // MARK: - UsersTableViewController functions

    func refreshData(sender: AnyObject) {
        if let user = self.user {
            let service = UserService()

            if following {
                service.getFollowing(user, completion: { [weak self] (result) in
                    if let controller = self where result {
                        if let user = controller.user {
                            controller.users = Array(user.following)
                            controller.tableView.reloadData()
                        }

                        if let refresher = controller.refreshControl where refresher.refreshing {
                            refresher.endRefreshing()
                        }
                    }
                })
            } else {
                service.getFollowers(user, completion: { [weak self] (result) in
                    if let controller = self where result {
                        if let user = controller.user {
                            controller.users = Array(user.followers)
                            controller.tableView.reloadData()
                        }

                        if let refresher = controller.refreshControl where refresher.refreshing {
                            refresher.endRefreshing()
                        }
                    }
                })
            }
        }


        /*let service = PodcastService()
        self.podcasts = service.getSubscribedPodcasts { [weak self] (podcasts) in
            if let controller = self {
                controller.podcasts = podcasts
                controller.tableView.reloadData()

                if let refresher = controller.refreshControl {
                    if refresher.refreshing {
                        refresher.endRefreshing()
                    }
                }
            }
        }*/
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        self.tableView.allowsMultipleSelection = false
        self.tableView.allowsSelection = true

        self.refreshControl = UIRefreshControl()
        if let refresher = self.refreshControl {
            refresher.attributedTitle = NSAttributedString(string: "Pull to refresh", attributes: [NSForegroundColorAttributeName: UIColor.whiteColor()])
            refresher.addTarget(self, action: "refreshData:", forControlEvents: UIControlEvents.ValueChanged)
            refresher.backgroundColor = UIColor.fablerOrangeColor()
            refresher.tintColor = UIColor.whiteColor()
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

    // MARK: - UITableViewController functions

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let result = self.users.count

        if result > 0 {
            self.tableView?.backgroundView = nil
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
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
            self.tableView?.separatorStyle = UITableViewCellSeparatorStyle.None
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
