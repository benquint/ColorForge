//
//  AppDelegate.swift
//  ColorForge
//
//  Created by Ben Quinton on 07/08/2025.
//

import Foundation
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        DataModel.shared.saveAllImageItemsToDisk()
    }
}
