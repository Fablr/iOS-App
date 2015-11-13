//
//  FablerPlayer.swift
//  Fabler
//
//  Created by Christopher Day on 11/12/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

public let PlayerStartPlayback = "com.Fabler.PlayerStartPlayback"

class FablerPlayer {

    // MARK: - FablerPlayer members

    var smallPlayer: SmallPlayerViewController
    var playing: Bool

    // MARK: - FablerPlayer functions

    init() {
        smallPlayer = SmallPlayerViewController(nibName: "SmallPlayer", bundle: nil)
        let width = UIScreen.mainScreen().bounds.size.width
        let height = UIScreen.mainScreen().bounds.size.height
        smallPlayer.view.frame = CGRectMake(0, (height - 50), width, 50)

        playing = false
    }

    func startPlayback() {
        playing = true
        NSNotificationCenter.defaultCenter().postNotificationName(PlayerStartPlayback, object: self)
    }

    func registerPlaybackStarted(completion: () -> Void) {
        let notificationCenter = NSNotificationCenter.defaultCenter()
        let mainQueue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(PlayerStartPlayback, object: nil, queue: mainQueue) { _ in
            completion()
        }
    }
}