//
//  PodcastSettingsViewController.swift
//  Fabler
//
//  Created by Christopher Day on 12/19/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Eureka

class PodcastSettingsViewController: FormViewController {

    // MARK: - PodcastSettingsViewController properties

    var podcast: Podcast?

    // MARK: - PodcastSettingsViewController methods

    func autoDownloadDidChange(row: CheckRow) {
        if let podcast = self.podcast, let value = row.value {
            let service = PodcastService()
            service.setDownloadForPodcast(podcast, allowAutoDownload: value)
        }
    }

    func notificationDidChange(row: CheckRow) {
        if let podcast = self.podcast, let value = row.value {
            let service = PodcastService()
            service.setNotificationForPodcast(podcast, allowNotifications: value)
        }
    }

    func downloadCountDidChange(row: IntRow) {
        if let podcast = self.podcast, let value = row.value {
            let service = PodcastService()
            service.setDownloadAmountForPodcast(podcast, amount: value)
        }
    }

    func sortOrderDidChange(row: AlertRow<String>) {
        if let podcast = self.podcast, let rawValue = row.value, let value = SortOrder(rawValue: rawValue) {
            let service = PodcastService()
            service.setSortOrderForPodcast(podcast, order: value)
        }
    }

    func unsubscribePressed(cell: ButtonCellOf<String>, row: ButtonRow) {
        if let podcast = self.podcast {
            let service = PodcastService()
            let subscribed = !(podcast.subscribed)

            service.subscribeToPodcast(podcast, subscribe: subscribed, completion: nil)
        }

        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func closePressed(cell: ButtonCellOf<String>, row: ButtonRow) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    func setFormValues() {
        if let podcast = self.podcast {
            let values: [String: Any?] = ["AutoDownload": podcast.download, "Notifications": podcast.notify, "DownloadCount": podcast.downloadAmount, "SortOrder": podcast.sortOrderRaw]
            self.form.setValues(values)
            self.tableView?.reloadData()
        }
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        guard self.podcast != nil else {
            Log.info("Expected a podcast initiated via previous controller.")
            return
        }

        let tint: UIColor

        if podcast!.primaryColor != nil {
            tint = podcast!.primaryColor!
        } else {
            tint = .fablerOrangeColor()
        }

        let blurEffect = UIBlurEffect(style: .Light)
        let veView = UIVisualEffectView(effect: blurEffect)
        veView.frame = self.view.bounds
        self.view.backgroundColor = .clearColor()
        self.view.insertSubview(veView, atIndex: 0)
        self.tableView?.backgroundColor = .clearColor()

        CheckRow.defaultCellSetup = { cell, row in cell.tintColor = tint }
        IntRow.defaultCellSetup = { cell, row in cell.tintColor = tint }

        self.navigationAccessoryView.tintColor = tint

        self.form +++= Section()
            <<< ButtonRow("Unsubscribe") {
                $0.title = $0.tag
                $0.onCellSelection(self.unsubscribePressed)
                $0.cellSetup({ cell, row in
                    cell.tintColor = .flatRedColor()
                    if let size = cell.textLabel?.font.pointSize {
                        cell.textLabel?.font = .boldSystemFontOfSize(size)
                    }
                })
            }

        self.form +++= Section()
            <<< CheckRow("AutoDownload") {
                $0.title = "Auto-download new episodes"
                $0.onChange(self.autoDownloadDidChange)
            }
            <<< CheckRow("Notifications") {
                $0.title = "Enable notifications for new episodes"
                $0.onChange(self.notificationDidChange)
            }
            <<< IntRow("DownloadCount") {
                $0.title = "Auto-download count"
                $0.onChange(self.downloadCountDidChange)
            }

        self.form +++= Section()
            <<< AlertRow<String>("SortOrder") {
                $0.title = "Episode sort order"
                $0.selectorTitle = "Episode sort order"
                $0.options = [SortOrder.NewestOldest.rawValue, SortOrder.OldestNewest.rawValue]
                $0.onChange(self.sortOrderDidChange)
            }
            .onPresent { _, action in
                action.view.tintColor = tint
            }

        self.form +++= Section()
            <<< ButtonRow("Close") {
                $0.title = $0.tag
                $0.onCellSelection(self.closePressed)
                $0.cellSetup({ cell, row in cell.tintColor = tint })
            }

        self.setFormValues()
    }
}
