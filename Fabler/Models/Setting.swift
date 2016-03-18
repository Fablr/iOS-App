//
//  Setting.swift
//  Fabler
//
//  Created by Christopher Day on 3/17/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import RealmSwift

final public class Setting: Object {

    // MARK: - Setting properties

    dynamic var user: User?

    dynamic var limitDownload: Bool = false
    dynamic var limitAmountInBytes: Int = 1048576
}
