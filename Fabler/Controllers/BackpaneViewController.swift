//
//  BackpaneViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Kingfisher
import AlamofireImage

class BackpaneViewController: UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var userButton: UIButton?
    @IBOutlet weak var userImage: UIImageView?

    // MARK: - IBActions

    @IBAction func userButtonPressed(sender: AnyObject) {
        performSegueWithIdentifier("pushUserSegue", sender: self.user)
    }

    // MARK: - BackpaneViewController properties

    private var user: User?

    // MARK: - BackpaneViewController methods

    func updateUserElements() {
        guard let user = self.user else {
            return
        }

        if let url = NSURL(string: user.image) {
            let manager = KingfisherManager.sharedManager
            let cache = manager.cache

            let key = "\(user.userId)-profile"

            if let circle = cache.retrieveImageInDiskCacheForKey(key) {
                self.userImage?.image = circle
            } else {
                manager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil) { [weak self] (image, error, cacheType, url) in
                    guard let image = image where error == nil else {
                        return
                    }

                    let circle = image.af_imageRoundedIntoCircle()
                    cache.storeImage(circle, forKey: key)

                    dispatch_async(dispatch_get_main_queue()) { [weak self] in
                        self?.userImage?.image = circle
                    }
                }
            }
        }

        self.userButton?.setTitle(user.userName, forState: .Normal)
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(CurrentUserDidChangeNotification, object: nil, queue: mainQueue) { [weak self] (_) in
            self?.user = User.getCurrentUser()
            self?.updateUserElements()
        }

        self.user = User.getCurrentUser()
        updateUserElements()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        self.updateUserElements()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let controller = segue.destinationViewController as? FablerNavigationController, let root = controller.viewControllers.first as? UserViewController, let user = sender as? User where segue.identifier == "pushUserSegue" {
            root.user = user
            root.root = true
        }
    }
}
