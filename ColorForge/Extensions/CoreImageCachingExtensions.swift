//
//  CoreImageCachingExtensions.swift
//  ColorForge
//
//  Created by admin on 24/06/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import simd


extension CIImage {
	
	
	func convertToCGImageAndCache() -> CIImage {
		let startTime = CFAbsoluteTimeGetCurrent()
		
		let backgroundContext = RenderingManager.shared.cacheContext
//		print("Caching extent: \(self.extent)")
		
		let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!
		guard let cgImage = backgroundContext.createCGImage(self, from: self.extent, format: .RGBAf, colorSpace: colorSpace) else {
			fatalError("Failed to create 32-bit float CGImage without color space")
		}
		
		let ciImage = CIImage(cgImage: cgImage)
		
		let endTime = CFAbsoluteTimeGetCurrent()
		let durationMs = (endTime - startTime) * 1000
//		print("convertToCGImageAndCache took \(String(format: "%.2f", durationMs)) ms")
		
		return ciImage
	}
 
	
	
	func convertToPixelBufferAndCache() -> CIImage {
		let startTime = CFAbsoluteTimeGetCurrent()
		
		let backgroundContext = RenderingManager.shared.exportContext
		print("Caching extent: \(self.extent)")
		
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

		// Lock base address for writing
		CVPixelBufferLockBaseAddress(buffer, [])
		backgroundContext.render(self, to: buffer, bounds: self.extent, colorSpace: nil)
		CVPixelBufferUnlockBaseAddress(buffer, [])

		let ciImage = CIImage(cvPixelBuffer: buffer)

		let endTime = CFAbsoluteTimeGetCurrent()
		let durationMs = (endTime - startTime) * 1000
		print("convertToPixelBufferAndCache took \(String(format: "%.2f", durationMs)) ms")

		return ciImage
	}
	
	
	
}
