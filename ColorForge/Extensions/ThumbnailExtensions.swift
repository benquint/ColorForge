//
//  ThumbnailExtensions.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import Foundation
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI


extension CIImage {
	
	// Render thumbnail to NSImage
	func renderThumb() -> NSImage? {
		let context = RenderingManager.shared.thumbnailContext
		let thumbScale: CGFloat = 0.3


		let scaledImage = self.transformed(by: CGAffineTransform(scaleX: thumbScale, y: thumbScale))

		guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
			return nil
		}

		let nsImage = NSImage(cgImage: cgImage, size: scaledImage.extent.size)
		return nsImage
	}
	
	
	
	
	
}

extension NSImage {
	/// Saves the NSImage as a PNG to the temporary directory.
	/// - Parameter name: The filename (without extension) to use for the saved image.
	/// - Returns: The URL where the image was saved, or `nil` on failure.
	func saveToTemp(name: String) -> URL? {
		guard let tiffData = self.tiffRepresentation,
			  let bitmap = NSBitmapImageRep(data: tiffData),
			  let pngData = bitmap.representation(using: .png, properties: [:]) else {
			print("Failed to create PNG data")
			return nil
		}
		
		let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("\(name).png")
		
		do {
			try pngData.write(to: tempURL)
			print("Thumbnail saved to: \(tempURL.path)")
			return tempURL
		} catch {
			print("Failed to write thumbnail: \(error)")
			return nil
		}
	}
}
