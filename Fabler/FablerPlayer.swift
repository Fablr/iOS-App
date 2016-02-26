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

public class FablerPlayer: NSObject {

    // MARK: - singleton

    public static let sharedInstance = FablerPlayer()

    // MARK: - FablerPlayer members

    public let smallPlayer: SmallPlayerViewController
    public let largePlayer: LargePlayerViewController
    private let audioPlayer: AVQueuePlayer

    public var playing: Bool
    public var started: Bool
    private var uiTimer: NSTimer?
    private var serviceTimer: NSTimer?

    public var episode: Episode?
    public var podcast: Podcast?

    // MARK: - FablerPlayer functions

    override init() {
        smallPlayer = SmallPlayerViewController(nibName: "SmallPlayer", bundle: nil)
        let width = UIScreen.mainScreen().bounds.size.width
        smallPlayer.view.frame = CGRect(x: 0, y: 0, width: width, height: 44)

        largePlayer = LargePlayerViewController(nibName: "LargePlayer", bundle: nil)
        largePlayer.modalPresentationStyle = .OverCurrentContext

        audioPlayer = AVQueuePlayer()

        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch {}

        playing = false
        started = false

        super.init()
    }

    deinit {
        uiTimer?.invalidate()
        serviceTimer?.invalidate()
    }

    @objc private func updateCurrentTime() {
        if let current = audioPlayer.currentItem {
            smallPlayer.updatePlayerProgress(Float(current.duration.seconds), current: Float(current.currentTime().seconds))
            largePlayer.updatePlayerProgress(Float(current.duration.seconds), current: Float(current.currentTime().seconds))
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
        self.podcast = episode.podcast

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

    private func insertCurrentEpisode() {
        if let episode = self.episode {
            let url = NSURL(string: episode.link)!
            let item = AVPlayerItem(URL:url)
            let notificationCenter = NSNotificationCenter.defaultCenter()
            let mainQueue = NSOperationQueue.mainQueue()

            notificationCenter.addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: mainQueue) { item in
                if let current = self.audioPlayer.currentItem {
                    let service = EpisodeService()
                    let currentTime = Double(current.duration.seconds)
                    service.setMarkForEpisode(episode, mark: currentTime, completed: true)
                }
            }

            audioPlayer.insertItem(item, afterItem: nil)
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

    public func setPlaybackTo(seconds: Float) {
        Log.info("Setting playback to \(seconds) seconds.")

        if audioPlayer.currentItem == nil {
            self.insertCurrentEpisode()
        }

        audioPlayer.seekToTime(CMTime(seconds: Double(seconds), preferredTimescale: 10))
        self.playPlayback()
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
