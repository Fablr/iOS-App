//
//  FablerPlayer.swift
//  Fabler
//
//  Created by Christopher Day on 11/12/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

// swiftlint:disable variable_name

public let PlayerStartPlayback = "com.Fabler.PlayerStartPlayback"

// swiftlint:enable variable_name

import UIKit
import AVFoundation
import MediaPlayer
import Kingfisher

public enum PlaybackRate: Float {
    case Half = 0.5
    case Normal = 1.0
    case NormalPlus = 1.5
    case Double = 2.0

    var description: String {
        switch self {
        case Half:
            return "0.5X"
        case Normal:
            return "1X"
        case .NormalPlus:
            return "1.5X"
        case .Double:
            return "2X"
        }
    }

    var nextRate: PlaybackRate {
        switch self {
        case .Half:
            return .Normal
        case .Normal:
            return .NormalPlus
        case .NormalPlus:
            return .Double
        case .Double:
            return .Half
        }
    }
}

public class FablerPlayer: NSObject {

    // MARK: - singleton

    public static let sharedInstance = FablerPlayer()

    // MARK: - FablerPlayer properties

    public let smallPlayer: SmallPlayerViewController
    public let largePlayer: LargePlayerViewController
    private let audioPlayer: AVQueuePlayer = AVQueuePlayer()

    public var playing: Bool = false
    public var started: Bool = false

    public var rate: PlaybackRate = .Normal

    private var uiTimer: NSTimer?
    private var serviceTimer: NSTimer?

    private var image: UIImage?

    public var episode: Episode?

    public var upNext: [Episode] = []

    // MARK: - FablerPlayer methods

    override init() {
        //
        // Create player views
        //
        smallPlayer = SmallPlayerViewController(nibName: "SmallPlayer", bundle: nil)
        let width = UIScreen.mainScreen().bounds.size.width
        smallPlayer.view.frame = CGRect(x: 0, y: 0, width: width, height: 44)

        let storyboard = UIStoryboard(name: "LargePlayer", bundle: nil)
        if let controller = storyboard.instantiateViewControllerWithIdentifier("player") as? LargePlayerViewController {
            self.largePlayer = controller
        } else {
            fatalError("Unable to cast LargePlayer from storyboard.")
        }

        super.init()

        //
        // Register for playback finished notification
        //
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: mainQueue) { [weak self] (item) in
            if let player = self {
                if let current = player.audioPlayer.currentItem, let episode = player.episode {
                    let service = EpisodeService()
                    let currentTime = Double(current.duration.seconds)
                    service.setMarkForEpisode(episode, mark: currentTime, completed: true)
                }

                if !player.upNext.isEmpty {
                    player.episode = player.upNext.removeFirst()
                    player.insertCurrentEpisode()
                    player.playPlayback()
                }
            }
        }

        //
        // Set audio as active
        //
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

        //
        // Set up remote command center
        //
        let commandCenter = MPRemoteCommandCenter.sharedCommandCenter()

        commandCenter.playCommand.addTarget(self, action: "playPlayback")
        commandCenter.playCommand.enabled = true

        commandCenter.pauseCommand.addTarget(self, action: "pausePlayback")
        commandCenter.pauseCommand.enabled = true

        commandCenter.skipBackwardCommand.addTarget(self, action: "skipBackward")
        commandCenter.skipBackwardCommand.preferredIntervals = [15]
        commandCenter.skipBackwardCommand.enabled = true

        commandCenter.skipForwardCommand.addTarget(self, action: "skipForward")
        commandCenter.skipForwardCommand.preferredIntervals = [15]
        commandCenter.skipForwardCommand.enabled = true

