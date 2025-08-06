//
//  HapticModel.swift
//  ColorForge
//
//  Created by Ben Quinton on 06/08/2025.
//

import Foundation
import AppKit

class HapticModel {
    static let shared = HapticModel()
    
    
    
    public func short() {
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }
}
