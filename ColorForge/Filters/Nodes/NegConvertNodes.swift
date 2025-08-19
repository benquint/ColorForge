//
//  NegConvertNodes.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI
import AppKit

// MARK: - Lut Nodes

struct FilmStockNode: FilterNode {
	let stockChoice: Int
	let convertToNeg: Bool
	
	func apply(to input: CIImage) -> CIImage {
		
		let filmStock: String
		switch stockChoice {
//        case 0: filmStock = "P400_2025"
		case 0: filmStock = "Pentax_P400_Oct24"
		case 1: filmStock = "Pentax645Z_P400_Plus1"
		case 2: filmStock = "Pentax645Z_P400_Plus2"
		case 3: filmStock = "Pentax645ZGold"
		case 4: filmStock = "Pentax645z_to_Tmax"
		default: filmStock = "Pentax_P400_Oct24"
		}
		
//		print("\n\nAttempting to apply film stock \(filmStock) for input value of \(stockChoice)\n\n")
		
		if convertToNeg {
			let neg = input.applyLut(filmStock)
            return neg.cropped(to: input.extent)
		} else {
			return input
		}
	}
}


// MARK: - Cineon Positive / Negative

struct DecodeNegativeNode: FilterNode {
	let convertToNeg: Bool
	let applyScanMode: Bool
	let stockChoice: Int
	
	func apply(to input: CIImage) -> CIImage {
        guard convertToNeg else {return input}
        
		if convertToNeg && !applyScanMode {
			let dMinRed: Float = 0.0
			let dMinGreen: Float = 0.0
			let dMinBlue: Float = 0.0
			let redDensity: Float = 0.0
			let greenDensity: Float = 0.0
			let blueDensity: Float = 0.0
			let choice = stockChoice + 1
			
			let kernel = CIColorKernelCache.shared.decodeNegative
			
			guard let negative = kernel.apply(
				extent: input.extent,
				roiCallback: { _, r in r },
				arguments: [input, dMinRed, dMinGreen, dMinBlue, redDensity, greenDensity, blueDensity, choice]
			) else {
				fatalError("GlobalSaturation kernel failed")
			}
            
            let gamma22 = negative.encodeGamma22()
			
            return gamma22.cropped(to: input.extent)
		} else {
			return input
		}
	}
}


// MARK: - MTF Curve
struct MTFParameters {
	// Red gains
	static let rGain_10LPM: Float = 0.95
	static let rGain_20LPM: Float = 0.80
	static let rGain_50LPM: Float = 0.45
	static let rGain_100LPM: Float = 0.15
	
	// Green gains
	static let gGain_10LPM: Float = 0.95
	static let gGain_20LPM: Float = 0.85
	static let gGain_50LPM: Float = 0.55
	static let gGain_100LPM: Float = 0.25
	
	// Blue gains
	static let bGain_10LPM: Float = 0.90
	static let bGain_20LPM: Float = 0.70
	static let bGain_50LPM: Float = 0.55
	static let bGain_100LPM: Float = 0.30
	
	// Sensor widths (in mm)
    static let largeFormat54Width: CGFloat = 127.0 // 5x4 - 9
	static let mediumFormatWidth: CGFloat = 60.0 // 0
	static let cropMediumSensorWidth: CGFloat = 43.8 // 1
	static let thirtyFiveWidth: CGFloat = 36.0 // 2
	static let halfFrameWidth: CGFloat = 18.0 // 3
	static let motionStandard35mm: CGFloat = 21.95
	static let motionSuper35mm: CGFloat = 24.89
	static let motion16mm: CGFloat = 10.26
	static let motion8mm: CGFloat = 4.8
	static let motionSuper8: CGFloat = 5.79
}

// Causing black squares in areas of high values
struct MTFCurveNode: FilterNode {
	let applyMTF: Bool
	let mtfAmount: Float
	let format: Int
	let applyGrain: Bool
	let exportMode: Bool
	let nativeLongEdge: Int
	let isExport: Bool
	let uiScale: Float
	
