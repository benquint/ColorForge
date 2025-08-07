//
//  Preferences.swift
//  ColorForge
//
//  Created by Ben Quinton on 07/08/2025.
//

import Foundation


class Preferences {
    private static let bookmarksKey = "WorkingDirectoryBookmarks"

    static var bookmarkedDirectories: [Data] {
        get {
            guard let rawData = UserDefaults.standard.data(forKey: bookmarksKey),
                  let array = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(rawData) as? [Data] else {
                return []
            }
            return array
        }
        set {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false) {
                UserDefaults.standard.set(data, forKey: bookmarksKey)
            } else {
                print("Failed to archive bookmark data array.")
            }
        }
    }
}
