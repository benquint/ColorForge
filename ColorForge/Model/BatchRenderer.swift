//
//  BatchRenderer.swift
//  ColorForge
//
//  Created by admin on 30/07/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import AppKit
import ImageIO


class BatchRenderer {
	static let shared = BatchRenderer()
	
	let context1: CIContext
	let context2: CIContext
	let context3: CIContext
	let context4: CIContext
    let context5: CIContext
    let context6: CIContext
    let context7: CIContext
    let context8: CIContext
	let device: MTLDevice
	
	private init() {
		let adobeRGBColorSpace = CGColorSpace(name: CGColorSpace.adobeRGB1998)!
		
		// Main display context
		let options: [CIContextOption: Any] = [
            .workingColorSpace: NSNull(),
            .outputColorSpace: NSNull(),
            .name: "cacheContext",
            .outputPremultiplied: false,
            .useSoftwareRenderer: false,
            .workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
            .allowLowPower: false, // Use high-performance mode
            .highQualityDownsample: false, // Enable high-quality downsampling
            .priorityRequestLow: false, // Push to background
            .cacheIntermediates: false, // Cache intermediate results for performance
            .memoryTarget: 4_294_967_296 // 4gb
		]
        
		
		
		if let device = MTLCreateSystemDefaultDevice() {
			self.device = device
			self.context1 = CIContext(mtlDevice: device, options: options)
			self.context2 = CIContext(mtlDevice: device, options: options)
			self.context3 = CIContext(mtlDevice: device, options: options)
			self.context4 = CIContext(mtlDevice: device, options: options)
            self.context5 = CIContext(mtlDevice: device, options: options)
            self.context6 = CIContext(mtlDevice: device, options: options)
            self.context7 = CIContext(mtlDevice: device, options: options)
            self.context8 = CIContext(mtlDevice: device, options: options)
		} else {
			print("Falling back to default CIContext without Metal support.")
			self.device = MTLCreateSystemDefaultDevice()! // Fallback to ensure device is set
			self.context1 = CIContext(mtlDevice: device, options: options)
			self.context2 = CIContext(mtlDevice: device, options: options)
			self.context3 = CIContext(mtlDevice: device, options: options)
			self.context4 = CIContext(mtlDevice: device, options: options)
            self.context5 = CIContext(mtlDevice: device, options: options)
            self.context6 = CIContext(mtlDevice: device, options: options)
            self.context7 = CIContext(mtlDevice: device, options: options)
            self.context8 = CIContext(mtlDevice: device, options: options)
		}
	}
	
	
	// Converts a batch of CIImages into NSImages using 4 CIContexts concurrently.
	// Returns an array of (UUID, NSImage?) in the same order as input.
	func batchConvertToNSImage(_ images: [(UUID, CIImage)]) async -> [(UUID, NSImage?)] {
		await withTaskGroup(of: [(UUID, NSImage?)].self) { group in
			let chunkSize = max(1, (images.count + 3) / 4) // Split evenly into 4 batches
			let batches = stride(from: 0, to: images.count, by: chunkSize).map {
				Array(images[$0 ..< min($0 + chunkSize, images.count)])
			}
			
			let contexts = [context1, context2, context3, context4]
			let context = context1
			
			// Add one task per batch
			for (index, batch) in batches.enumerated() {
				
				
				group.addTask() {
					var results: [(UUID, NSImage?)] = []
					for (id, ciImage) in batch {
						let nsImage = await self.convertToNSImage(ciImage, context)
						results.append((id, nsImage))
					}
					return results
				}
			}
			
			// Collect results from all batches
			var allResults: [(UUID, NSImage?)] = []
			for await batchResults in group {
				allResults.append(contentsOf: batchResults)
			}
			
			// Preserve the original order of input images
			return images.map { id, _ in
				allResults.first(where: { $0.0 == id }) ?? (id, nil)
			}
		}
	}

	// Convert a single CIImage to NSImage using the given CIContext.
	private func convertToNSImage(_ input: CIImage, _ context: CIContext) async -> NSImage? {
		guard let cgImage = context.createCGImage(input, from: input.extent) else {
			return nil
		}
		let size = NSSize(width: cgImage.width, height: cgImage.height)
		return NSImage(cgImage: cgImage, size: size)
	}
	
	
}




