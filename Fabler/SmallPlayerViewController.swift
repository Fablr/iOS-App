//
//  SmallPlayerController.swift
//  Fabler
//
//  Created by Christopher Day on 11/12/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit

class SmallPlayerViewController : UIViewController {

    // MARK: - IBOutlets

    @IBOutlet weak var barView: UIView!

    // MARK: - UIViewController functions

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let tapRec = UITapGestureRecognizer()
        tapRec.addTarget(self, action: "barTapped")
        barView.addGestureRecognizer(tapRec)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - SmallPlayerViewController functions

    func barTapped() {
        let largePlayer = LargePlayerViewController(nibName: "LargePlayer", bundle: nil)
        largePlayer.modalPresentationStyle = .FullScreen

        if var view = (UIApplication.sharedApplication().delegate as! AppDelegate).window?.rootViewController {
            //
            // This will loop until we get to the most recently displayed view controller.
            //
            while ((view.presentedViewController) != nil) {
                view = view.presentedViewController!
            }

            view.presentViewController(largePlayer, animated: true, completion: nil)
        }
    }
}
