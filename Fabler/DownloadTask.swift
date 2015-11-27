//
//  DownloadTask.swift
//  Fabler
//
//  Created by Christopher Day on 11/23/15.
//  Copyright © 2015 Fabler. All rights reserved.
//

import RealmSwift

final class DownloadTask: Object {

    // MARK: - DownloadTask members

    dynamic var sessionIdentifier: String = ""
    dynamic var taskIdentifier: Int = 0
    dynamic var readBytes: Int64 = 0
    dynamic var totalBytes: Int64 = 0
    dynamic var expectedBytes: Int64 = 0
    dynamic var localPath: String = ""
    dynamic var objectId: Int = 0
    dynamic var objectType: String = ""

    // MARK: - Realm methods

}
