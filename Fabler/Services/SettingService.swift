//
//  SettingService.swift
//  Fabler
//
//  Created by Christopher Day on 3/17/16.
//  Copyright © 2016 Fabler. All rights reserved.
//

import RealmSwift

public class SettingService {


    // MARK: - SettingService API methods

    public func setLimitDownload(setting: Setting, limit: Bool) {
        do {
            let realm = try Realm()

            try realm.write {
                setting.limitDownload = limit
            }
        } catch {
            Log.error("Realm write failed")
        }
    }

    public func setLimitDownloadSize(setting: Setting, sizeInBytes: Int) {
        do {
            let realm = try Realm()

            try realm.write {
                setting.limitAmountInBytes = sizeInBytes
            }
        } catch {
            Log.error("Realm write failed")
        }
    }

    public func getSettingForCurrentUser() -> Setting? {
        let result: Setting?

        if let user = User.getCurrentUser() {
            result = self.getSettingForUser(user)
        } else {
            result = nil
        }

        return result
    }

    public func getSettingForUser(user: User) -> Setting? {
        var result: Setting? = nil

        do {
            let realm = try Realm()

            result = realm.objects(Setting).filter("user == %@", user).first

            if result == nil {
                result = Setting()

                result?.user = user

                try realm.write {
                    realm.create(Setting.self, value: result!, update: false)
                }
            }
        } catch {
            Log.error("Realm read failed")
        }

        return result
    }
}
