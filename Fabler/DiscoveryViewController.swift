//
//  DiscoveryViewController.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class DiscoveryViewController: UICollectionViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var menuButton:UIBarButtonItem!

    // MARK: - DiscoveryViewController members

    private let reuseIdentifier = "ShowCell"
    private var podcasts:[Podcast]?

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        if revealViewController() != nil {
            menuButton.target = revealViewController()
            menuButton.action = "revealToggle:"
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        let service = PodcastService()
        self.podcasts = service.readAllPodcasts { podcasts in
            self.podcasts = podcasts
            self.collectionView!.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayShowSegue" {
            (segue.destinationViewController as! ShowTableViewController).podcast = (sender as! Podcast)
        }
    }

    // MARK: - UICollectionViewController functions

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard indexPath.section == 0 else {
            print("Unexpected section selected.")
            return
        }

        performSegueWithIdentifier("displayShowSegue", sender: podcasts![indexPath.row])
    }

    // MARK: - UICollectionViewDataSource functions

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard podcasts != nil else {
            return 0
        }

        return (podcasts?.count)!
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! ShowCell

        cell.titleLabel.text = podcasts?[indexPath.row].title

        return cell
    }
}
