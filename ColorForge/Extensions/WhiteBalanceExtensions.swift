//
//  WhiteBalanceExtensions.swift
//  ColorForge
//
//  Created by Ben Quinton on 21/05/2025.
//


/*
 White Balance related functions and extensions
 */

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import simd

extension CIImage {
	
	
	// Calculate temp and tint from XY
	func calculateTempAndTintFromXY(_ x: Float, _ y: Float) -> (Float, Float)? {
		let kernel = CIColorKernelCache.shared.calculateTempFromXY
		
		let pixel = CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))

		guard let outputImage = kernel.apply(
			extent: pixel.extent,
			roiCallback: { _, rect in rect },
			arguments: [pixel, x, y]
		) else {
			return nil
		}

		let tempTint = outputImage.sampleFloat2()
		return (tempTint.x, tempTint.y)
	}
	
	
	
}






