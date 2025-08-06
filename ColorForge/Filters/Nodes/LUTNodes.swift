//
//  LUTNodes.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI


// MARK: - Apply LUT with data
struct ApplyLUTNode: FilterNode {
	let lutName: String

	func apply(to input: CIImage) -> CIImage {
		let lutModel = LutModel.shared

		guard let cachedLUT = lutModel.getCachedLUT(named: lutName) else {
			print("LUT data for \(lutName) not found in cache.")
			return input
		}

		guard let filter = CIFilter(name: "CIColorCube") else {
			print("Failed to create CIColorCube filter")
			return input
		}

		let actualLUTData = cachedLUT.data.suffix(from: 4)

		filter.setDefaults()
		filter.setValue(cachedLUT.dimension, forKey: "inputCubeDimension")
		filter.setValue(actualLUTData, forKey: "inputCubeData")
		filter.setValue(input, forKey: kCIInputImageKey)
		filter.setValue(true, forKey: "inputExtrapolate")

		guard let outputImage = filter.outputImage else {
			print("Failed to apply LUT. Image extent: \(input.extent)")
			return input
		}

		return outputImage
	}
}


