//
//  ColorSpaceNodes.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI


// MARK: - Apply Adobe Camera Raw Curve

struct ApplyAdobeCameraRawCurveNode: FilterNode {
	let convertToNeg: Bool

	func apply(to input: CIImage) -> CIImage {
		if !convertToNeg { // Only apply if convert to neg is false
			var processImage = input
			processImage = processImage.LogC2Lin()
			processImage = processImage.awg3ToAdobeRGB()
//			processImage = processImage.gamutMap() // Using built in gamut mapping now
			processImage = processImage.toneMapLin()
			processImage = processImage.encodeGamma22()
			processImage = processImage.applyCameraRawCurve()
			
			return processImage
		} else {
			return input
		}
	}
}


