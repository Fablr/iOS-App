//
//  File.swift
//  Fabler
//
//  Created by Christopher Day on 11/12/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class FablerNavigationController: UINavigationController {

    // MARK: - FablerNavigationController members

    var playerAdded: Bool = false

    // MARK: - UIViewController functions

    override func viewDidLoad() {
        super.viewDidLoad()

        self.setToolbarHidden(true, animated: true)

        guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }

        if let player = delegate.player {
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
}
