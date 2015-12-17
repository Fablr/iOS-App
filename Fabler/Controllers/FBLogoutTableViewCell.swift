//
//  FBLogoutTableViewCell.swift
//  Fabler
//
//  Created by Christopher Day on 12/16/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import FBSDKLoginKit

protocol PerformsLogoutSegueDelegate {
    func performLogoutSegue()
}

class FBLogoutTableViewCell: UITableViewCell, FBSDKLoginButtonDelegate {

    // MARK: - IBOutlets

    @IBOutlet weak var fbButton: FBSDKLoginButton?

    // MARK: - FBLogoutTableViewCell members

    var delegate: PerformsLogoutSegueDelegate?

    // MARK: - UITableViewCell functions

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // MARK: - FBSDKLoginButtonDelegate functions

    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        if error != nil {
            Log.error(error.localizedDescription)
        }
    }

    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        self.delegate?.performLogoutSegue()
    }
}
