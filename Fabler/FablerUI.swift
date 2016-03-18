//
//  FablerUI.swift
//  Fabler
//
//  Created by Christopher Day on 12/8/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import UIKit
import Foundation
import Eureka

extension UIColor {
    static func fablerOrangeColor() -> UIColor {
        return UIColor(red: 255.0/255.0, green: 144.0/255.0, blue: 50.0/255.0, alpha: 1.0)
    }

    static func washedOutFablerOrangeColor() -> UIColor {
        return UIColor(red: 231.0/255.0, green: 210.0/255.0, blue: 198.0/255.0, alpha: 1.0)
    }
}

extension Int {
    func format(format: String) -> String {
        return String(format: "%\(format)d", self)
    }
}

extension Float {
    func format(format: String) -> String {
        return String(format: "%\(format)f", self)
    }
}


func sizeStringFrom(bytes: Int) -> String {
    let result: String

    let fBytes = Float(bytes)

    let gigs = fBytes / 1073741824.0
    let megs = fBytes / 1048576.0
    let kils = fBytes / 1024.0

    if Int(gigs) > 0 {
        result = "\(gigs.format(".1"))GB"
    } else if Int(megs) > 0 {
        result = "\(megs.format(".1"))MB"
    } else if Int(kils) > 0 {
        result = "\(kils.format(".1"))KB"
    } else {
        result = "\(bytes)B"
    }

    return result
}
