//
//  FablerNavigationController.swift
//  Fabler
//
//  Created by Christopher Day on 11/12/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import ChameleonFramework

class FablerNavigationController: UINavigationController {

    // MARK: - FablerNavigationController properties

    var playerAdded: Bool = false
    var showPlayer: Bool = true

    var currentStatusBarStyle: UIStatusBarStyle = .LightContent

    var playerView: UIView?

    // MARK: - FablerNavigationController methods

    func displaySmallPlayer() {
        if playerAdded && showPlayer {
            //self.setToolbarHidden(false, animated: true)
            self.playerView?.hidden = false
        }
    }

    func dismissSmallPlayer() {
        //self.setToolbarHidden(true, animated: true)
        self.playerView?.hidden = true
    }

    func setDefaultNavigationBar() {
        self.navigationBar.barStyle = UIBarStyle.Default
        self.navigationBar.barTintColor = FablerColors.Orange.Regular.flatten()
        self.navigationBar.translucent = false
        self.navigationBar.tintColor = UIColor(contrastingBlackOrWhiteColorOn: FablerColors.Orange.Regular.flatten(), isFlat: true)
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(contrastingBlackOrWhiteColorOn: FablerColors.Orange.Regular.flatten(), isFlat: true)]
        self.navigationBar.setTitleVerticalPositionAdjustment(0.0, forBarMetrics: UIBarMetrics.Default)
        self.setStatusBarStyle(UIStatusBarStyleContrast)
    }

    // MARK: - UIViewController methods

    override func viewDidLoad() {
        super.viewDidLoad()

        let player = FablerPlayer.sharedInstance

        self.playerView = player.smallPlayer.view
        self.playerView?.frame = CGRect(x: 0.0, y: UIScreen.mainScreen().bounds.size.height - 92.0, width: UIScreen.mainScreen().bounds.size.width, height: 44.0)
        self.view.addSubview(self.playerView!)

        self.setDefaultNavigationBar()

        self.dismissSmallPlayer()

        if showPlayer {
            player.registerPlaybackStarted { [weak self] in
                if let controller = self where !controller.playerAdded {
                    controller.playerAdded = true
                    self?.displaySmallPlayer()
                }
            }
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        let player = FablerPlayer.sharedInstance

        self.playerView = player.smallPlayer.view
        self.playerView?.frame = CGRect(x: 0.0, y: UIScreen.mainScreen().bounds.size.height - 92.0, width: UIScreen.mainScreen().bounds.size.width, height: 44.0)
        self.view.addSubview(self.playerView!)

        if player.started && showPlayer {
            self.playerAdded = true
            self.displaySmallPlayer()
        }
    }
}
