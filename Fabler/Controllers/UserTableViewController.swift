//
//  UserTableViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/15/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Kingfisher

class UserTableViewController: UITableViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var userImage: UIImageView?

    // MARK: - UserTableViewController members

    var user: User?

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        guard self.user != nil else {
            Log.error("Expected a user initiated via previous controller.")
            return
        }

        super.viewDidLoad()

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

        if user!.currentUser {
            let button = UIBarButtonItem(barButtonSystemItem: .Compose, target: self, action: "editSegue")
            self.navigationItem.rightBarButtonItem = button
        }
    }
}
