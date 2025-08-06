//
//  URLExtensions.swift
//  ColorForge
//
//  Created by admin on 11/07/2025.
//

import CoreImage
import CoreGraphics
import AppKit

extension URL {
	/// Loads the image at the URL as a CIImage, supporting TIFF and PNG formats.
	/// Falls back to a blank 1×1 CIImage if loading fails.
	func asCIImage() -> CIImage {
		let supportedExtensions = ["tif", "tiff", "png"]
		guard supportedExtensions.contains(self.pathExtension.lowercased()) else {
			return CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
		}

		if let nsImage = NSImage(contentsOf: self),
		   let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
			return CIImage(cgImage: cgImage)
		}

		// Fallback to empty transparent image
		return CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
	}
}
