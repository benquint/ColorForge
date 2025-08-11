//
//  CoreImageExtensions.swift
//  ColorForge
//
//  Created by Ben Quinton on 21/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import simd


// Returns luminosity from SIMD3 of RGB
extension SIMD3 where Scalar == Float {
	var luminosity: Float {
		// Assuming self = [R, G, B]
		return 0.299 * self.x + 0.587 * self.y + 0.114 * self.z
	}
}

extension CIImage {
	
	// MARK: - Min / Max / Average
	
	func findMin() -> CIImage {
		let filter = CIFilter.areaMinimum()
		filter.inputImage = self
		filter.extent = self.extent
		return filter.outputImage!
	}
	
	func findMax() -> CIImage {
		let filter = CIFilter.areaMaximum()
		filter.inputImage = self
		filter.extent = self.extent
		return filter.outputImage!
	}
    
    func findAveragePix() -> CIImage {
        let filter = CIFilter.areaAverage()
        filter.inputImage = self
        filter.extent = self.extent
        return filter.outputImage!
    }
    
	
	
	// MARK: - Clamping
	
	func clampedToInfiniteExtent() -> CIImage {
		let clampFilter = CIFilter.affineClamp()
		clampFilter.inputImage = self
		clampFilter.transform = .identity
		return clampFilter.outputImage!
	}

	// MARK: - Caching
	
	

	
	

	

    
	
	// MARK: - Sampling functions
	
	func findAverage() -> (Float, Float, Float) {
		let filter = CIFilter.areaAverage()
		filter.inputImage = self
		guard let output = filter.outputImage else {
			return (999, 999, 999)
		}
		
		let rgb = output.sampleFloat3()
		
		return (rgb.x, rgb.y, rgb.z)
	}
	
	
	func findBlackPoint() -> (Float, Float, Float) {
		let sampleSize: Int = 100
		let lab = self.RGBtoLAB()
		
		let scaleX = CGFloat(sampleSize) / self.extent.width
		let scaleY = CGFloat(sampleSize) / self.extent.height
		let downscaled = lab.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

		var bestScore = Float.infinity
		var bestColor: SIMD3<Float> = SIMD3<Float>(0, 0, 0)

		for row in 0..<sampleSize {
			for col in 0..<sampleSize {
				let origin = CGPoint(x: CGFloat(col), y: CGFloat(row))
				let tile = downscaled.cropped(to: CGRect(origin: origin, size: CGSize(width: 1, height: 1)))
				let color = tile.sampleFloat3() // Lab color

				let l = color.x
				let a = color.y
				let b = color.z

				let score = abs(l - 0.0) + abs(a - 0.5) + abs(b - 0.5)
				if score < bestScore {
					bestScore = score
					bestColor = color
				}
			}
		}

		// Reconstruct a 1x1 image with the best Lab color and convert back to RGB
		let bestPixel = CIImage(color: CIColor(red: CGFloat(bestColor.x), green: CGFloat(bestColor.y), blue: CGFloat(bestColor.z)))
			.cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
		let rgbPixel = bestPixel.LABtoRGB()

		let rgb = rgbPixel.sampleFloat3()
		return (rgb.x, rgb.y, rgb.z)
	}
	
