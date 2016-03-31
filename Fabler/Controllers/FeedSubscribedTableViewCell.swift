//
//  FeedSubscribedTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 3/30/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import SwiftDate
import RxSwift
import RxCocoa

public protocol PerformsPodcastSegueDelegate {
    func performSegueToPodcast(podcast: Podcast)
}

public class FeedSubscribedTableViewCell: UITableViewCell {

    // MARK: - IBOutlets

    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var userButton: UIButton?
    @IBOutlet weak var podcastButton: UIButton?
    @IBOutlet weak var podcastLargeButton: UIButton?
    @IBOutlet weak var subscribeButton: UIButton?
    @IBOutlet weak var userImage: UIImageView?
    @IBOutlet weak var podcastImage: UIImageView?

    // MARK: - IBActions

    @IBAction func userButtonPressed(sender: AnyObject) {
        guard let user = self.event?.user else {
            return
        }

        self.userDelegate?.performSegueToUser(user)
    }

    @IBAction func podcastButtonPressed(sender: AnyObject) {
        guard let podcast = self.event?.podcast else {
            return
        }

        self.podcastDelegate?.performSegueToPodcast(podcast)
    }

    @IBAction func subscribeButtonPressed(sender: AnyObject) {
        guard let podcast = self.event?.podcast else {
            return
        }

        let service = PodcastService()
        service.subscribeToPodcast(podcast, subscribe: true) { [weak self] result in
            if !result {
                self?.subscribeButton?.hidden = false
            }
        }

        self.subscribeButton?.hidden = true
    }

    // MARK: - FeedSubscribedTableViewCell properties

    public var event: Event?
    public var userDelegate: PerformsUserSegueDelegate?
    public var podcastDelegate: PerformsPodcastSegueDelegate?

    private var bag: DisposeBag! = DisposeBag()

    // MARK: - FeedSubscribedTableViewCell methods

    public func setEventInstance(event: Event) {
        self.bag = nil
        self.bag = DisposeBag()

        guard event.eventType == .Subscribed else {
            fatalError("\(event.eventTypeRaw) passed to subscribed cell")
        }

        self.event = event

        guard let user = event.user, let podcast = event.podcast else {
            fatalError("Invalid event passed to subscribed cell")
        }

        self.userButton?.setTitle(user.userName, forState: .Normal)
        self.podcastButton?.setTitle(podcast.title, forState: .Normal)
        self.podcastLargeButton?.setTitle(podcast.title, forState: .Normal)

        if podcast.subscribed {
            self.subscribeButton?.hidden = true
        } else {
            self.subscribeButton?.hidden = false
        }

        user.profileImage { [weak self] image in
            self?.userImage?.image = image
        }

        podcast.image { [weak self] image in
            self?.podcastImage?.image = image
        }

        if let date = event.time.toNaturalString(NSDate(), inRegion: nil, style: FormatterStyle(style: .Full, max: 1)) {
            self.timeLabel?.text = "\(date) ago"
        } else {
            self.timeLabel?.text = ""
        }

        podcast
        .rx_observeWeakly(Bool.self, "primarySet")
        .subscribeNext { [weak self] color in
            if let primary = self?.event?.podcast?.primaryColor {
                self?.podcastLargeButton?.tintColor = primary
                self?.subscribeButton?.tintColor = primary
            }
        }
        .addDisposableTo(self.bag)
    }

    // MARK: - UIViewController methods

    deinit {
        self.bag = nil
    }
}
