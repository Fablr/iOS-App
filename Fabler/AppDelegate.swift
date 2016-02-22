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
        console.minLevel = .Debug
        console.detailOutput = true
        console.dateFormat = "MM/dd/yyyy hh:mma"
        log.addDestination(console)
    #else
    #endif

    return log
}()

let ScratchRealmIdentifier = "fabler-scratch"

// swiftlint:enable variable_name

import UIKit
import FBSDKCoreKit
import SwiftyBeaver
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var userService: UserService?
    var player: FablerPlayer?
    var scratchRealm: Realm?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Log.info("Application did finish launching.")

        do {
            self.scratchRealm = try Realm(configuration: Realm.Configuration(inMemoryIdentifier: ScratchRealmIdentifier))
        } catch {
            Log.warning("Unable to create scratch Realm.")
        }

        if application.applicationState == UIApplicationState.Background {
            Log.debug("In background fetch mode.")

            return true
        }

        let notificationCenter = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()

        notificationCenter.addObserverForName(TokenDidChangeNotification, object: nil, queue: queue) { _ in
            let autoDownloader = FablerAutoDownload.sharedInstance
            autoDownloader.addTask(.CacheImages)
            autoDownloader.addTask(.CalculateEpisodes)
            autoDownloader.addTask(.DownloadEpisodes)
        }

        self.userService = UserService()
        self.player = FablerPlayer()

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
        FablerDownloadManager.sharedInstance.backgroundSessionCompletionHandler = completionHandler
    }
}