	func apply(to input: CIImage) -> CIImage {
		if applyMTF {
			
			var zoomScalar = ImageViewModel.shared.zoomScale
			
			
			let gateWidth: CGFloat
			switch format {
			case 0: gateWidth = MTFParameters.mediumFormatWidth              // 60.0 mm
			case 1: gateWidth = MTFParameters.cropMediumSensorWidth          // 43.8 mm
			case 2: gateWidth = MTFParameters.thirtyFiveWidth                // 36.0 mm
			case 3: gateWidth = MTFParameters.halfFrameWidth                 // 18.0 mm
			case 4: gateWidth = MTFParameters.motionStandard35mm             // 21.95 mm
			case 5: gateWidth = MTFParameters.motionSuper35mm                // 24.89 mm
			case 6: gateWidth = MTFParameters.motion16mm                     // 10.26 mm
			case 7: gateWidth = MTFParameters.motion8mm                      // 4.8 mm
			case 8: gateWidth = MTFParameters.motionSuper8                   // 5.79 mm
			case 9: gateWidth = MTFParameters.largeFormat54Width             // 127.0 mm
            case 10: gateWidth = 107.95
			default: gateWidth = MTFParameters.mediumFormatWidth             // Fallback
			}
			

			
            let safeInput = input.clampedToExtent()
			
			// Target size used for tests
			let targetPPMWidth: CGFloat = 600
			
			// Calculate the input MM size in pixels based on gatewidth
			let inputPPM = max(input.extent.width, input.extent.height) / gateWidth
			
			// Scale the input ppm to match that of the test target
			var imageScalar = targetPPMWidth / inputPPM
			
			if ImageViewModel.shared.isZoomed {
				imageScalar /= CGFloat(uiScale)
			}
			
			// Apply the scalar clamping at 1.0 to avoid upscaling
			let scalar100: CGFloat = min(max(0.4 * imageScalar, 0.0), 1.0)
			let scalar50:  CGFloat = min(max(0.2 * imageScalar, 0.0), 1.0)
			let scalar25:  CGFloat = min(max(0.12 * imageScalar, 0.0), 1.0)
			let scalar10:  CGFloat = min(max(0.05 * imageScalar, 0.0), 1.0)

			print("""

			Line Pairs Per MM Scalars:
			  100 LP/mm: \(scalar100)
			   50 LP/mm: \(scalar50)
			   25 LP/mm: \(scalar25)
			   10 LP/mm: \(scalar10)

			""")
			
			
			
	
			let scalar = (max(input.extent.width, input.extent.height) / CGFloat(nativeLongEdge)) * zoomScalar
			print("MTF Scalar = \(scalar)")
            
			
			if isExport {
				zoomScalar = 1.0
			}
			
            
            
			
			
			let linesPerPixel = (CGFloat(nativeLongEdge) / gateWidth) * scalar

            var lpmm10  =    linesPerPixel / 10.0 * 2.0
            var lpmm20  =    linesPerPixel / 20.0 * 2.0
            var lpmm50  =    linesPerPixel / 50.0 * 2.0
            var lpmm100 =    linesPerPixel / 100.0 * 2.0
            
            let epsilon: CGFloat = 0.0001  // very small number to avoid division by zero

            lpmm10  = min(1.0 / max(lpmm10, epsilon), 1.0)
            lpmm20  = min(1.0 / max(lpmm20, epsilon), 1.0)
            lpmm50  = min(1.0 / max(lpmm50, epsilon), 1.0)
            lpmm100 = min(1.0 / max(lpmm100, epsilon), 1.0)

            if format == 10 {
                lpmm10 = (lpmm10 + lpmm20) / 2.0
                lpmm20 = lpmm10
                lpmm50 = lpmm10
                lpmm100 = lpmm10
            }

			
            print("""
                
                Native Long Edge:
                
                \(nativeLongEdge)
                
                Scalar:
                
                \(scalar)
                
                Lines Per Pixel:
                
                \(linesPerPixel)
                
                LPMM:
                
                10  =  \(lpmm10)
                20  =  \(lpmm20)
                50  =  \(lpmm50)
                100 =  \(lpmm100)
                
                """)

			
            
            
			// Concurrent blur creation
			let group = DispatchGroup()
			let queue = DispatchQueue.global(qos: .userInitiated)
			
			var blur10 = CIImage.clear
			var blur20 = CIImage.clear
			var blur50 = CIImage.clear
			var blur100 = CIImage.clear

			
			
			// Gaussian Blur
			group.enter()
			queue.async {
                blur100 = safeInput.downAndUp(scalar100)
				group.leave()
			}
			
			group.enter()
			queue.async {

				blur50 = safeInput.downAndUp(scalar50)
				group.leave()
			}
			
			group.enter()
			queue.async {
				blur20 = safeInput.downAndUp(scalar25)
				group.leave()
			}
			
			group.enter()
			queue.async {
				blur10 = safeInput.downAndUp(scalar10)
				group.leave()
			}
			
			group.wait() // Wait for blurs to complete
			


			
			let bandKernel = CIColorKernelCache.shared.mtfBandKernel
			
			var rGain100 = MTFParameters.rGain_100LPM
			var gGain100 = MTFParameters.gGain_100LPM
			var bGain100 = MTFParameters.bGain_100LPM
			
			if applyGrain {
				rGain100 += (1.0 - rGain100) / 2.0
				gGain100 += (1.0 - gGain100) / 2.0
				bGain100 += (1.0 - bGain100) / 2.0
			}
			
			var result = safeInput
			
			result = bandKernel.apply(
				extent: safeInput.extent,
				roiCallback: {$1},
				arguments: [
					result, blur100, MTFParameters.rGain_100LPM, MTFParameters.gGain_100LPM, MTFParameters.bGain_100LPM
				]
			) ?? input
			
			result = bandKernel.apply(
				extent: safeInput.extent,
				roiCallback: { $1 },
				arguments: [
					result, blur50, MTFParameters.rGain_50LPM, MTFParameters.gGain_50LPM, MTFParameters.bGain_50LPM
				]
			) ?? result
			
			result = bandKernel.apply(
				extent: safeInput.extent,
				roiCallback: {  $1 },
				arguments: [
					result, blur20, MTFParameters.rGain_20LPM, MTFParameters.gGain_20LPM, MTFParameters.bGain_20LPM
				]
			) ?? result
			
			result = bandKernel.apply(
				extent: safeInput.extent,
				roiCallback: {  $1 },
				arguments: [
					result, blur10, MTFParameters.rGain_10LPM, MTFParameters.gGain_10LPM, MTFParameters.bGain_10LPM
				]
			) ?? result
			
			
			let blended = safeInput.blendWithOpacityPercent(result, mtfAmount)
			
            let cropped = blended.crop(input.extent)
			
			let cachedResult = cropped.insertingIntermediate(cache: true)
			
			return cachedResult
			
		} else {
			return input
		}
	}
}



