//
//  ScaleExtensions.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import simd


extension CIImage {
	
	// Rotate 90 degrees clockwise
	func rotated90DegreesClockwise() -> CIImage {
		let transform = CGAffineTransform(translationX: self.extent.height, y: 0)
			.rotated(by: .pi / 2)
		let rotated = self.transformed(by: transform)
		let newExtent = CGRect(origin: .zero, size: CGSize(width: self.extent.height, height: self.extent.width))
		return rotated.cropped(to: newExtent)
	}
	
	
	
	// Apply Padding
	func applyPadding(_ padding: CGFloat) -> CIImage {
		let paddedWidth = self.extent.width - (padding * 2)
		let paddedHeight = self.extent.height - (padding * 2)
		let scaleX = paddedWidth / self.extent.width
		let scaleY = paddedHeight / self.extent.height
		let scale = min(scaleX, scaleY)
		let padded = self.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
		return padded
	}
	
	func scaleToViewAndPad(_ viewSize: CGSize, _ padding: CGFloat) -> CIImage {
		let viewWidth = viewSize.width
		let viewHeight = viewSize.height
		let imageHeight = self.extent.height
		
		let scalar = viewHeight / imageHeight
		var scaled = self.scaleToValue(scalar)
		if scaled.extent.width > viewWidth {
			let newScalar = viewWidth / scaled.extent.width
			scaled = scaled.scaleToValue(newScalar)
		}
		scaled = scaled.applyPadding(padding)
		return scaled
	}
	
	func scaleToValue(_ scaleVal: CGFloat) -> CIImage {
		let transform = CGAffineTransform(scaleX: scaleVal, y: scaleVal)
		let scaled = self.transformed(by: transform)
		return scaled
	}
	
	func scale_WP_BP_ByScalar(_ whiteScale: Float, _ blackScale: Float) -> CIImage {
		let kernel = CIColorKernelCache.shared.scaleWP_BP_withScalar
		guard let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self, whiteScale, blackScale]
		) else {
			print("Failed to convert image to capture one")
			return self}
		return result
	}
	
	
	// Scales the image down to 1×1 using an affine transform, returning a 1×1 `CIImage`.
	func scaleToOnePixel() -> CIImage {
		let scaleX = 1.0 / extent.width
		let scaleY = 1.0 / extent.height
		let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
		
		return transformed(by: transform)
			.cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
	}
	
	// Thumbnail Scale
	func scaleToThumbnail(thumnailScale: CGFloat) -> CIImage {
		let transform = CGAffineTransform(scaleX: thumnailScale, y: thumnailScale)
		
		return transformed(by: transform).cropped(to: self.extent)
	}
	
	// Display Scale (80% the size of the current display)
	func scaleToDisplay(displayScale: CGFloat) -> CIImage {
		let transform = CGAffineTransform(scaleX: displayScale, y: displayScale)
		let scaledImage = self.transformed(by: transform)
		return scaledImage
	}
	
	// Export Scale
	func scaleToExport(exportScale: CGFloat) -> CIImage {
		let transform = CGAffineTransform(scaleX: exportScale, y: exportScale)
		
		return transformed(by: transform).cropped(to: self.extent)
	}
	
	
	// MARK: - Bicubic
	
	func downAndUp(_ scaleDownVal: CGFloat) -> CIImage {
		
		let clamped = self.clampedToExtent()
		let scaledDown = clamped.bicubicScale(scaleDownVal)
		let scaleUpScalar = 1.0 / scaleDownVal
		let scaledUp = scaledDown.bicubicScale(scaleUpScalar)
		
		return scaledUp
    }
	
	func bicubicScale(_ scale: CGFloat) -> CIImage {
			let bicubicScaleFilter = CIFilter.bicubicScaleTransform()
			bicubicScaleFilter.inputImage = self
			bicubicScaleFilter.scale = Float(scale)
			bicubicScaleFilter.aspectRatio = 1.0
			bicubicScaleFilter.parameterB = 1.0
            bicubicScaleFilter.parameterC = 0.0 // soft, no halos
			guard let result = bicubicScaleFilter.outputImage else {return self}
			return result
	}
    
    
    func scaleLanczos(_ scale: CGFloat) -> CIImage {
        guard scale > 0 else { return self }

        guard let filter = CIFilter(name: "CILanczosScaleTransform") else {
            return self
        }
        
        filter.setValue(self, forKey: kCIInputImageKey)
        filter.setValue(scale, forKey: kCIInputScaleKey)
        filter.setValue(1.0, forKey: kCIInputAspectRatioKey) // Maintain aspect ratio

        return filter.outputImage ?? self
    }
    
    // MARK: - CROP
    
    func crop(_ cropRect: CGRect) -> CIImage {
        let crop = self.applyingFilter("CICrop", parameters: [
            "inputRectangle": CIVector(cgRect: cropRect)
        ])
        return crop
    }
}
