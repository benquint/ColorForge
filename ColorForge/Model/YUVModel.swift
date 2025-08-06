//
//  YUVModel.swift
//  ColorForge
//
//  Created by admin on 09/06/2025.
//

import Foundation
import CoreImage
import CoreVideo
import SwiftUI
import simd


class YUVModel {
	
	init() {
		
		
	}
	
	// Shared singleton
	static let shared = YUVModel()
	
	// Global average for U and V values (x, y)
	private var globalAverage: SIMD2<Float> = .zero
	// Average values for warm U and V values (x, y)
	private var group1Average: SIMD2<Float> = .zero
	// Average values for cool U and V values (x, y)
	private var group2Average: SIMD2<Float> = .zero
	
	private var sourceCiImage: CIImage?
	private var inputBuffer: CVPixelBuffer?
	
	private var targetCiImage: CIImage?
	
	
	// Lut variables
	
	private var lutCIImage: CIImage?
	
	enum Dimension: Int {
		/// A very small color cube. May exhibit posterization.
		case four = 4
		
		/// This size is good enough for many applications using noisy or lower-quality input.
		case sixteen = 16
		
		case thirtyTwo = 32
		
		/// Higher quality. There is rarely a need to go beyond this setting.
		case sixtyFour = 64
		
		/// Excessive quality. Image is 4096x4096 and almost 35MB.
		case twoHundredFiftySix = 256
	}
	
	// MARK: - Sampling
	
//	func findHighestUV (_ input: CIImage) {
//		var yuv = input.RGBtoYUV()
//		let minYuv = input.findMin()
//		let maxYuv = input.findMax()
//		
//		let min = minYuv.sampleFloat3()
//		let max = maxYuv.sampleFloat3()
//		
//		print("YUV Minimums: \(min)")
//		print("YUV Maximums:")
//		
//		
//		
//		
//		let yUv = tempU.sampleFloat3()
//		let yuV = tempV.sampleFloat3()
//		let u = yUv.y
//		let v = yuV.z
//		
//		
//		
//		
//		
//	}
	

	func sampleUVGroups(_ inputImage: CIImage, _ sampleSize: Int) {
		let width = sampleSize
		let height = sampleSize
		let context = RenderingManager.shared.backgroundContext
		
		sourceCiImage = inputImage

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

		context.render(inputImage, to: buffer, bounds: inputImage.extent, colorSpace: nil)
		inputBuffer = buffer

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

		globalAverage = globalSum / Float(globalCount)
		
		// Warm colors
		group1Average = group1Count > 0 ? group1Sum / Float(group1Count) : SIMD2<Float>(0, 0)
		
		// Cool colors
		group2Average = group2Count > 0 ? group2Sum / Float(group2Count) : SIMD2<Float>(0, 0)

	}
	
	
	// MARK: - Warping
	
	
	
	// MARK: - Output result
	
	
	func createResultLut() {
		guard let source = sourceCiImage else {return}
		guard let target = targetCiImage else {return}
		
		
	}
	
	
	
	// MARK: - Generate HALD
	
	/// Creates a reference color cube image for the indicated size and writes it to disk.
	///
	/// - Parameters:
	///   - size: A value from the `ColorCubeImageCreator.Dimension` enum.
	///   - saveLocation: An optional URL for where to store the created image.
	///                   If left `nil`, the method places the image in the Documents folder in the app sandbox.
	/// - Returns: A `Bool` indicating the success or failure of the operation.
	static func createColorCube(size: Dimension, saveLocation: URL?) -> Bool {
		let cubeSize = size.rawValue
		
		/// Total number of pixels needed to represent all points in the cube.
		let pixels = cubeSize * cubeSize * cubeSize
		
		/// Square dimensions of the image that will store exactly enough pixels.
		//            let imageSize = Int(sqrt(Double(pixels)))
		
		let width = cubeSize * cubeSize
		let height = cubeSize
		
		
		/// We're only encoding RGB. No alpha.
		let channels = 3
		
		/// Total number of bytes required for all the data.
		let memorySize = pixels * channels
		
		/// Pre-calculate the square of the cube size.
		let cubeSizeSquared = cubeSize * cubeSize
		
		/// Storage for RGB values.
		let imageBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: memorySize)
		
		// Deallocate the buffer when done.
		defer { imageBuffer.deallocate() }
		
		/// Amount to vary the red, green, and blue channel values by at each step.
		let colorStep = 255.0 / Float(cubeSize - 1)
		
		/// Offset in the imageBuffer we're working on.
		for i in 0..<pixels {
			let offset = i * channels
			
			// Red value
			imageBuffer[offset] = UInt8(round(Float(i % cubeSize) * colorStep))
			
			// Green value
			imageBuffer[offset + 1] = UInt8(round(Float((i / cubeSize) % cubeSize) * colorStep))
			
			// Blue value
			imageBuffer[offset + 2] = UInt8(round(Float(i / cubeSizeSquared) * colorStep))
		}
		
		/// Data provider created with the calculated values in the imageBuffer.
		let callback: CGDataProviderReleaseDataCallback = { _, _, _ in }
		guard let dataProvider = CGDataProvider(dataInfo: nil, data: imageBuffer, size: memorySize, releaseData: callback) else {
			preconditionFailure("Couldn't create CGDataProvider.")
		}
		
		// Setup values for the CGImage.
		let bitsPerComponent = 8
		let bitsPerPixel = channels * bitsPerComponent
		//            let bytesPerRow = imageSize * channels
		let bytesPerRow = width * channels
		let displayP3ColorSpace = CGColorSpace(name: CGColorSpace.displayP3)!
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let alphaInfo = CGImageAlphaInfo.none
		let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: alphaInfo.rawValue)
		let renderingIntent: CGColorRenderingIntent = .defaultIntent
		
		// Attempt to process the buffer of bytes into an image.
		guard let imageRef = CGImage(width: width,
									 height: height,
									 bitsPerComponent: bitsPerComponent,
									 bitsPerPixel: bitsPerPixel,
									 bytesPerRow: bytesPerRow,
									 space: displayP3ColorSpace,
									 bitmapInfo: bitmapInfo,
									 provider: dataProvider,
									 decode: nil,
									 shouldInterpolate: false,
									 intent: renderingIntent) else {
			assertionFailure("Unable to create CGImage.")
			return false
		}
		
		let lutCIImage = CIImage(cgImage: imageRef)
		
		return true
//
//		/// The NSImage created from the buffer data.
//		let cubeImage = NSImage(cgImage: imageRef, size: NSSize(width: width, height: height))
//		
//		/// The PNG representation of the `cubeImage`.
//		guard let tiffData = cubeImage.tiffRepresentation,
//			  let bitmapImage = NSBitmapImageRep(data: tiffData),
//			  let imageData = bitmapImage.representation(using: .png, properties: [:]) else {
//			assertionFailure("Failed to generate PNG data.")
//			return false
//		}
//		
//		// Check that we can establish a URL for saving.
//		guard let imageURL = saveLocation ?? defaultLocationForSize(size: size) else {
//			assertionFailure("Can't access save location.")
//			return false
//		}
//		
//		// Try to write the image to disk.
//		do {
//			try imageData.write(to: imageURL, options: [])
//			print("Image successfully written to:", imageURL.absoluteString)
//			return true
//		} catch let error {
//			print("Failed to write image:", error)
//			return false
//		}
	}
	

	
}
