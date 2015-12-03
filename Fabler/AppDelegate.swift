//
//  AppDelegate.swift
//  Fabler
//
//  Created by Christopher Day on 10/28/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

// swiftlint:disable variable_name

let Log: XCGLogger = {
    let log = XCGLogger.defaultInstance()
#if DEBUG
    log.setup(.Debug, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil, fileLogLevel: .Debug)
#else
    log.setup(.Severe, showThreadName: true, showLogLevel: true, showFileNames: true, showLineNumbers: true, writeToFile: nil)
#endif

    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "MM/dd/yyyy hh:mma"
    dateFormatter.locale = NSLocale.currentLocale()
    log.dateFormatter = dateFormatter

    return log
}()

// swiftlint:enable variable_name

import UIKit
import FBSDKCoreKit
import XCGLogger

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

        return FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }

    func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        self.downloader?.setBackgroundCompletionHandler(completionHandler)
    }
}
