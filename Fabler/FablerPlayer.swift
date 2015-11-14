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
    var timer: NSTimer?

    weak var episode: Episode?

    // MARK: - FablerPlayer functions

    override init() {
        smallPlayer = SmallPlayerViewController(nibName: "SmallPlayer", bundle: nil)
        let width = UIScreen.mainScreen().bounds.size.width
        let height = UIScreen.mainScreen().bounds.size.height
        smallPlayer.view.frame = CGRectMake(0, (height - 50), width, 50)

        largePlayer = LargePlayerViewController(nibName: "LargePlayer", bundle: nil)
        largePlayer.modalPresentationStyle = .FullScreen

        audioPlayer = AVQueuePlayer()

        playing = false

        super.init()
    }

    deinit {
        timer?.invalidate()
    }

    func updateCurrentTime() {
        if let current = audioPlayer.currentItem {
            smallPlayer.updatePlayerProgress(current.duration, current: current.currentTime())
        }
    }

    func startPlayback(episode: Episode) {
        if let url = NSURL(string: episode.link) {
            let item = AVPlayerItem(URL: url)

            audioPlayer.insertItem(item, afterItem: nil)
            audioPlayer.play()

            playing = true
            self.episode = episode

            timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "updateCurrentTime", userInfo: nil, repeats: true)

            smallPlayer.updateOutlets()

            NSNotificationCenter.defaultCenter().postNotificationName(PlayerStartPlayback, object: self)
        }
    }

    func pausePlayback() {
        playing = false
        audioPlayer.pause()
        timer?.invalidate()
        smallPlayer.updateOutlets()
    }

    func playPlayback() {
        playing = true
        audioPlayer.play()
        timer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: "updateCurrentTime", userInfo: nil, repeats: true)
        smallPlayer.updateOutlets()
    }

    func registerPlaybackStarted(completion: () -> Void) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(PlayerStartPlayback, object: nil, queue: mainQueue) { _ in
            completion()
        }
    }
}