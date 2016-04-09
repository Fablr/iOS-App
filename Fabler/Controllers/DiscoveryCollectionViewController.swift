//
//  DiscoveryViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import SWRevealViewController

class DiscoveryCollectionViewController: UICollectionViewController {

    // MARK: - DiscoveryViewController properties

    private let reuseIdentifier = "ShowCell"
    private var podcasts: [Podcast] = []

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

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
        if let controller = segue.destinationViewController as? PodcastTableViewController, let podcast = sender as? Podcast where segue.identifier == "displayPodcastSegue" {
            controller.podcast = podcast
        }
    }

    // MARK: - UICollectionViewController methods

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        performSegueWithIdentifier("displayPodcastSegue", sender: podcasts[indexPath.row])
    }

    // MARK: - UICollectionViewDataSource methods

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return podcasts.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)

        if let cell = cell as? PodcastCell {
            let podcast = podcasts[indexPath.row]

            cell.setPodcastInstance(podcast)
        }

        return cell
    }
}
