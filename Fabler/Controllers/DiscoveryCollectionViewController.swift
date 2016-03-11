//
//  DiscoveryViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Kingfisher

class DiscoveryCollectionViewController: UICollectionViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var menuButton: UIBarButtonItem?

    // MARK: - DiscoveryViewController properties

    private let reuseIdentifier = "ShowCell"
    private var podcasts: [Podcast]?

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        if revealViewController() != nil {
            self.menuButton?.target = revealViewController()
            self.menuButton?.action = "revealToggle:"
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        let service = PodcastService()
        self.podcasts = service.readAllPodcasts { [weak self] (podcasts) in
            self?.podcasts = podcasts
            self?.collectionView?.reloadData()
        }
    }

    override func viewWillAppear(animated: Bool) {
        if let navigation = self.navigationController as? FablerNavigationController {
            navigation.setDefaultNavigationBar()
        }

        super.viewWillAppear(animated)
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayPodcastSegue" {
            if let controller = segue.destinationViewController as? PodcastTableViewController, let podcast = sender as? Podcast {
                controller.podcast = podcast
            }
        }
    }

    // MARK: - UICollectionViewController methods

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            Log.warning("Unexpected section selected.")
            return
        }

        performSegueWithIdentifier("displayPodcastSegue", sender: podcasts![indexPath.row])
    }

    // MARK: - UICollectionViewDataSource methods

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let podcasts = self.podcasts else {
            return 0
        }

        return podcasts.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)

        if let cell = cell as? PodcastCell {
            if let path = podcasts?[indexPath.row].image, let url = NSURL(string: path) {
                cell.tileImage?.kf_setImageWithURL(url, placeholderImage: nil)
            }
        }

        return cell
    }
}
