//
//  LargePlayerViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/13/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import AVFoundation

class LargePlayerViewController: UIViewController {

    // MARK: - LargePlayerViewController members

    weak var player: FablerPlayer?

    // MARK: - IBOutlets

    @IBOutlet weak var artImage: UIImageView?
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var playbackSlider: UISlider?
    @IBOutlet weak var rewindButton: UIButton?
    @IBOutlet weak var playButton: UIButton?
    @IBOutlet weak var forwardButton: UIButton?
    @IBOutlet weak var closeButton: UIButton?
    @IBOutlet weak var currentTimeLabel: UILabel?
    @IBOutlet weak var durationLabel: UILabel?

    // MARK: - IBActions

    @IBAction func doneButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func playButtonPressed(sender: AnyObject) {
        if let player = self.player {
            if player.playing {
                player.pausePlayback()
            } else {
                player.playPlayback()
            }
        }
    }

    @IBAction func forwardButtonPressed(sender: AnyObject) {
        if let current = playbackSlider?.value, let max = playbackSlider?.maximumValue, let player = self.player {
            let next = (current + 15) >= max ? max : current + 15
            playbackSlider?.setValue(next, animated: true)
            player.setPlaybackTo(next)
        }
    }

    @IBAction func rewindButtonPressed(sender: AnyObject) {
        if let current = playbackSlider?.value, let min = playbackSlider?.minimumValue, let player = self.player {
            let next = (current - 15) <= min ? min : current - 15
            playbackSlider?.setValue(next, animated: true)
            player.setPlaybackTo(next)
        }
    }

    @IBAction func playbackSliderChanged(sender: AnyObject) {
        if let player = self.player, let slider = sender as? UISlider {
            player.setPlaybackTo(slider.value)
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
        self.playbackSlider?.continuous = false

        self.updateOutlets()

        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
        let veView = UIVisualEffectView(effect: blurEffect)
        veView.frame = self.view.bounds
        self.view.backgroundColor = UIColor.clearColor()
        self.view.insertSubview(veView, atIndex: 0)

        playbackSlider?.maximumValue = 0.0
        playbackSlider?.minimumValue = 0.0

        if let podcast = self.player?.podcast, let url = NSURL(string: podcast.image) {
            let placeholder = UIImage()
            self.artImage?.af_setImageWithURL(url, placeholderImage: placeholder)
        }

        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - SmallPlayerViewController functions

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

            updatePlayerProgress(player.getCurrentDuration(), current: player.getCurrentTime())
        }
    }

    func updatePlayerProgress(var duration: Float, var current: Float) {
        if duration.isNaN {
            duration = 0.0
        }

        if current.isNaN {
            current = 0.0
        }

        guard current <= duration else {
            return
        }

        let currentNSDate = NSDate.init(timeIntervalSince1970: Double(current))
        let durationNSDate = NSDate.init(timeIntervalSince1970: Double(duration))
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(abbreviation: "UTC")
        formatter.dateFormat = "HH:mm:ss"

        currentTimeLabel?.text = formatter.stringFromDate(currentNSDate)
        durationLabel?.text = formatter.stringFromDate(durationNSDate)

        if let highlighted = playbackSlider?.highlighted {
            if !highlighted {
                playbackSlider?.maximumValue = duration
                playbackSlider?.minimumValue = 0.0
                playbackSlider?.setValue(current, animated: true)
            }
        }
    }
}
