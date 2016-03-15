//
//  SettingViewController.swift
//  Fabler
//
//  Created by Christopher Day on 3/15/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import Eureka
import Kingfisher

class SettingViewController: FormViewController {

    // MARK: - SettingViewController properties

    var downloadSizeInBytes: Int = 0
    var imageCacheSizeInBytes: Int = 0

    // MARK: - SettingViewController methods

    func updateValues() {
        let values: [String: Any?] = ["ImageCacheSize": sizeStringFrom(self.imageCacheSizeInBytes), "EpisodeSize": sizeStringFrom(self.downloadSizeInBytes)]
        self.form.setValues(values)
        self.tableView?.reloadData()
    }

    func downloadsClear(cell: ButtonCellOf<String>, row: ButtonRow) {
        let manager = FablerDownloadManager.sharedInstance
        manager.removeAll()

        self.downloadSizeInBytes = 0
        self.updateValues()
    }

    func imageCacheClear(cell: ButtonCellOf<String>, row: ButtonRow) {
        let manager = KingfisherManager.sharedManager
        manager.cache.clearDiskCache()

        self.imageCacheSizeInBytes = 0
        self.updateValues()
    }

    func setupPodcastSection(podcasts: [Podcast]) {
        guard let section = self.form.sectionByTag("PodcastSection") else {
            return
        }

        section.removeAll()

        for podcast in podcasts {
            section
                <<< ButtonRow() {
                    $0.title = "\(podcast.title)"
                }
                .onCellSelection { [weak self] (cell, row) in
                    self?.performSegueWithIdentifier("displayPodcastSettingsSegue", sender: podcast)
                }
                .cellUpdate { cell, row in
                    cell.textLabel?.textAlignment = .Left
                }
        }

        self.tableView?.reloadData()
    }

    // MARK: UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        if revealViewController() != nil {
            let menu = UIBarButtonItem(image: UIImage(named: "menu"), style: .Plain, target: revealViewController(), action: "revealToggle:")
            self.navigationItem.leftBarButtonItem = menu
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }

        self.navigationItem.title = "Settings"

        ButtonRow.defaultCellSetup = { cell, row in cell.tintColor = .fablerOrangeColor() }

        //
        // Episode cache
        //
        self.form +++= Section(header: "Downloaded Episodes", footer: "")
            <<< AlertRow<String>("EpisodeSize") {
                $0.title = "Size of downloaded episodes"
                $0.disabled = true
                $0.hidden = false
            }
            <<< ButtonRow("ClearEpisodes") {
                $0.title = "Delete downloaded episodes "
                $0.onCellSelection(self.downloadsClear)
                $0.cellSetup({ cell, row in
                    cell.tintColor = .flatRedColor()
                    if let size = cell.textLabel?.font.pointSize {
                        cell.textLabel?.font = .boldSystemFontOfSize(size)
                    }
                })
            }

        let downloadManager = FablerDownloadManager.sharedInstance

        downloadManager.calculateSizeOnDisk({ [weak self] (size) in
            self?.downloadSizeInBytes = size
            self?.updateValues()
        })

        //
        // Image Cache
        //
        self.form +++= Section(header: "Image Cache", footer: "")
            <<< AlertRow<String>("ImageCacheSize") {
                $0.title = "Size of image cache"
                $0.disabled = true
                $0.hidden = false
            }
            <<< ButtonRow("ClearImageCache") {
                $0.title = "Clear image cache"
                $0.onCellSelection(self.imageCacheClear)
                $0.cellSetup({ cell, row in
                    cell.tintColor = .flatRedColor()
                    if let size = cell.textLabel?.font.pointSize {
                        cell.textLabel?.font = .boldSystemFontOfSize(size)
                    }
                })
            }

        //
        // Individual podcast settings
        //
        self.form +++= Section(header: "Podcast Settings", footer: "") {
            $0.tag = "PodcastSection"
        }

        let service = PodcastService()
        let podcasts = service.getSubscribedPodcasts(completion: { [weak self] (podcasts) in
            self?.setupPodcastSection(podcasts)
        })

        self.setupPodcastSection(podcasts)

        let cacheManager = KingfisherManager.sharedManager

        cacheManager.cache.calculateDiskCacheSizeWithCompletionHandler({ [weak self] (size) in
            self?.imageCacheSizeInBytes = Int(size)
            self?.updateValues()
        })

        //
        // Default values
        //
        self.updateValues()
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayPodcastSettingsSegue" {
            if let controller = segue.destinationViewController as? PodcastSettingsViewController, let podcast = sender as? Podcast {
                controller.podcast = podcast
                controller.embeddedNavigation = true
            }
        }
    }
}