	func findWhitePoint() -> (Float, Float, Float) {
		let sampleSize: CGFloat = 20.0
		let lab = self.RGBtoLAB()
		
		let scaleX = sampleSize / self.extent.width
		let scaleY = sampleSize / self.extent.height
		let downscaled = lab.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

		var bestScore = Float.infinity
		var bestColor: SIMD3<Float> = SIMD3<Float>(1, 1, 1)

		for row in 0..<20 {
			for col in 0..<20 {
				let origin = CGPoint(x: CGFloat(col), y: CGFloat(row))
				let tile = downscaled.cropped(to: CGRect(origin: origin, size: CGSize(width: 1, height: 1)))
				let color = tile.sampleFloat3() // Lab color

				let l = color.x
				let a = color.y
				let b = color.z

				let score = abs(l - 1.0) + abs(a - 0.5) + abs(b - 0.5)
				if score < bestScore {
					bestScore = score
					bestColor = color
				}
			}
		}

		// Reconstruct a 1x1 image with the best Lab color and convert back to RGB
		let bestPixel = CIImage(color: CIColor(red: CGFloat(bestColor.x), green: CGFloat(bestColor.y), blue: CGFloat(bestColor.z)))
			.cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
		let rgbPixel = bestPixel.LABtoRGB()

		let rgb = rgbPixel.sampleFloat3()
		return (rgb.x, rgb.y, rgb.z)
	}
	
	func findLightestAndDarkest() -> (SIMD3<Float>, SIMD3<Float>) {
		let sampleSize: CGFloat = 20.0
		let lab = self.RGBtoLAB()
		
		let scaleX = sampleSize / self.extent.width
		let scaleY = sampleSize / self.extent.height
		let downscaled = lab.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

		var minL: Float = Float.infinity
		var maxL: Float = -Float.infinity
		var darkestColor = SIMD3<Float>(0, 0, 0)
		var lightestColor = SIMD3<Float>(1, 1, 1)

		for row in 0..<20 {
			for col in 0..<20 {
				let origin = CGPoint(x: CGFloat(col), y: CGFloat(row))
				let tile = downscaled.cropped(to: CGRect(origin: origin, size: CGSize(width: 1, height: 1)))
				let labColor = tile.sampleFloat3()

				let l = labColor.x
				if l < minL {
					minL = l
					darkestColor = labColor
				}
				if l > maxL {
					maxL = l
					lightestColor = labColor
				}
			}
		}

		let darkCI = CIImage(color: CIColor(red: CGFloat(darkestColor.x), green: CGFloat(darkestColor.y), blue: CGFloat(darkestColor.z)))
			.cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
		let lightCI = CIImage(color: CIColor(red: CGFloat(lightestColor.x), green: CGFloat(lightestColor.y), blue: CGFloat(lightestColor.z)))
			.cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))

		let darkRGB = darkCI.LABtoRGB().sampleFloat3()
		let lightRGB = lightCI.LABtoRGB().sampleFloat3()

		return (darkRGB, lightRGB)
	}
	
	func sampleFloat1() -> Float {
		return self.sampleFloat4().x
	}
	
	func sampleFloat2() -> SIMD2<Float> {
		let f = self.sampleFloat4()
		return SIMD2<Float>(f.x, f.y)
	}
	
	func sampleFloat3() -> SIMD3<Float> {
		let f = self.sampleFloat4()
		return SIMD3<Float>(f.x, f.y, f.z)
	}
	
	func sampleFloat4() -> SIMD4<Float> {
		let width = 1
		let height = 1
		
		let context = RenderingManager.shared.backgroundContext
		
		var pixelBuffer: CVPixelBuffer?
		let attrs = [
			kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_128RGBAFloat,
			kCVPixelBufferWidthKey: width,
			kCVPixelBufferHeightKey: height
		] as CFDictionary
		
		let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height,
										 kCVPixelFormatType_128RGBAFloat,
										 attrs,
										 &pixelBuffer)
		
		guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
			fatalError("Failed to create pixel buffer")
		}
		
		context.render(self, to: buffer, bounds: self.extent, colorSpace: nil)
		
		CVPixelBufferLockBaseAddress(buffer, .readOnly)
		guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
			CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
			fatalError("Failed to get base address")
		}
		
		let floatPointer = baseAddress.assumingMemoryBound(to: Float.self)
		let result = SIMD4<Float>(floatPointer[0], floatPointer[1], floatPointer[2], floatPointer[3])
		CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
		
		return result
	}

	
	// MARK: - Save Extensions
	

    
}
