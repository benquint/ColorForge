//
//  SamModel.swift
//  ColorForge
//
//  Created by Ben Quinton on 07/08/2025.
//

import Foundation
import CoreImage
import AppKit

class SamModel: ObservableObject {
    static let shared = SamModel()
    
    init() {
        
    }
    
    @Published var addToMask: Bool = true
    @Published var subtractFromMask: Bool = false
    @Published var currentMaskCG: CGImage? = nil

    private var currentMask: CIImage? = nil

    func addMask(_ segmentation: SAMSegmentation) {
        var mask = CIImage.black
        let newMask = segmentation.mask

        print("Received new segmentation mask with extent: \(newMask.extent)")

        if self.currentMask == nil {
            print("No existing mask. Initializing with black mask cropped to new extent.")
            mask = CIImage.black.cropped(to: newMask.extent)
        } else if let currentMask = self.currentMask {
            print("Existing mask found. Adding new mask to current mask.")
            mask = currentMask
        }

        // Perform the add operation
        mask = mask.add(newMask)
        print("Combined mask extent: \(mask.extent)")

        let context = RenderingManager.shared.mainImageContext

        // Try to create a CGImage from the CIImage
        if let cgImage = context.createCGImage(mask, from: mask.extent) {
            print("Successfully created CGImage from combined mask.")
            currentMaskCG = cgImage
            self.currentMask = mask // <- Persist the CIImage for future additions
        } else {
            print("Failed to create CGImage from combined mask.")
        }
    }
}
