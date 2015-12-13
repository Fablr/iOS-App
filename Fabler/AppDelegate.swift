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
import AlamofireImage
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var userService: UserService?
    var player: FablerPlayer?
    var downloader: DownloadManager?
    var imageDownloader: ImageDownloader?
    var scratchRealm: Realm?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Log.info("Application did finish launching.")

        self.downloader = DownloadManager(identifier: "com.Fabler.Fabler.background")

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

        notificationCenter.addObserverForName(TokenDidChangeNotification, object: nil, queue: queue) { [weak self] (_) in
            if let app = self {
                app.fillCaches()
            }
        }

        self.userService = UserService()
        self.player = FablerPlayer()
        self.imageDownloader = ImageDownloader(downloadPrioritization: .LIFO)

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

    func fillCaches() {
        Log.info("Attempting pre-fetch and fill caches.")

        //
        // Fill image cache for subscribed podcasts
        //
        let podcastService = PodcastService()
        podcastService.getSubscribedPodcasts(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), completion: { [weak self] (podcasts) in
            Log.info("Caching subscribed podcast images.")

            if let downloader = self?.imageDownloader, let cache = downloader.imageCache {
                for podcast in podcasts {
                    if let _ = cache.imageWithIdentifier("\(podcast.podcastId)-header-blurred") {
                        continue
                    }

                    let id = podcast.podcastId

                    if let url = NSURL(string: podcast.image) {
                        let request = NSURLRequest(URL: url)

                        downloader.downloadImage(URLRequest: request, completion: { (response) in
                            if let image = response.result.value {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [weak self] in
                                    if let blurred = image.af_imageWithAppliedCoreImageFilter("CIGaussianBlur", filterParameters: ["inputRadius": 25.0]) {
                                        Log.info("Cached image at '\(id)-header-blurred'.")
                                        self?.imageDownloader?.imageCache?.addImage(blurred, withIdentifier: "\(id)-header-blurred")
                                    }
                                })
                            }
                        })
                    }
                }
            }
        })
        // END
    }
}
