//
//  LUTExtensions.swift
//  ColorForge
//
//  Created by admin on 07/06/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreVideo

extension CIImage {
	
	
	// MARK: - Apply LUT methods
	
	// No colorspace
	func applyLut(_ resourceName: String) -> CIImage {
		let lutModel = LutModel.shared

		guard let cachedLUT = lutModel.getCachedLUT(named: resourceName) else {
			print("LUT data for \(resourceName) not found in cache.")
			return self
		}

		guard let filter = CIFilter(name: "CIColorCube") else {
			print("Failed to create CIColorCube filter")
			return self
		}

		let actualLUTData = cachedLUT.data.suffix(from: 4)

		filter.setDefaults()
		filter.setValue(cachedLUT.dimension, forKey: "inputCubeDimension")
		filter.setValue(actualLUTData, forKey: "inputCubeData")
		filter.setValue(self, forKey: kCIInputImageKey)
		filter.setValue(false, forKey: "inputExtrapolate")

		guard let outputImage = filter.outputImage else {
			print("Failed to apply LUT. Image extent: \(self.extent)")
			return self
		}
		
		
		return outputImage
	}
	
	// Adobe RGB
	func applyLutColorSpace(_ resourceName: String) -> CIImage {
		let lutModel = LutModel.shared

		guard let cachedLUT = lutModel.getCachedLUT(named: resourceName) else {
			print("LUT data for \(resourceName) not found in cache.")
			return self
		}
		
		let actualLUTData = cachedLUT.data.suffix(from: 4)
		
		let colorCubeEffect = CIFilter.colorCubeWithColorSpace()
		colorCubeEffect.inputImage = self
		
		if let adobeRGB = CGColorSpace(name: CGColorSpace.adobeRGB1998) {
			colorCubeEffect.colorSpace = adobeRGB
		} else {
			print("❌ Failed to create Adobe RGB color space. Falling back to Device RGB.")
			colorCubeEffect.colorSpace = CGColorSpaceCreateDeviceRGB()
		}
		
		colorCubeEffect.cubeData = actualLUTData
		colorCubeEffect.cubeDimension = cachedLUT.dimension
		
		return colorCubeEffect.outputImage!
	}
    
    
    func applyLutData(_ data: Data) -> CIImage {
        let lutModel = LutModel.shared


        guard let filter = CIFilter(name: "CIColorCube") else {
            print("Failed to create CIColorCube filter")
            return self
        }

//        let actualLUTData = cachedLUT.data.suffix(from: 4)

        filter.setDefaults()
        filter.setValue(64, forKey: "inputCubeDimension")
        filter.setValue(data, forKey: "inputCubeData")
        filter.setValue(self, forKey: kCIInputImageKey)
        filter.setValue(true, forKey: "inputExtrapolate")

        guard let outputImage = filter.outputImage else {
            print("Failed to apply LUT. Image extent: \(self.extent)")
            return self
        }

        return outputImage
    }
	
	
	func applyCurveData(data: Data) -> CIImage {
		guard !data.isEmpty else {
			print("Empty curve data")
			return self
		}

		let colorCurvesFilter = CIFilter.colorCurves()
		colorCurvesFilter.inputImage = self
		colorCurvesFilter.curvesData = data
		colorCurvesFilter.curvesDomain = CIVector(x: 0.0, y: 1.0)
		colorCurvesFilter.colorSpace = CGColorSpaceCreateDeviceRGB()
		guard let result = colorCurvesFilter.outputImage else { return self }
		
		return result
	}
	
}

//// MARK: - Create HALD
//public func fromColorCubeData(_ cubeData: [Float32], size: Int) -> CIImage? {
//	let width = size
//	let height = size * size
//	let floatComponents = 4
//	let dataSize = width * height * floatComponents * MemoryLayout<Float32>.size
//
//	guard cubeData.count == size * size * size * floatComponents else {
//		print("Cube data size mismatch.")
//		return nil
//	}
//
//	var pixelBuffer: CVPixelBuffer?
//	let attrs: CFDictionary = [
//		kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary
//	] as CFDictionary
//
//	let status = CVPixelBufferCreate(
//		kCFAllocatorDefault,
//		width,
//		height,
//		kCVPixelFormatType_128RGBAFloat, // 32-bit float per component
//		attrs,
//		&pixelBuffer
//	)
//
//	guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
//		print("Failed to create pixel buffer.")
//		return nil
//	}
//
//	CVPixelBufferLockBaseAddress(buffer, [])
//	guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
//		CVPixelBufferUnlockBaseAddress(buffer, [])
//		return nil
//	}
//
//	let floatPtr = baseAddress.bindMemory(to: Float32.self, capacity: dataSize / 4)
//
//	var offset = 0
//	for g in 0..<size {
//		for b in 0..<size {
//			for r in 0..<size {
//				let index = ((b * size * size) + (g * size) + r) * 4
//				floatPtr[offset + 0] = cubeData[index + 0] // R
//				floatPtr[offset + 1] = cubeData[index + 1] // G
//				floatPtr[offset + 2] = cubeData[index + 2] // B
//				floatPtr[offset + 3] = cubeData[index + 3] // A
//				offset += 4
//			}
//		}
//	}
//
//	CVPixelBufferUnlockBaseAddress(buffer, [])
//	
//	let ciImage = CIImage(cvPixelBuffer: buffer, options: [.colorSpace: NSNull()])
//	
//	debugSave(ciImage)
//
//	// CIImage from CVPixelBuffer with nil color space
//	return ciImage
//}


