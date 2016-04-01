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

    // MARK: - FablerNavigationController methods

    func displaySmallPlayer() {
        if playerAdded && showPlayer {
            self.setToolbarHidden(false, animated: true)
            //let frame = self.toolbar.frame
            //self.toolbar.frame = CGRect(x: frame.origin.x, y: frame.origin.y - 100, width: frame.width, height: frame.height)
        }
    }

    func dismissSmallPlayer() {
        self.setToolbarHidden(true, animated: true)
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

        self.setDefaultNavigationBar()

        self.setToolbarHidden(true, animated: true)

        let player = FablerPlayer.sharedInstance

        if player.started && showPlayer {
            self.playerAdded = true
            self.setToolbarHidden(false, animated: true)
        }

        if showPlayer {
            player.registerPlaybackStarted { [weak self] in
                if let controller = self where !controller.playerAdded {
                    controller.playerAdded = true
                    controller.setToolbarHidden(false, animated: true)
                }
            }
        }
    }
}
