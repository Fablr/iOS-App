//
//  SyncEngine.swift
//  Fabler
//
//  Created by Christopher Day on 11/17/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import CoreData
import Alamofire

class DownloadManager {

    var queue: dispatch_queue_t {
        return dispatch_get_global_queue(QOS_CLASS_UTILITY, 0)
    }

    init() {
        
    }
}
