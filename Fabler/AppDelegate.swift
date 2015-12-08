//
//  AppDelegate.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

// swiftlint:disable variable_name

let Log: SwiftyBeaver.Type = {
    let log = SwiftyBeaver.self
    #if DEBUG
        let console = ConsoleDestination()
        console.detailOutput = true
        console.dateFormat = "MM/dd/yyyy hh:mma"
        log.addDestination(console)
    #else
    #endif

    return log
}()

// swiftlint:enable variable_name

import UIKit
import FBSDKCoreKit
import SwiftyBeaver

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var loginService: LoginService?
    var player: FablerPlayer?
    var downloader: DownloadManager?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Log.info("Application did finish launching.")

        self.loginService = LoginService()
        self.player = FablerPlayer()
        self.downloader = DownloadManager(identifier: "com.Fabler.Fabler.background")

        let result = FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)

        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let viewController: UIViewController
        if FBSDKAccessToken.currentAccessToken() == nil {
            viewController = storyboard.instantiateViewControllerWithIdentifier("login")
        } else {
            viewController = storyboard.instantiateViewControllerWithIdentifier("start")
        }

        self.window?.rootViewController = viewController;
        self.window?.makeKeyAndVisible()

        return result
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        self.downloader?.setBackgroundCompletionHandler(completionHandler)
    }
}
