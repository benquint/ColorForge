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
    
    func convertToNSImage() async -> NSImage? {
        // Use your shared CIContext
        let context = RenderingManager.shared.thumbnailContext
        
        // Create a CGImage from the CIImage
        guard let cgImage = context.createCGImage(self, from: self.extent) else {
            return nil
        }
        
        // Wrap it in an NSImage
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        return nsImage
    }
    
    
    
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
    
    func convertToNSImageBatch(_ context: CIContext) -> NSImage? {
        
        // Create a CGImage from the CIImage
        guard let cgImage = context.createCGImage(self, from: self.extent) else {
            return nil
        }
        
        // Wrap it in an NSImage
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        return nsImage
    }
    
    func convertDebayeredToCG() async -> CGImage? {
        let context = RenderingManager.shared.mainImageContext
        
        // Create a CGImage from the CIImage
        guard let cgImage = context.createCGImage(self, from: self.extent) else {
            return nil
        }
        return cgImage
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
    
    func convertToCGImage() async -> CGImage? {
        // Use your shared CIContext
        let context = RenderingManager.shared.cacheContext
        
        // Create a CGImage from the CIImage
        guard let cgImage = context.createCGImage(self, from: self.extent) else {
            return nil
        }
        
        return cgImage
    }
    
    
    func convertThumbToCGImage() async  -> CGImage? {
        let thumbScale = 500 / max(self.extent.width, self.extent.height)
        let thumbnail = self.transformed(by: CGAffineTransform(scaleX: thumbScale, y: thumbScale))
        guard let cgImage = await thumbnail.convertToCGImage() else {
            return nil
        }
        return cgImage
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

extension CGImage {
    
    func convertCGtoNSImage() -> NSImage {
        let size = NSSize(width: self.width, height: self.height)
        let nsImage = NSImage(cgImage: self, size: size)
        return nsImage
    }
    
}
