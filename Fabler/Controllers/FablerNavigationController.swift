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

    // MARK: - FablerNavigationController members

    var playerAdded: Bool = false

    var currentStatusBarStyle: UIStatusBarStyle = .LightContent

    // MARK: - FablerNavigationController functions

    func displaySmallPlayer() {
        if playerAdded {
            self.setToolbarHidden(false, animated: true)
        }
    }

    func dismissSmallPlayer() {
        self.setToolbarHidden(true, animated: true)
    }

    func setDefaultNavigationBar() {
        self.navigationBar.barStyle = UIBarStyle.Default
        self.navigationBar.barTintColor = UIColor.fablerOrangeColor().flatten()
        self.navigationBar.translucent = false
        self.navigationBar.tintColor = UIColor(contrastingBlackOrWhiteColorOn: UIColor.fablerOrangeColor().flatten(), isFlat: true)
        self.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor(contrastingBlackOrWhiteColorOn: UIColor.fablerOrangeColor().flatten(), isFlat: true)]
        self.navigationBar.setTitleVerticalPositionAdjustment(0.0, forBarMetrics: UIBarMetrics.Default)
        self.setStatusBarStyle(UIStatusBarStyleContrast)
    }

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setDefaultNavigationBar()

        self.setToolbarHidden(true, animated: true)

        let player = FablerPlayer.sharedInstance

        if player.started {
            self.playerAdded = true
            self.setToolbarHidden(false, animated: true)
        }

        player.registerPlaybackStarted { [weak self] in
            if let controller = self {
                if !controller.playerAdded {
                    controller.playerAdded = true
                    controller.setToolbarHidden(false, animated: true)
                }
            }
        }
    }
}
