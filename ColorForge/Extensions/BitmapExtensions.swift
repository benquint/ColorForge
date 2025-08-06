//
//  BitmapExtensions.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import CoreImage
import AppKit
import CoreGraphics

extension CIImage {
    

    
    
    func convertToNSImageSync() -> NSImage? {
        // Use your shared CIContext
        let context = RenderingManager.shared.mainImageContext
        
        // Create a CGImage from the CIImage
        guard let cgImage = context.createCGImage(self, from: self.extent) else {
            return nil
        }
        
        // Wrap it in an NSImage
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        return nsImage
    }

    
    func convertDebayeredToBuffer(_ context: CIContext) async -> CVPixelBuffer? {
        
        let width = Int(self.extent.width)
        let height = Int(self.extent.height)

        let attrs: [CFString: Any] = [
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_128RGBAFloat, // matches RGBAf format
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            fatalError("Failed to create CVPixelBuffer")
        }


        context.render(self, to: buffer, bounds: self.extent, colorSpace: nil)

        return buffer
    }
    
    func convertDebayeredToBufferSync() -> CVPixelBuffer? {
        let context = RenderingManager.shared.mainImageContext
        
        let width = Int(self.extent.width)
        let height = Int(self.extent.height)

        let attrs: [CFString: Any] = [
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_128RGBAFloat, // matches RGBAf format
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            fatalError("Failed to create CVPixelBuffer")
        }


        context.render(self, to: buffer, bounds: self.extent, colorSpace: nil)

        return buffer
    }


    
    func convertThumbToCGImageBatch(_ context: CIContext) async  -> CGImage? {
        let thumbScale = 500 / max(self.extent.width, self.extent.height)
        let thumbnail = self.transformed(by: CGAffineTransform(scaleX: thumbScale, y: thumbScale))

        guard let cgImage = context.createCGImage(self, from: self.extent) else {
            return nil
        }
        
        return cgImage
    }

    
}
