//
//  ScanNodes.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//


import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI





struct OffsetNode: FilterNode {
	let applyScanMode: Bool
	let offsetRGB: Float
	let offsetRed: Float
	let offsetGreen: Float
	let offsetBlue: Float
	
	func apply(to input: CIImage) -> CIImage {

		
		if applyScanMode {

            let rgb = offsetRGB / 400.0
            let r = ((offsetRed - 68.0) / 400.0) / 3.0
            let g = ((offsetGreen + 3.0) / 400.0) / 3.0
            let b = ((offsetBlue + 35.0) / 400.0) / 3.0
			let BW: Int = 0
			
			let kernel = CIColorKernelCache.shared.offsetRGB
			let result =  kernel.apply(
				extent: input.extent,
				roiCallback: { _, r in r },
				arguments: [input, rgb, r, g, b, BW]
			) ?? input
			
			return result.cropped(to: input.extent)
		} else {return input}
	}
	
}

struct ScanContrastNode: FilterNode {
	let applyScanMode: Bool
	let scanContrast: Float
	
	func apply(to input: CIImage) -> CIImage {
		if applyScanMode {
			
			let contrastNorm = scanContrast / 100.0
			let kernel = CIColorKernelCache.shared.scanContrast
			let result =  kernel.apply(
				extent: input.extent,
				roiCallback: { _, r in r },
				arguments: [input, contrastNorm]
			) ?? input
			return result.cropped(to: input.extent)
		} else {return input}
	}
}



struct Kodak2383Node: FilterNode {
	let blend: Float
	let applyScanMode: Bool
	let applyPFE: Bool
	
	func apply(to input: CIImage) -> CIImage {
		if applyScanMode && applyPFE {
			
			let display = input.CineonToDisplay()
			
			let resourceName = "2383v2"
			let lutApplied = input.applyLut(resourceName)
			
			let blended = display.blendWithOpacityPercent(lutApplied, blend)
			
			return blended.cropped(to: input.extent)
		} else {return input}
	}
}

struct Fujifilm3513Node: FilterNode {
	let blend: Float
	
	
	func apply(to input: CIImage) -> CIImage {
		
		
		
		
		
		
		return input
	}
}