// MARK: - Haltion Negative

struct NegativeHalationNode: FilterNode {
	let spread: Float
	let blend: Float
	let applyNegHalation: Bool
	
	func apply(to input: CIImage) -> CIImage {
		if applyNegHalation {
			
			let randomNoise = CIFilter.randomGenerator().outputImage!
			let noiseBlurred = randomNoise.gaussianBlur(30)
			let softnoise = noiseBlurred.transformed(by: CGAffineTransform(scaleX: 0.1, y: 0.1)).cropped(to: input.extent)

			
			let blendAdjusted = blend / 100.0
			
			// First scale up the input before blurring to avoid edges bleeding
//			let inputWidth = input.extent.width
//			let blurScale = (input.extent.width + CGFloat(spreadAdjusted)) / inputWidth
//			var blurred = input.transformed(by: CGAffineTransform(scaleX: blurScale, y: blurScale))
			var blurred = input.gaussianBlur(CGFloat(spread))
			blurred = blurred.cropped(to: input.extent)
			
			let kernel = CIColorKernelCache.shared.halation
			
			// Step 2: Apply saturation in spherical space
			guard let result = kernel.apply(
				extent: input.extent,
				roiCallback: { _, r in r },
				arguments: [input, blurred, blendAdjusted]
			) else {
				fatalError("GlobalSaturation kernel failed")
			}
			
			return softnoise.cropped(to: input.extent)
		} else {
			return input
		}
	}
	
}
