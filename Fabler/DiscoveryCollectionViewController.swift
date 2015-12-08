//
//  DiscoveryViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import AlamofireImage

class DiscoveryCollectionViewController: UICollectionViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var menuButton: UIBarButtonItem?

    // MARK: - DiscoveryViewController members

    private let reuseIdentifier = "ShowCell"
    private var podcasts: [Podcast]?

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        if revealViewController() != nil {
            self.menuButton?.target = revealViewController()
            self.menuButton?.action = "revealToggle:"
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        let service = PodcastService()
        self.podcasts = service.readAllPodcasts { podcasts in
            self.podcasts = podcasts
            self.collectionView?.reloadData()
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayPodcastSegue" {
            if let controller = segue.destinationViewController as? PodcastTableViewController, let podcast = sender as? Podcast {
                controller.podcast = podcast
            }
        }
    }

    // MARK: - UICollectionViewController functions

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            print("Unexpected section selected.")
            return
        }

        performSegueWithIdentifier("displayPodcastSegue", sender: podcasts![indexPath.row])
    }

    // MARK: - UICollectionViewDataSource functions

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard podcasts != nil else {
            return 0
        }

        return podcasts!.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)

        if let cell = cell as? PodcastCell {
            if let path = podcasts?[indexPath.row].image, let url = NSURL(string: path) {
                let placeholder = UIImage(named: "logo-launch")
                cell.tileImage?.af_setImageWithURL(url, placeholderImage: placeholder)
            }
        }

        return cell
    }
}
