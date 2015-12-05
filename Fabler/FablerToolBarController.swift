//
//  FablerToolBarController.swift
//  Fabler
//
//  Created by Christopher Day on 12/4/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class FablerToolBarController: UIToolbar {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    var item: UIBarButtonItem?
    var flexItemLeft: UIBarButtonItem?
    var flexItemRight: UIBarButtonItem?

    override func setItems(items: [UIBarButtonItem]?, animated: Bool) {
        guard let delegate = UIApplication.sharedApplication().delegate as? AppDelegate else {
            return
        }

        if let player = delegate.player {
            if self.item == nil {
                let width = UIScreen.mainScreen().bounds.size.width
                self.item = UIBarButtonItem(customView: player.smallPlayer.view)
                self.item!.width = width
            }

            if self.flexItemLeft == nil {
                self.flexItemLeft = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: "")
            }

            if self.flexItemRight == nil {
                self.flexItemRight = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: "")
            }

            super.setItems([self.flexItemLeft!, self.item!, self.flexItemRight!], animated: false)
        }
    }
}
