//
//  FablerTabBarController.swift
//  Fabler
//
//  Created by Christopher Day on 4/8/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import UIKit

public class FablerTabBarController: UITabBarController, UITabBarControllerDelegate {

    // MARK: - UIViewController methods

    public override func viewDidLoad() {
        super.viewDidLoad()

        self.tabBar.tintColor = FablerColors.Orange.Regular

        self.delegate = self
    }

    // MARK: - UITabBarControllerDelegate methods

    public func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if let navigationController = viewController as? FablerNavigationController, let userController = navigationController.viewControllers.first as? UserViewController {
            userController.user = User.getCurrentUser()
        }
    }
}
