//
//  LargePlayerViewController.swift
//  Fabler
//
//  Created by Christopher Day on 11/13/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import AVFoundation

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
    @IBOutlet weak var moreButton: UIButton?

    // MARK: - IBActions

    @IBAction func moreButtonPressed(sender: AnyObject) {
        guard let episode = self.player?.episode else {
            return
        }

        let actionController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)

        //
        // Cancel
        //
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        actionController.addAction(cancelAction)

        //
        // Comments
        //
        let commentAction = UIAlertAction(title: "Comments", style: .Default) { [weak self] (action) in
            if let episode = self?.player?.episode {
                self?.performSegueWithIdentifier("displayEpisodeSegue", sender: episode)
            }
        }
        actionController.addAction(commentAction)

        //
        // Save
        //
        let saveTitle: String
        if episode.saved {
            saveTitle = "Unsave Episode"
        } else {
            saveTitle = "Save Episode"
        }

        let saveAction = UIAlertAction(title: saveTitle, style: .Default) { [weak self] (action) in
            if let episode = self?.player?.episode {
                let service = EpisodeService()
                service.flipSaveForEpisode(episode)
            }
        }
        actionController.addAction(saveAction)

        self.presentViewController(actionController, animated: true, completion: nil)
    }

    @IBAction func rateButtonPressed(sender: AnyObject) {
        guard let player = self.player else {
            return
        }

        let currentRate = player.rate
        let nextRate = currentRate.nextRate

        player.setRate(nextRate)

        self.rateButton?.setTitle(nextRate.description, forState: .Normal)
    }

    @IBAction func doneButtonPressed(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }

    @IBAction func playButtonPressed(sender: AnyObject) {
        guard let player = self.player else {
            return
        }

        if player.playing {
            player.pausePlayback()
        } else {
            player.playPlayback()
        }
    }

    @IBAction func forwardButtonPressed(sender: AnyObject) {
        guard let current = playbackSlider?.value, let max = playbackSlider?.maximumValue, let player = self.player else {
            return
        }

        let next = (current + 15) >= max ? max : current + 15
        playbackSlider?.setValue(next, animated: true)
        player.setPlaybackTo(next)
    }

    @IBAction func rewindButtonPressed(sender: AnyObject) {
        guard let current = playbackSlider?.value, let min = playbackSlider?.minimumValue, let player = self.player else {
            return
        }

        let next = (current - 15) <= min ? min : current - 15
        playbackSlider?.setValue(next, animated: true)
        player.setPlaybackTo(next)
    }

    @IBAction func playbackSliderChanged(sender: AnyObject) {
        guard let player = self.player, let slider = sender as? UISlider else {
            return
        }

        player.setPlaybackTo(slider.value)
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

        if let podcast = self.player?.episode?.podcast {
            podcast.image { [weak self] (image) in
                self?.artImage?.image = image
            }
        }

        super.viewDidLoad()
    }

    override public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "displayEpisodeSegue" {
            if let navigator = segue.destinationViewController as? FablerNavigationController, let episode = sender as? Episode, let controller = navigator.topViewController as? EpisodeTableViewController {
                navigator.showPlayer = false
                controller.episode = episode
                controller.root = true
            }
        }
    }

    // MARK: - LargePlayerViewController methods

    func updateOutlets() {
        self.player = FablerPlayer.sharedInstance

        guard let player = self.player else {
            return
        }

        titleLabel?.text = player.episode?.title

        if player.playing {
            playButton?.setImage(UIImage(named: "pause"), forState: .Normal)
        } else {
            playButton?.setImage(UIImage(named: "play"), forState: .Normal)
        }

        self.rateButton?.setTitle(player.rate.description, forState: .Normal)

        updatePlayerProgress(player.getCurrentDuration(), current: player.getCurrentTime())
    }

    func updatePlayerProgress(duration: Float, current: Float) {
        let actualDuration: Float
        if duration.isNaN {
            actualDuration = 0.0
        } else {
            actualDuration = duration
        }

        let actualCurrent: Float
        if current.isNaN {
            actualCurrent = 0.0
        } else {
            actualCurrent = current
        }

        guard actualCurrent <= actualDuration else {
            return
        }

        let currentNSDate = NSDate.init(timeIntervalSince1970: Double(actualCurrent))
        let durationNSDate = NSDate.init(timeIntervalSince1970: Double(actualDuration))
        let formatter = NSDateFormatter()
        formatter.timeZone = NSTimeZone(abbreviation: "UTC")
        formatter.dateFormat = "HH:mm:ss"

        currentTimeLabel?.text = formatter.stringFromDate(currentNSDate)
        durationLabel?.text = formatter.stringFromDate(durationNSDate)

        if let highlighted = playbackSlider?.highlighted {
            if !highlighted {
                playbackSlider?.maximumValue = actualDuration
                playbackSlider?.minimumValue = 0.0
                playbackSlider?.setValue(actualCurrent, animated: true)
            }
        }
    }
}
