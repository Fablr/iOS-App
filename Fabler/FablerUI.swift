//
//  FablerUI.swift
//  Fabler
//
//  Created by Christopher Day on 12/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Foundation

extension UIColor {
    static func fablerOrangeColor() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 144.0/255.0, blue: 50.0/255.0, alpha: 1.0)
    }

    static func washedOutFablerOrangeColor() -> UIColor {
        return UIColor(red: 231.0/255.0, green: 210.0/255.0, blue: 198.0/255.0, alpha: 1.0)
    }
}

func sizeStringFrom(bytes: Int) -> String {
    let result: String

    let gigs = bytes / 1048576
    let megs = bytes / 1024

    if gigs > 0 {
        result = "\(gigs)GB"
    } else if megs > 0 {
        result = "\(megs)MB"
    } else {
        result = "\(bytes)B"
    }

    return result
}
