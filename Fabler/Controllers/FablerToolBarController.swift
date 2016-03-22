//
//  FablerToolBarController.swift
//  Fabler
//
//  Created by Christopher Day on 12/4/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class FablerToolBarController: UIToolbar {

    // MARK: - FablerToolBarController properties

    var item: UIBarButtonItem?
    var flexItemLeft: UIBarButtonItem?
    var flexItemRight: UIBarButtonItem?

    // MARK: - UIToolbar methods

    override func setItems(items: [UIBarButtonItem]?, animated: Bool) {
        let player = FablerPlayer.sharedInstance

        if self.item == nil {
            let width = UIScreen.mainScreen().bounds.size.width
            self.item = UIBarButtonItem(customView: player.smallPlayer.view)
            self.item!.width = width
        }

        if self.flexItemLeft == nil {
            self.flexItemLeft = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: Selector())
        }

        if self.flexItemRight == nil {
            self.flexItemRight = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: Selector())
        }

        super.setItems([self.flexItemLeft!, self.item!, self.flexItemRight!], animated: false)
    }
}
