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
            UserDefaults.standard.array(forKey: bookmarksKey) as? [Data] ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: bookmarksKey)
        }
    }
}
