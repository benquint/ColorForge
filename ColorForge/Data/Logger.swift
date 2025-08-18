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
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        logURL = documentsPath.appendingPathComponent("ColorForge.log")
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
