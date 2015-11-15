//
//  File.swift
//  Fabler
//
//  Created by Christopher Day on 11/12/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class FablerNavigationController : UINavigationController {

    // MARK: - FablerNavigationController members

    var playerAdded: Bool = false

    // MARK: - UIViewController functions

    override func viewDidLoad(){
        super.viewDidLoad()

        let player = (UIApplication.sharedApplication().delegate as! AppDelegate).player!

        if player.started {
            self.playerAdded = true
            self.view.addSubview(player.smallPlayer.view)
        }

        player.registerPlaybackStarted { [weak self] in
            if let controller = self {
                if !controller.playerAdded {
                    controller.playerAdded = true
                    controller.view.addSubview(player.smallPlayer.view)
                }
            }
        }
    }
}