        commandCenter.likeCommand.enabled = false
        commandCenter.ratingCommand.enabled = false
        commandCenter.bookmarkCommand.enabled = false
        commandCenter.seekBackwardCommand.enabled = false
        commandCenter.seekForwardCommand.enabled = false
        commandCenter.stopCommand.enabled = false
        commandCenter.togglePlayPauseCommand.enabled = false
        commandCenter.nextTrackCommand.enabled = false
        commandCenter.previousTrackCommand.enabled = false
        commandCenter.changePlaybackRateCommand.enabled = false
        commandCenter.dislikeCommand.enabled = false

        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
    }

    deinit {
        uiTimer?.invalidate()
        serviceTimer?.invalidate()
    }

    @objc private func updateCurrentTime() {
        if let current = audioPlayer.currentItem, let episode = self.episode {
            smallPlayer.updatePlayerProgress(Float(current.duration.seconds), current: Float(current.currentTime().seconds))
            largePlayer.updatePlayerProgress(Float(current.duration.seconds), current: Float(current.currentTime().seconds))

            var info: [String : AnyObject] = [MPMediaItemPropertyTitle: episode.title, MPMediaItemPropertyPlaybackDuration: current.duration.seconds, MPNowPlayingInfoPropertyElapsedPlaybackTime: current.currentTime().seconds]

            if let image = self.image {
                let art = MPMediaItemArtwork(image: image)
                info[MPMediaItemPropertyArtwork] = art
            }

            MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = info
        }
    }

    @objc private func updateService() {
        if let current = audioPlayer.currentItem, let episode = self.episode {
            let service = EpisodeService()
            let currentTime = Double(current.currentTime().seconds)
            service.setMarkForEpisode(episode, mark: currentTime, completed: false)
        }
    }

    public func startPlayback(episode: Episode) {
        guard self.episode != episode else {
            Log.info("Starting playback for existing episode.")

            self.playPlayback()
            return
        }

        self.episode = episode

        self.insertCurrentEpisode()
        setPlaybackTo(Float(episode.mark - 1))
        audioPlayer.play()

        playing = true
        started = true

        uiTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "updateCurrentTime", userInfo: nil, repeats: true)
        serviceTimer = NSTimer.scheduledTimerWithTimeInterval(5, target:  self, selector: "updateService", userInfo: nil, repeats: true)

        smallPlayer.updateOutlets()
        largePlayer.updateOutlets()

        NSNotificationCenter.defaultCenter().postNotificationName(PlayerStartPlayback, object: self)
    }

    public func addEpisodeToUpNext(episode: Episode) {
        if self.episode == nil {
            self.startPlayback(episode)
        } else {
            self.upNext.append(episode)
        }
    }

    private func insertCurrentEpisode() {
        if let episode = self.episode {
            var url: NSURL? = nil

            if let download = episode.download where download.state == .Completed {
                url = episode.localURL()
            } else {
                url = NSURL(string: episode.link)
            }

            if let url = url {
                let item = AVPlayerItem(URL:url)

                audioPlayer.removeAllItems()
                audioPlayer.insertItem(item, afterItem: nil)

                if let podcast = self.episode?.podcast, let url = NSURL(string: podcast.image) {
                    let manager = KingfisherManager.sharedManager
                    manager.retrieveImageWithURL(url, optionsInfo: nil, progressBlock: nil, completionHandler: { [weak self] (image, error, cacheType, url) in
                        if error == nil, let player = self {
                            player.image = image
                        }
                    })
                }

                MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [MPMediaItemPropertyTitle: episode.title]
            }
        } else {
            Log.warning("No episode currently set.")
        }
    }

    public func pausePlayback() {
        guard self.playing else {
            Log.warning("Episode is already paused.")
            return
        }

        playing = false
        audioPlayer.pause()

        uiTimer?.invalidate()
        serviceTimer?.invalidate()

        updateService()

        smallPlayer.updateOutlets()
        largePlayer.updateOutlets()
    }

    public func playPlayback() {
        guard !self.playing else {
            Log.warning("Episode is already playing.")
            return
        }

        playing = true
        audioPlayer.play()

        uiTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "updateCurrentTime", userInfo: nil, repeats: true)
        serviceTimer = NSTimer.scheduledTimerWithTimeInterval(5, target:  self, selector: "updateService", userInfo: nil, repeats: true)

        smallPlayer.updateOutlets()
        largePlayer.updateOutlets()
    }

    public func skipForward() {
        self.setPlaybackTo(min(self.getCurrentTime() + 15.0, self.getCurrentDuration()))
    }

    public func skipBackward() {
        self.setPlaybackTo(max(0.0, self.getCurrentTime() - 15.0))
    }

    public func setPlaybackTo(seconds: Float) {
        Log.info("Setting playback to \(seconds) seconds.")

        if audioPlayer.currentItem == nil {
            self.insertCurrentEpisode()
        }

        audioPlayer.seekToTime(CMTime(seconds: Double(seconds), preferredTimescale: 10))
        self.playPlayback()
    }

    public func setRate(rate: PlaybackRate) {
        self.rate = rate
        self.audioPlayer.rate = rate.rawValue
    }

    public func getCurrentDuration() -> Float {
        guard audioPlayer.currentItem != nil else {
            return 0.0
        }

        return Float(audioPlayer.currentItem!.duration.seconds)
    }

    public func getCurrentTime() -> Float {
        guard audioPlayer.currentItem != nil else {
            return 0.0
        }

        return Float(audioPlayer.currentTime().seconds)
    }

    public func registerPlaybackStarted(completion: () -> Void) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(PlayerStartPlayback, object: nil, queue: mainQueue) { _ in
            Log.info("Notifying that playback has started.")
            completion()
        }
    }
}
