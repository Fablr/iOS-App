//
//  FeedListenedTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 3/31/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit
import SwiftDate
import RxSwift
import RxCocoa

public class FeedListenedTableViewCell: UITableViewCell {

    private enum ActionButtonState: String {
        case Subscribe = "Subscribe"
        case Play = "Play"
    }

    // MARK: - IBOutlets

    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var userButton: UIButton?
    @IBOutlet weak var podcastButton: UIButton?
    @IBOutlet weak var episodeButton: UIButton?
    @IBOutlet weak var podcastLargeButton: UIButton?
    @IBOutlet weak var actionButton: UIButton?
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
        guard let podcast = self.event?.episode?.podcast else {
            return
        }

        self.podcastDelegate?.performSegueToPodcast(podcast)
    }

    @IBAction func episodeButtonPressed(sender: AnyObject) {
        guard let episode = self.event?.episode else {
            return
        }

        self.episodeDelegate?.performSegueToEpisode(episode)
    }

    @IBAction func actionButtonPressed(sender: AnyObject) {
        switch self.actionState {
        case .Play:
            guard let episode = self.event?.episode else {
                return
            }

            FablerPlayer.sharedInstance.startPlayback(episode)

        case .Subscribe:
            guard let podcast = self.event?.episode?.podcast else {
                return
            }

            let service = PodcastService()
            service.subscribeToPodcast(podcast, subscribe: true) { [weak self] result in
                if !result {
                    self?.actionState = .Subscribe
                    self?.actionButton?.setTitle(ActionButtonState.Subscribe.rawValue, forState: .Normal)
                }
            }

            self.actionState = .Play
            self.actionButton?.setTitle(self.actionState.rawValue, forState: .Normal)
        }
    }

    // MARK: - FeedListenedTableViewCell properties

    public var event: Event?
    public var userDelegate: PerformsUserSegueDelegate?
    public var podcastDelegate: PerformsPodcastSegueDelegate?
    public var episodeDelegate: PerformsEpisodeSegueDelegate?

    private var actionState: ActionButtonState = .Subscribe
    private var bag: DisposeBag! = DisposeBag()

    // MARK: - FeedListenedTableViewCell methods

    public func setEventInstance(event: Event) {
        self.bag = nil
        self.bag = DisposeBag()

        guard event.eventType == .Listened else {
            fatalError("\(event.eventTypeRaw) passed to subscribed cell")
        }

        self.event = event

        guard let user = event.user, let episode = event.episode, let podcast = episode.podcast else {
            fatalError("Invalid event passed to listened cell")
        }

        self.userButton?.setTitle(user.userName, forState: .Normal)
        self.podcastButton?.setTitle(podcast.title, forState: .Normal)
        self.podcastLargeButton?.setTitle(podcast.title, forState: .Normal)
        self.episodeButton?.setTitle(episode.title, forState: .Normal)

        user.profileImage { [weak self] image in
            self?.userImage?.image = image
        }

        podcast.image { [weak self] image in
            self?.podcastImage?.image = image
        }

        if podcast.subscribed {
            self.actionState = .Play
        } else {
            self.actionState = .Subscribe
        }

        self.actionButton?.setTitle(self.actionState.rawValue, forState: .Normal)

        if let date = event.time.toNaturalString(NSDate(), inRegion: nil, style: FormatterStyle(style: .Full, max: 1)) {
            self.timeLabel?.text = "\(date) ago"
        } else {
            self.timeLabel?.text = ""
        }

        podcast
        .rx_observeWeakly(Bool.self, "primarySet")
        .subscribeNext { [weak self] color in
            if let primary = self?.event?.episode?.podcast?.primaryColor {
                self?.podcastLargeButton?.tintColor = primary
                self?.episodeButton?.tintColor = primary
                self?.actionButton?.tintColor = primary
            }
        }
        .addDisposableTo(self.bag)
    }

    // MARK: - UIViewController methods

    deinit {
        self.bag = nil
    }
}
