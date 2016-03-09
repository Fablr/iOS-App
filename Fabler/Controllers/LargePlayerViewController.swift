//
//  LargePlayerViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/13/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import AVFoundation
import Kingfisher

public class LargePlayerViewController: UIViewController {

    // MARK: - LargePlayerViewController properties

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
    @IBOutlet weak var upNextButton: UIButton?
    @IBOutlet weak var rateButton: UIButton?

    // MARK: - IBActions

    @IBAction func rateButtonPressed(sender: AnyObject) {
        if let player = self.player {
            let currentRate = player.rate
            let nextRate = currentRate.nextRate

            player.setRate(nextRate)

            self.rateButton?.setTitle(nextRate.description, forState: .Normal)
        }
    }

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

    // MARK: - UIViewController methods

    override public func viewDidLoad() {
        self.playbackSlider?.continuous = false

        self.updateOutlets()

        let blurEffect = UIBlurEffect(style: .Light)
        let veView = UIVisualEffectView(effect: blurEffect)
        veView.frame = self.view.bounds
        self.view.backgroundColor = .clearColor()
        self.view.insertSubview(veView, atIndex: 0)

        playbackSlider?.maximumValue = 0.0
        playbackSlider?.minimumValue = 0.0

        if let podcast = self.player?.episode?.podcast, let url = NSURL(string: podcast.image) {
            let placeholder = UIImage()
            self.artImage?.kf_setImageWithURL(url, placeholderImage: placeholder)
        }

        super.viewDidLoad()
    }

    // MARK: - SmallPlayerViewController methods

    func updateOutlets() {
        self.player = FablerPlayer.sharedInstance

        if let player = self.player {
            titleLabel?.text = player.episode?.title

            if player.playing {
                playButton?.setImage(UIImage(named: "pause"), forState: .Normal)
            } else {
                playButton?.setImage(UIImage(named: "play"), forState: .Normal)
            }

            self.rateButton?.setTitle(player.rate.description, forState: .Normal)

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
