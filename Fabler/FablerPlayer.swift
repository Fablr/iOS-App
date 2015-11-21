//
//  FablerPlayer.swift
//  Fabler
//
//  Created by Christopher Day on 11/12/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import AVFoundation

public let PlayerStartPlayback = "com.Fabler.PlayerStartPlayback"

class FablerPlayer : NSObject {

    // MARK: - FablerPlayer members

    let smallPlayer: SmallPlayerViewController
    let largePlayer: LargePlayerViewController
    let audioPlayer: AVQueuePlayer

    var playing: Bool
    var started: Bool
    var uiTimer: NSTimer?
    var serviceTimer: NSTimer?

    var episode: Episode?

    // MARK: - FablerPlayer functions

    override init() {
        smallPlayer = SmallPlayerViewController(nibName: "SmallPlayer", bundle: nil)
        let width = UIScreen.mainScreen().bounds.size.width
        let height = UIScreen.mainScreen().bounds.size.height
        smallPlayer.view.frame = CGRectMake(0, (height - 50), width, 50)

        largePlayer = LargePlayerViewController(nibName: "LargePlayer", bundle: nil)
        largePlayer.modalPresentationStyle = .OverCurrentContext

        audioPlayer = AVQueuePlayer()

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
        if let current = audioPlayer.currentItem {
            let service = EpisodeService()
            let currentTime = Double(current.currentTime().seconds)
            service.setMarkForEpisode(self.episode!, mark: currentTime, completed: false)
        }
    }

    func startPlayback(episode: Episode) {
        guard self.episode != episode else {
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

    private func insertCurrentEpisode() {
        let url = NSURL(string: self.episode!.link)!
        let item = AVPlayerItem(URL:url)
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(AVPlayerItemDidPlayToEndTimeNotification, object: nil, queue: mainQueue) { item in
            if let current = self.audioPlayer.currentItem {
                let service = EpisodeService()
                let currentTime = Double(current.duration.seconds)
                service.setMarkForEpisode(self.episode!, mark: currentTime, completed: true)
            }
        }

        audioPlayer.insertItem(item, afterItem: nil)
    }

    func pausePlayback() {
        guard self.playing else {
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

    func playPlayback() {
        guard !self.playing else {
            return
        }

        playing = true
        audioPlayer.play()

        uiTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "updateCurrentTime", userInfo: nil, repeats: true)
        serviceTimer = NSTimer.scheduledTimerWithTimeInterval(5, target:  self, selector: "updateService", userInfo: nil, repeats: true)

        smallPlayer.updateOutlets()
        largePlayer.updateOutlets()
    }

    func setPlaybackTo(seconds: Float) {
        if audioPlayer.currentItem == nil {
            self.insertCurrentEpisode()
        }

        audioPlayer.seekToTime(CMTime(seconds: Double(seconds), preferredTimescale: 10))
        audioPlayer.play()
    }

    func getCurrentDuration() -> Float {
        guard audioPlayer.currentItem != nil else {
            return 0.0
        }

        return Float(audioPlayer.currentItem!.duration.seconds)
    }

    func getCurrentTime() -> Float {
        return Float(audioPlayer.currentTime().seconds)
    }

    func registerPlaybackStarted(completion: () -> Void) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(PlayerStartPlayback, object: nil, queue: mainQueue) { _ in
            completion()
        }
    }
}