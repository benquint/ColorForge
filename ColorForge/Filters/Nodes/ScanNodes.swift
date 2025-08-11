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
    let neg: Bool
	let applyScanMode: Bool
	let offsetRGB: Float
	let offsetRed: Float
	let offsetGreen: Float
	let offsetBlue: Float
	
	func apply(to input: CIImage) -> CIImage {
        guard neg else { return input }
		
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
    let neg: Bool
	let applyScanMode: Bool
	let scanContrast: Float
	
	func apply(to input: CIImage) -> CIImage {
        guard neg else { return input }
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


struct ScanLutNode: FilterNode {
    let neg: Bool
    let blend: Float
    let applyScanMode: Bool
    let applyPFE: Bool
    let apply2383: Bool
    let apply3513: Bool
    
    func apply(to input: CIImage) -> CIImage {
        guard neg else { return input }
        if applyScanMode && applyPFE {
            
            let display = input.CineonToDisplay()
            
            var resourceName = "2383v2"
            
            if apply3513 {
                resourceName = "3513v2"
            }
            
            let lutApplied = input.applyLut(resourceName)
            
            let blended = display.blendWithOpacityPercent(lutApplied, blend)
            
            return blended.cropped(to: input.extent)
        } else {return input}
    }
}


struct Kodak2383Node: FilterNode {
    let neg: Bool
	let blend: Float
	let applyScanMode: Bool
	let applyPFE: Bool
	
	func apply(to input: CIImage) -> CIImage {
        guard neg else { return input }
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
    let neg: Bool
    let blend: Float
    let applyScanMode: Bool
    let applyPFE: Bool
    
    func apply(to input: CIImage) -> CIImage {
        guard neg else { return input }
        if applyScanMode && applyPFE {
            
            let display = input.CineonToDisplay()
            
            let resourceName = "3513v2"
            let lutApplied = input.applyLut(resourceName)
            
            let blended = display.blendWithOpacityPercent(lutApplied, blend)
            
            return blended.cropped(to: input.extent)
        } else {return input}
    }
}
