//
//  EpisodeTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 11/6/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import ACPDownload
import RealmSwift
import RxSwift
import RxCocoa

protocol PresentAlertControllerDelegate {
    func presentAlert(controller: UIAlertController)
}

class EpisodeTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var subLabel: UILabel?
    @IBOutlet weak var downloadView: ACPDownloadView?
    @IBOutlet weak var ellipsisButton: UIButton?

    // MARK: - EpisodeTableViewCell members

    var episode: Episode?
    var token: NotificationToken?
    var bag: DisposeBag! = DisposeBag()

    // MARK: - Delegates

    var presentDelegate: PresentAlertControllerDelegate?

    // MARK: - IBActions

    @IBAction func ellipsisButtonPressed(sender: AnyObject) {
        let actionController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: { action in

        })
        actionController.addAction(cancelAction)

        self.presentDelegate?.presentAlert(actionController)
    }

    // MARK: - EpisodeTableViewCell functions

    func setEpisodeInstance(episode: Episode) {
        token?.stop()
        token = nil

        self.episode = episode

        let localTimeZone = NSTimeZone.localTimeZone()
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = localTimeZone
        dateFormatter.dateFormat = "dd/MM/yyyy 'at' HH:mm"
        let date = dateFormatter.stringFromDate(episode.pubdate)

        self.titleLabel?.text = episode.title
        self.subLabel?.text = date

        if let podcast = episode.podcast {
            podcast.rx_observe(Float.self, "backgroundBlue")
            .subscribeNext({ [weak self] (color) in
                if let bgColor = self?.episode?.podcast?.backgroundColor, let primary = self?.episode?.podcast?.primaryColor {
                    if bgColor.isDark {
                        self?.downloadView?.tintColor = bgColor
                        self?.ellipsisButton?.tintColor = bgColor
                    } else {
                        self?.downloadView?.tintColor = primary
                        self?.ellipsisButton?.tintColor = primary
                    }
                }
            })
            .addDisposableTo(self.bag)
        }

        self.downloadView?.setActionForTap({ view, status in
            switch status {
            case .None:
                let downloader = FablerDownloadManager.sharedInstance
                downloader.downloadWithEpisode(episode)
                view.setIndicatorStatus(.Indeterminate)

                do {
                    let realm = try Realm()

                    self.token = realm.addNotificationBlock({ notification, realm in
                        self.setDownloadStatus()
                    })
                } catch {

                }
            case .Indeterminate:
                fallthrough
            case .Running:
                episode.download?.cancel()
                view.setIndicatorStatus(.None)
                self.token?.stop()
                self.token = nil
            case .Completed:
                break
            }
        })

        self.setDownloadStatus()
    }

    func setDownloadStatus() {
        if let episode = self.episode {

            self.downloadView?.hidden = false

            if episode.download == nil {
                self.downloadView?.setIndicatorStatus(.None)
            } else {
                switch episode.download!.state {
                case .Unknown:
                    fallthrough
                case .Waiting:
                    self.downloadView?.setIndicatorStatus(.Indeterminate)
                case .Pausing:
                    fallthrough
                case .Paused:
                    fallthrough
                case .Failed:
                    fallthrough
                case .Cancelled:
                    self.downloadView?.setIndicatorStatus(.None)
                case .Downloading:
                    self.downloadView?.setIndicatorStatus(.Running)
                    if let fraction = self.episode?.download?.fractionCompleted {
                        self.downloadView?.setProgress(fraction, animated: true)
                    }
                case .Completed:
                    self.downloadView?.hidden = true
                    token?.stop()
                    token = nil
                }
            }
        }
    }

    // MARK: - UITableViewCell functions

    deinit {
        self.token?.stop()
        self.token = nil
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
