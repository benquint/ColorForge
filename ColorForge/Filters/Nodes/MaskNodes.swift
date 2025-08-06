//
//  MaskNodes.swift
//  ColorForge
//
//  Created by admin on 27/06/2025.
//

import Foundation
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI


struct LinearGradientNode: FilterNodeMaskable {
	var isMask: Bool
    var maskData: Any? = nil
	let drawMask: Bool
	let startPoint: CGPoint
	let endPoint: CGPoint
	
	
	func apply(to input: CIImage) -> CIImage {
		let linearGradient = CIFilter.linearGradient()
		linearGradient.point0 = startPoint
		linearGradient.point1 = endPoint
		linearGradient.color0 = CIColor(red: 1, green: 0, blue: 0, alpha: 1)
		linearGradient.color1 = CIColor(red: 1, green: 0, blue: 0, alpha: 0)
		guard let mask = linearGradient.outputImage else {
			print("Failed to generate linear gradient")
			return input
		}
		
		return mask.cropped(to: input.extent)
	}
	
	
}






