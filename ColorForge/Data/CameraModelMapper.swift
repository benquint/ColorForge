//
//  CameraModelMapper.swift
//  ColorForge
//
//  Created by Ben Quinton on 20/08/2025.
//

import Foundation


struct CameraModelMapping {
    let originalModel: String
    let targetModel: String
}

struct CameraModelMapper {
    static let mappings: [CameraModelMapping] = [
        CameraModelMapping(originalModel: "GFX100S II", targetModel: "GFX100S"),
        CameraModelMapping(originalModel: "GFX100 II", targetModel: "GFX100S"),
        
        // Add more mappings here as needed
        // CameraModelMapping(originalModel: "SomeCamera X", targetModel: "SomeCamera"),
    ]
    
    static func getTargetModel(for originalModel: String) -> String? {
        return mappings.first { $0.originalModel == originalModel }?.targetModel
    }
    
    static func needsModelChange(for model: String) -> Bool {
        return mappings.contains { $0.originalModel == model }
    }
}
