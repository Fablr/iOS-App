//
//  SmallPlayerController.swift
//  Fabler
//
//  Created by Christopher Day on 11/12/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import AVFoundation

class SmallPlayerViewController: UIViewController {

    // MARK: - SmallPlayerViewController members

    weak var player: FablerPlayer?

    // MARK: - IBOutlets

    @IBOutlet weak var progressView: UIProgressView?
    @IBOutlet weak var barView: UIView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var playButton: UIButton?

    // MARK: - IBActions

    @IBAction func playButtonPressed(sender: AnyObject) {
        if let player = self.player {
            if player.playing {
                player.pausePlayback()
            } else {
                player.playPlayback()
            }
        }
    }

    // MARK: - UIViewController functions

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapRec = UITapGestureRecognizer()
        tapRec.addTarget(self, action: "barTapped")
        barView?.addGestureRecognizer(tapRec)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - SmallPlayerViewController functions

    func barTapped() {
        guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }

        if var view = delegate.window?.rootViewController {
            //
            // This will loop until we get to the most recently displayed view controller.
            //
            while (view.presentedViewController) != nil {
                view = view.presentedViewController!
            }

            if let largePlayerView = self.player?.largePlayer {
                view.presentViewController(largePlayerView, animated: true, completion: nil)
            }
        }
    }

    func updateOutlets() {
        guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }

        self.player = delegate.player

        if let player = self.player {
            titleLabel?.text = player.episode?.title

            if player.playing {
                playButton?.setImage(UIImage(named: "pause"), forState: .Normal)
            } else {
                playButton?.setImage(UIImage(named: "play"), forState: .Normal)
            }
        }
    }

    func updatePlayerProgress(duration: Float, current: Float) {
        let progress = current / duration
        progressView?.setProgress(Float(progress), animated: true)
    }
}
