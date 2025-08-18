//
//  Logger.swift
//  ColorForge
//
//  Created by Ben Quinton on 18/08/2025.
//

import Foundation

class LogModel {
    static let shared = LogModel()
    private let logURL: URL
    
    init() {
        let fileManager = FileManager.default
        
        do {
            let appSupport = try fileManager.url(for: .applicationSupportDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true)
            
            // Step 2: Define folder structure
            let appFolder = appSupport.appendingPathComponent("ColorForge")
            let appDataFolder = appFolder.appendingPathComponent("AppData")
            
            // Create the folders if they don't exist
            if !fileManager.fileExists(atPath: appDataFolder.path) {
                try fileManager.createDirectory(at: appDataFolder,
                                              withIntermediateDirectories: true,
                                              attributes: nil)
            }
            
            // Change to save in applicationSupport/ColorForge/AppData
            logURL = appDataFolder.appendingPathComponent("ColorForge.log")
            
        } catch {
            // Fallback to documents directory if anything fails
            NSLog("Failed to create app support directory: \(error)")
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            logURL = documentsPath.appendingPathComponent("ColorForge.log")
        }
    }
    
    func log(_ message: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logMessage = "[\(timestamp)] \(message)\n"
        
        // Console output
        Swift.print(logMessage, terminator: "")
        
        // File output
        do {
            if FileManager.default.fileExists(atPath: logURL.path) {
                let fileHandle = try FileHandle(forWritingTo: logURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(logMessage.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            } else {
                try logMessage.write(to: logURL, atomically: true, encoding: .utf8)
            }
        } catch {
            NSLog("Log write failed: \(error)")
        }
    }
}
