//
//  ShowSettingsViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/19/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class ShowSettingsTableViewController : UITableViewController {

    var podcast: Podcast?

    // MARK: - IBOutlets

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var downloadSwitch: UISwitch!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var amountStepper: UIStepper!
    @IBOutlet weak var amountLabel: UILabel!

    // MARK: - IBActions

    @IBAction func topCloseButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func bottomCloseButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func downloadSwitchChanged(sender: AnyObject) {
        let service = PodcastService()
        service.setDownloadForPodcast(podcast!, allowAutoDownload: self.downloadSwitch.on)
    }

    @IBAction func notificationSwitchChanged(sender: AnyObject) {
        let service = PodcastService()
        service.setNotificationForPodcast(podcast!, allowNotifications: self.notificationSwitch.on)
    }

    @IBAction func amountStepperChanged(sender: AnyObject) {
        let service = PodcastService()
        service.setDownloadAmountForPodcast(podcast!, amount: Int(self.amountStepper.value))

        self.amountLabel.text = String(format: "Auto-download %d new episodes.", podcast!.downloadAmount)
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let veView = UIVisualEffectView(effect: blurEffect)
        veView.frame = self.view.bounds
        self.view.backgroundColor = UIColor.clearColor()
        self.view.insertSubview(veView, atIndex: 0)

        self.edgesForExtendedLayout = UIRectEdge.None
        self.extendedLayoutIncludesOpaqueBars = false
        self.automaticallyAdjustsScrollViewInsets = false

        self.downloadSwitch.on = podcast!.download
        self.notificationSwitch.on = podcast!.notify
        self.amountStepper.value = Double(podcast!.downloadAmount)

        self.amountLabel.text = String(format: "Auto-download %d new episodes.", podcast!.downloadAmount)

        titleLabel.text = podcast!.title + " Settings"
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
