//
//  YUVExtensions.swift
//  ColorForge
//
//  Created by admin on 09/06/2025.
//

import Foundation
import CoreVideo
import CoreImage
import simd


extension CIImage {
	
	
	// MARK: - Conversion
	
	// Converts RGB tp YUV
	/// Input range RGB 0-1
	/// Returns values in the range of:
	/// Y:  0-1
	/// U: -0.436 to 0.436
	/// V: -0.615 to 0.615
	func RGBtoYUV() -> CIImage {
		let kernel = CIColorKernelCache.shared.RGBtoYUV
		let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) ?? self
		return result.cropped(to: self.extent)
	}
	
	func YUVtoRGB() -> CIImage {
		let kernel = CIColorKernelCache.shared.YUVtoRGB
		let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) ?? self
		return result.cropped(to: self.extent)
	}
	
    func reducedY() -> CIImage {
        let kernel = CIColorKernelCache.shared.UVtoRGB
        let result = kernel.apply(
            extent: self.extent,
            roiCallback: { _, rect in rect },
            arguments: [self]
        ) ?? self
        return result.cropped(to: self.extent)
    }
	
	// MARK: - Sampling

	func sampleUVGroups(sampleSize: Int) -> (SIMD2<Float>, SIMD2<Float>, SIMD2<Float>) {
		let width = sampleSize
		let height = sampleSize
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
		let rowStride = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<Float>.size
		let channelStride = 4 // RGBA

		var globalSum = SIMD2<Float>(0, 0)
		var group1Sum = SIMD2<Float>(0, 0)
		var group2Sum = SIMD2<Float>(0, 0)

		var globalCount = 0
		var group1Count = 0
		var group2Count = 0

		for y in 0..<height {
			for x in 0..<width {
				let index = y * rowStride + x * channelStride
				let g = floatPointer[index + 1]
				let b = floatPointer[index + 2]
				let point = SIMD2<Float>(g, b)

				globalSum += point
				globalCount += 1

				let normX = Float(x) / Float(width)
				let normY = Float(y) / Float(height)

				if normY > normX {
					group1Sum += point
					group1Count += 1
				} else {
					group2Sum += point
					group2Count += 1
				}
			}
		}

		CVPixelBufferUnlockBaseAddress(buffer, .readOnly)

		let globalAvg = globalSum / Float(globalCount)
		let group1Avg = group1Count > 0 ? group1Sum / Float(group1Count) : SIMD2<Float>(0, 0)
		let group2Avg = group2Count > 0 ? group2Sum / Float(group2Count) : SIMD2<Float>(0, 0)

		return (globalAvg, group1Avg, group2Avg)
	}
	
	
	
	
	// MARK: - Sort Values
	
	
}
