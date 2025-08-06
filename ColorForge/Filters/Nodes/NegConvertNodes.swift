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
			
//            let width = input.extent.width
//            let height = input.extent.height
//            let scaledExtent = input.extent.insetBy(dx: -width * 0.2, dy: -height * 0.2)
            
            let safeInput = input.clampedToExtent()
//            safeInput = safeInput.crop(scaledExtent)
            
            
            
			// This will eventually allow the user to scale the values below
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
                blur100 = safeInput.downAndUp(lpmm100)
				group.leave()
			}
			
			group.enter()
			queue.async {

				blur50 = safeInput.downAndUp(lpmm50)
				group.leave()
			}
			
			group.enter()
			queue.async {
				blur20 = safeInput.downAndUp(lpmm20)
				group.leave()
			}
			
			group.enter()
			queue.async {
				blur10 = safeInput.downAndUp(lpmm10)
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


// OLD - Blur based

//// Causing black squares in areas of high values
//struct MTFCurveNode: FilterNode {
//	let applyMTF: Bool
//	let mtfAmount: Float
//	let format: Int
//	let applyGrain: Bool
//	let exportMode: Bool
//	let nativeLongEdge: Int
//    let isExport: Bool
//	
//	func apply(to input: CIImage) -> CIImage {
//		if applyMTF {
//			
//            var zoomScalar = ImageViewModel.shared.zoomScale
//			
//			var scaledDown = input
//			
//			let gateWidth: CGFloat
//			switch format {
//			case 0: gateWidth = MTFParameters.mediumFormatWidth              // 60.0 mm
//			case 1: gateWidth = MTFParameters.cropMediumSensorWidth          // 43.8 mm
//			case 2: gateWidth = MTFParameters.thirtyFiveWidth                // 36.0 mm
//			case 3: gateWidth = MTFParameters.halfFrameWidth                 // 18.0 mm
//			case 4: gateWidth = MTFParameters.motionStandard35mm             // 21.95 mm
//			case 5: gateWidth = MTFParameters.motionSuper35mm                // 24.89 mm
//			case 6: gateWidth = MTFParameters.motion16mm                     // 10.26 mm
//			case 7: gateWidth = MTFParameters.motion8mm                      // 4.8 mm
//            case 8: gateWidth = MTFParameters.motionSuper8                   // 5.79 mm
//			case 9: gateWidth = MTFParameters.largeFormat54Width             // 127.0 mm
//			default: gateWidth = MTFParameters.mediumFormatWidth             // Fallback
//			}
//			
//			// This will eventually allow the user to scale the values below
//			let scalar = max(scaledDown.extent.width, scaledDown.extent.height) / CGFloat(nativeLongEdge)
//			print("MTF Scalar = \(scalar)")
//            
//            if isExport {
//                zoomScalar = 1.0
//            }
//	
//			let linesPerPixel = (CGFloat(nativeLongEdge) / gateWidth) * scalar
//            let LPMMblurVal10 = ((0.1 * linesPerPixel) * zoomScalar) / 2.0
//            let LPMMblurVal20 = ((0.05 * linesPerPixel) * zoomScalar) / 2.0
//            let LPMMblurVal50 = ((0.02 * linesPerPixel) * zoomScalar) / 2.0
//            let LPMMblurVal100 = ((0.01 * linesPerPixel) * zoomScalar) / 2.0
//			
//			
//			let scaledDownRect = scaledDown.extent
//
//			
//			// Concurrent blur creation
//			let group = DispatchGroup()
//			let queue = DispatchQueue.global(qos: .userInitiated)
//			
//			var blur10: CIImage?
//			var blur20: CIImage?
//			var blur50: CIImage?
//			var blur100: CIImage?
//			
//
//			scaledDown = scaledDown.clampedToExtent()
//			
//			// Gaussian Blur
//			group.enter()
//			queue.async {
//				let safeInput = scaledDown // Clamp extent to avoid bleed
//				blur100 = GaussianBlurNode(blurVal: Float(LPMMblurVal100)).apply(to: safeInput)
//				group.leave()
//			}
//			
//			group.enter()
//			queue.async {
//				let safeInput = scaledDown
//				blur50 = GaussianBlurNode(blurVal: Float(LPMMblurVal50)).apply(to: safeInput)
//				group.leave()
//			}
//			
//			group.enter()
//			queue.async {
//				let safeInput = scaledDown
//				blur20 = GaussianBlurNode(blurVal: Float(LPMMblurVal20)).apply(to: safeInput)
//				group.leave()
//			}
//			
//			group.enter()
//			queue.async {
//				let safeInput = scaledDown
//				blur10 = GaussianBlurNode(blurVal: Float(LPMMblurVal10)).apply(to: safeInput)
//				group.leave()
//			}
//			
//			group.wait() // Wait for blurs to complete
//			
//			guard var b10 = blur10, var b20 = blur20, var b50 = blur50, var b100 = blur100 else {
//				fatalError("Failed to generate blurred images")
//			}
//
//			
//			var result = scaledDown.cropped(to: scaledDownRect).clampedToExtent()
//			
//			let bandKernel = CIColorKernelCache.shared.mtfBandKernel
//			
//			var rGain100 = MTFParameters.rGain_100LPM
//			var gGain100 = MTFParameters.gGain_100LPM
//			var bGain100 = MTFParameters.bGain_100LPM
//			
//			if applyGrain {
//				rGain100 += (1.0 - rGain100) / 2.0
//				gGain100 += (1.0 - gGain100) / 2.0
//				bGain100 += (1.0 - bGain100) / 2.0
//			}
//			
//			result = bandKernel.apply(
//				extent: result.extent,
//				roiCallback: { _, rect in rect },
//				arguments: [
//					result, b100, MTFParameters.rGain_100LPM, MTFParameters.gGain_100LPM, MTFParameters.bGain_100LPM
//				]
//			) ?? result
//			
//			result = bandKernel.apply(
//				extent: result.extent,
//				roiCallback: { _, rect in rect },
//				arguments: [
//					result, b50, MTFParameters.rGain_50LPM, MTFParameters.gGain_50LPM, MTFParameters.bGain_50LPM
//				]
//			) ?? result
//			
//			result = bandKernel.apply(
//				extent: result.extent,
//				roiCallback: { _, rect in rect },
//				arguments: [
//					result, b20, MTFParameters.rGain_20LPM, MTFParameters.gGain_20LPM, MTFParameters.bGain_20LPM
//				]
//			) ?? result
//			
//			result = bandKernel.apply(
//				extent: result.extent,
//				roiCallback: { _, rect in rect },
//				arguments: [
//					result, b10, MTFParameters.rGain_10LPM, MTFParameters.gGain_10LPM, MTFParameters.bGain_10LPM
//				]
//			) ?? result
//			
//			scaledDown.cropped(to: scaledDownRect)
//			let croppedResult = result.cropped(to: scaledDownRect)
//			let blended = scaledDown.blendWithOpacityPercent(croppedResult, mtfAmount)
//			
//
//			
//			
//			let cachedResult = blended.insertingIntermediate(cache: true)
//			
//			return cachedResult.cropped(to: input.extent)
//			
//		} else {
//			return input
//		}
//	}
//}

// MARK: - Grain



struct GrainV3Node: FilterNode {
    let amount: Float
    let applyGrain: Bool
    let applyMTF: Bool
    let format: Int
    let exportMode:  Bool
    
    func apply(to input: CIImage) -> CIImage {
        let amountNorm = amount / 100.0
        let grainPlates = GrainPlates.shared
        
        if applyGrain {

            
            // Now move onto grain
            var grainLow: CIImage
            var grainHigh: CIImage
                
            
                switch format {
                case 0: guard let g = grainPlates.display_grainLowLargeMediumFormatWidth else { return input }; grainLow = g
                case 1: guard let g = grainPlates.display_grainLowLargeCropMediumSensorWidth else { return input }; grainLow = g
                case 2: guard let g = grainPlates.display_grainLowLargeThirtyFiveWidth else { return input }; grainLow = g
                case 3: guard let g = grainPlates.display_grainLowLargeHalfFrameWidth else { return input }; grainLow = g
                case 4: guard let g = grainPlates.display_grainLowLargeMotionStandard35mm else { return input }; grainLow = g
                case 5: guard let g = grainPlates.display_grainLowLargeMotionSuper35 else { return input }; grainLow = g
                case 6: guard let g = grainPlates.display_grainLowLargeMotion16mm else { return input }; grainLow = g
                case 7: guard let g = grainPlates.display_grainLowLargeMotion8mm else { return input }; grainLow = g
                case 8: guard let g = grainPlates.display_grainLowLargeMotionSuper8 else { return input }; grainLow = g
                default: guard let g = grainPlates.display_grainLowLargeMediumFormatWidth else { return input }; grainLow = g
                }
                
                
                switch format {
                case 0: guard let g = grainPlates.display_grainHighLargeMediumFormatWidth else { return input }; grainHigh = g
                case 1: guard let g = grainPlates.display_grainHighLargeCropMediumSensorWidth else { return input }; grainHigh = g
                case 2: guard let g = grainPlates.display_grainHighLargeThirtyFiveWidth else { return input }; grainHigh = g
                case 3: guard let g = grainPlates.display_grainHighLargeHalfFrameWidth else { return input }; grainHigh = g
                case 4: guard let g = grainPlates.display_grainHighLargeMotionStandard35mm else { return input }; grainHigh = g
                case 5: guard let g = grainPlates.display_grainHighLargeMotionSuper35 else { return input }; grainHigh = g
                case 6: guard let g = grainPlates.display_grainHighLargeMotion16mm else { return input }; grainHigh = g
                case 7: guard let g = grainPlates.display_grainHighLargeMotion8mm else { return input }; grainHigh = g
                case 8: guard let g = grainPlates.display_grainHighLargeMotionSuper8 else { return input }; grainHigh = g
                default: guard let g = grainPlates.display_grainHighLargeMediumFormatWidth else { return input }; grainHigh = g
                }
        
            
            func calculateScale() -> CGFloat {
                let baseLength: CGFloat = 11000.0

                let inputLength = max(input.extent.width, input.extent.height)
                
                let scale = inputLength / baseLength

                return scale
            }
            
          // 
            
            var grainHighCropped: CIImage = input
            var grainLowCropped: CIImage = input
            
            if exportMode {
                let scale = calculateScale()
                grainHighCropped = GrainModel.shared.tilePlates(scale, grainHigh, input)
                grainLowCropped = GrainModel.shared.tilePlates(scale, grainLow, input)
                
            } else if input.extent != ImageViewModel.shared.currentExtent ||
                        ImageViewModel.shared.currentUiGrainHigh == nil ||
                        ImageViewModel.shared.currentUiGrainLow == nil ||
                        ImageViewModel.shared.currentFormat != format {

                print("Tiling new plates for UI mode")
                let scale = calculateScale()
                grainHighCropped = GrainModel.shared.tilePlates(scale, grainHigh, input)
                grainLowCropped = GrainModel.shared.tilePlates(scale, grainLow, input)

                ImageViewModel.shared.currentUiGrainHigh = grainHighCropped
                ImageViewModel.shared.currentUiGrainLow = grainLowCropped
                ImageViewModel.shared.currentExtent = input.extent  //don't forget this
                ImageViewModel.shared.currentFormat = format

            } else {
                guard let cachedGrainHigh = ImageViewModel.shared.currentUiGrainHigh else {
                    print("No currentUiGrainHigh")
                    return input
                }
                guard let cachedGrainLow = ImageViewModel.shared.currentUiGrainLow else {
                    print("No currentUiGrainLow")
                    return input
                }

                grainHighCropped = cachedGrainHigh
                grainLowCropped = cachedGrainLow
            }
            
            
            print("""
                
                Grain Debug:
                
                Grain High Tile Extent = \(grainHigh.extent)
                Grain Low Tile Extent = \(grainLow.extent)
                
                Grain High Tiled Plate Extent = \(grainHighCropped.extent)
                Grain Low Tiled Plate Extent = \(grainLowCropped.extent)
                
                """)
        
            
            let noiseFilter = CIFilter.randomGenerator()
            
            guard let noise = noiseFilter.outputImage else {
                return input
            }
            
            

            
            
            // Notes:
            //
            // 0.85 seems to work well for a large grain at screen size
            // 1.35 seems to work well for a small grain at screen size
            // so does 3.0
            
           
            /*
             
             Concept:
             
             We will loop through an image, layering up and fading noise layers
             as we cycle through the luminence ranges.
             
             Total steps will be for number of total passes, also this will act
             as the divisor for luminence bands, we'll start with 4.
             
             
             Within each band we'll do further passes, this number will increase
             as we go up the bands. This will be to simulate finer grain in
             highlights. Also because less graib particles are activated in lower
             bands and they're larger, and then layered on top of each other.
             
             To layer we'll use a smoothstep function in metal.
             
             
             We'll use the difference between the base scale and final scale to scale blurs etc
             
             
             Starting values for testing:
             
             4 pases total
             0.1 base blur
             
             8 total passes for high blur
             
             
             2 for low
             3 for lowmid
             5 for highmid
             8 for high
             
             */
            
            
            

            
            let totalPasses = 4

            // Each entry: (scale, blurPasses)
            let noiseLayers: [(scale: Int, passes: Int, band: Float, fadeVal: Float)] = [
                (2, 3, 0.15, 0.3),    // low
                (4, 3, 0.22, 0.3),    // lowmid
                (7, 3, 0.5, 0.3),    // highmid
                (10, 3, 1.0, 0.3)     // high
            ]

            let baseBlur: Float = 0.05
            let referenceScale: Int = Int(10)
            

            var result = CIImage(color: .gray).cropped(to: input.extent)
            var lastBand: Float = 0.0
            
            for (scale, passes, band, fadeVal) in noiseLayers {
                
                
                
                // Determine blur radius for this scale level
                let blurRadius = baseBlur * Float(referenceScale / 2) / Float(scale)
                
                // Compute scalar from image dimensions
                let width: CGFloat = (input.extent.width + input.extent.height) / 2.0 * CGFloat(scale)
                let inputLongest = max(input.extent.width, input.extent.height)
                let scalar = inputLongest / width

                let noiseScaled = noise.scaleToValue(CGFloat(scalar))
                let noiseCropped = noiseScaled

                // Pass dynamically computed blur and pass count
                let noiseResult = noiseCropped.modifyNoise(blurRadius, passes)
            
                
                
                
                result = result.blendWithSmoothStep(noiseResult, input, fadeVal, lastBand, band)
                
                lastBand = band
            }
    
            var grain = CIImage(color: .gray)
            grain = grain.overlayBlend(result)
            grain = grain.overlayBlend(result)
            
            let imageResult = input.arriSoftLight(grain)
            
            let finalBlend = input.blendWithOpacityPercent(imageResult, amount)
         
            return finalBlend.cropped(to: input.extent)
            
			
//			let width = input.extent.width
//			let height = input.extent.height
            
//		
//			let kernel = CIColorKernelCache.shared.filmGrain3D
//
//			guard let grainy = kernel.apply(
//				extent: input.extent,
//				roiCallback: { _, r in r },
//				arguments: [input, width, height, amount]
//			) else {
//				fatalError("filmGrain3D kernel failed")
//			}
//			
//			
//			return grainy
            

            

//            
//            var scalar = 4.0 - 3.0 * amountNorm
//            
//            let amount = 0.5
//        
//            
//            let clampedInput = input.clampedToExtent()
//            let scaledInput = clampedInput.scaleToValue(CGFloat(scalar))
//
//            let width = Float(input.extent.width)
//            let height = Float(input.extent.height)
//            
//            
//            let totalLength: Float = width + height
//            let baseLength: Float = 12704.0
//            let sizeScalar = totalLength / baseLength
//            
//            
//            
//            let blurAmount = (amountNorm * 0.8) + 0.2
//
//            
//            let blur = 2.0 * sizeScalar * blurAmount // Base blur of 2.0
//            let fade: Float = 70.0 // Opacity percent fade base of 70
//            
//            
//            
//            let redScaled = splitChannel(scaledInput, 0)
//            let greenScaled = splitChannel(scaledInput, 1)
//            let blueScaled = splitChannel(scaledInput, 2)
//            
//            let redGrain = applyGrain(redScaled)
//            let greenGrain = applyGrain(greenScaled)
//            let blueGrain = applyGrain(blueScaled)
//            
//            let combine = CIColorKernelCache.shared.combineChannelsF3
//            
//           
////            
////            guard let combinedRGB = combine.apply(
////                extent: greenGrain.extent,
////                roiCallback: { _, r in r },
////                arguments: [redGrain, greenGrain, blueGrain]
////            ) else {
////                fatalError("filmGrain3D kernel failed")
////            }
////            
////            
////            func splitChannel(_ channelInput: CIImage, _ channel: Int) -> CIImage {
////                let kernel = CIColorKernelCache.shared.returnChannelF3
////                
////                guard let channel = kernel.apply(
////                    extent: channelInput.extent,
////                    roiCallback: { _, r in r },
////                    arguments: [channelInput, channel]
////                ) else {
////                    fatalError("filmGrain3D kernel failed")
////                }
////                
////                return channel
////            }
////            
////            
////            
////            func applyGrain(_ grainInput: CIImage) -> CIImage {
////                let kernel = CIColorKernelCache.shared.filmGrain3D
////                
////                guard let grainy = kernel.apply(
////                    extent: grainInput.extent,
////                    roiCallback: { _, r in r },
////                    arguments: [grainInput, width, height, amount]
////                ) else {
////                    fatalError("filmGrain3D kernel failed")
////                }
////                let blurred = grainy.gaussianBlur(CGFloat(blur))
////                
////                let finalBlend = grainy.blendWithOpacityPercent(blurred, fade)
////                
////                return finalBlend
////            }
////            
//

//            let cached = scaledBack.insertingIntermediate(cache: true)
//
//            return cached.cropped(to: input.extent)
        } else {
            return input
        }
    }
}


//struct GrainV3Node: FilterNode {
//	let amount: Float
//	let applyGrain: Bool
//	let applyMTF: Bool
//	let format: Int
//	let exportMode:  Bool
//	
//	func apply(to input: CIImage) -> CIImage {
//		let amountNorm = amount / 100.0
//		let grainPlates = GrainPlates.shared
//		
//		if applyGrain {
//			
//			// Calculate the blur amount if MTF applied
//			var scaledUp = input
//			if input.extent.width < 3500.0  {
//				scaledUp = input.scaleToValue(2)
//			}
//			
//			let width = scaledUp.extent.width
//			let height = scaledUp.extent.height
//			scaledUp = CIImage.empty() // Destroy the CIImage Object now we've used it
//			let imageWidth = max(width, height)
//	
//			
//			
//			// Now move onto grain
//			var grainLow: CIImage
//			var grainHigh: CIImage
//				
//			if !exportMode {
//				switch format {
//				case 0: guard let g = grainPlates.display_grainLowLargeMediumFormatWidth else { return input }; grainLow = g
//				case 1: guard let g = grainPlates.display_grainLowLargeCropMediumSensorWidth else { return input }; grainLow = g
//				case 2: guard let g = grainPlates.display_grainLowLargeThirtyFiveWidth else { return input }; grainLow = g
//				case 3: guard let g = grainPlates.display_grainLowLargeHalfFrameWidth else { return input }; grainLow = g
//				case 4: guard let g = grainPlates.display_grainLowLargeMotionStandard35mm else { return input }; grainLow = g
//				case 5: guard let g = grainPlates.display_grainLowLargeMotionSuper35 else { return input }; grainLow = g
//				case 6: guard let g = grainPlates.display_grainLowLargeMotion16mm else { return input }; grainLow = g
//				case 7: guard let g = grainPlates.display_grainLowLargeMotion8mm else { return input }; grainLow = g
//				case 8: guard let g = grainPlates.display_grainLowLargeMotionSuper8 else { return input }; grainLow = g
//				default: guard let g = grainPlates.display_grainLowLargeMediumFormatWidth else { return input }; grainLow = g
//				}
//				
//				
//				switch format {
//				case 0: guard let g = grainPlates.display_grainHighLargeMediumFormatWidth else { return input }; grainHigh = g
//				case 1: guard let g = grainPlates.display_grainHighLargeCropMediumSensorWidth else { return input }; grainHigh = g
//				case 2: guard let g = grainPlates.display_grainHighLargeThirtyFiveWidth else { return input }; grainHigh = g
//				case 3: guard let g = grainPlates.display_grainHighLargeHalfFrameWidth else { return input }; grainHigh = g
//				case 4: guard let g = grainPlates.display_grainHighLargeMotionStandard35mm else { return input }; grainHigh = g
//				case 5: guard let g = grainPlates.display_grainHighLargeMotionSuper35 else { return input }; grainHigh = g
//				case 6: guard let g = grainPlates.display_grainHighLargeMotion16mm else { return input }; grainHigh = g
//				case 7: guard let g = grainPlates.display_grainHighLargeMotion8mm else { return input }; grainHigh = g
//				case 8: guard let g = grainPlates.display_grainHighLargeMotionSuper8 else { return input }; grainHigh = g
//				default: guard let g = grainPlates.display_grainHighLargeMediumFormatWidth else { return input }; grainHigh = g
//				}
//			} else {
//				print("Loading grain plates for export mode: format=\(format)")
//
//				
//				switch format {
//				case 0:
//					guard let g = grainPlates.fullsize_grainLowLargeMediumFormatWidth else {
//						print("grainLow plate nil for format 0")
//						return input
//					}
//					grainLow = g
//				case 1:
//					guard let g = grainPlates.fullsize_grainLowLargeCropMediumSensorWidth else {
//						print("grainLow plate nil for format 1")
//						return input
//					}
//					grainLow = g
//				case 2:
//					guard let g = grainPlates.fullsize_grainLowLargeThirtyFiveWidth else {
//						print("grainLow plate nil for format 2")
//						return input
//					}
//					grainLow = g
//				case 3:
//					guard let g = grainPlates.fullsize_grainLowLargeHalfFrameWidth else {
//						print("grainLow plate nil for format 3")
//						return input
//					}
//					grainLow = g
//				case 4:
//					guard let g = grainPlates.fullsize_grainLowLargeMotionStandard35mm else {
//						print("grainLow plate nil for format 4")
//						return input
//					}
//					grainLow = g
//				case 5:
//					guard let g = grainPlates.fullsize_grainLowLargeMotionSuper35 else {
//						print("grainLow plate nil for format 5")
//						return input
//					}
//					grainLow = g
//				case 6:
//					guard let g = grainPlates.fullsize_grainLowLargeMotion16mm else {
//						print("grainLow plate nil for format 6")
//						return input
//					}
//					grainLow = g
//				case 7:
//					guard let g = grainPlates.fullsize_grainLowLargeMotion8mm else {
//						print("grainLow plate nil for format 7")
//						return input
//					}
//					grainLow = g
//				case 8:
//					guard let g = grainPlates.fullsize_grainLowLargeMotionSuper8 else {
//						print("grainLow plate nil for format 8")
//						return input
//					}
//					grainLow = g
//				default:
//					guard let g = grainPlates.fullsize_grainLowLargeMediumFormatWidth else {
//						print("grainLow plate nil for unknown format \(format)")
//						return input
//					}
//					grainLow = g
//				}
//
//				switch format {
//				case 0:
//					guard let g = grainPlates.fullsize_grainHighLargeMediumFormatWidth else {
//						print("grainHigh plate nil for format 0")
//						return input
//					}
//					grainHigh = g
//				case 1:
//					guard let g = grainPlates.fullsize_grainHighLargeCropMediumSensorWidth else {
//						print("grainHigh plate nil for format 1")
//						return input
//					}
//					grainHigh = g
//				case 2:
//					guard let g = grainPlates.fullsize_grainHighLargeThirtyFiveWidth else {
//						print("grainHigh plate nil for format 2")
//						return input
//					}
//					grainHigh = g
//				case 3:
//					guard let g = grainPlates.fullsize_grainHighLargeHalfFrameWidth else {
//						print("grainHigh plate nil for format 3")
//						return input
//					}
//					grainHigh = g
//				case 4:
//					guard let g = grainPlates.fullsize_grainHighLargeMotionStandard35mm else {
//						print("grainHigh plate nil for format 4")
//						return input
//					}
//					grainHigh = g
//				case 5:
//					guard let g = grainPlates.fullsize_grainHighLargeMotionSuper35 else {
//						print("grainHigh plate nil for format 5")
//						return input
//					}
//					grainHigh = g
//				case 6:
//					guard let g = grainPlates.fullsize_grainHighLargeMotion16mm else {
//						print("grainHigh plate nil for format 6")
//						return input
//					}
//					grainHigh = g
//				case 7:
//					guard let g = grainPlates.fullsize_grainHighLargeMotion8mm else {
//						print("grainHigh plate nil for format 7")
//						return input
//					}
//					grainHigh = g
//				case 8:
//					guard let g = grainPlates.fullsize_grainHighLargeMotionSuper8 else {
//						print("grainHigh plate nil for format 8")
//						return input
//					}
//					grainHigh = g
//				default:
//					guard let g = grainPlates.fullsize_grainHighLargeMediumFormatWidth else {
//						print("grainHigh plate nil for unknown format \(format)")
//						return input
//					}
//					grainHigh = g
//				}
//
//				print("Grain plates loaded successfully")
//			}
//
//			
//            let (exportGrainScale, uiGrainScale) = GrainModel.shared.calculateGrainScale()
//            
//      
//            
//            
//			
//			let kernel = CIColorKernelCache.shared.grainPlateBlendKernel
//			
//			
//			func scale (plate: CIImage) -> CIImage {
//				if exportMode {
//					
//					print("\n\n\nGrain Export Debug:\nGrain Plate Width = \(plate.extent.width)\nImage Short Edge = \(min(input.extent.width, input.extent.height))\nInput image extent = \(input.extent)\n\n")
//				}
//				
//				var plateAdjusted = plate
//				
//				if plate.extent.width < min(input.extent.width, input.extent.height) {
//					plateAdjusted = plateAdjusted.tiledToCover(input.extent.size)
//				}
//				
//				let plateScaleVal = max(input.extent.width, input.extent.height) / min(plateAdjusted.extent.width, plateAdjusted.extent.height)
//				var scaledPlate = plateAdjusted.transformed(by: CGAffineTransform(scaleX: plateScaleVal, y: plateScaleVal))
//			
//				
//				let plateCropped = scaledPlate.cropped(to: input.extent)
//				return plateCropped
//			}
//			
//			let grainHighCropped = scale(plate: grainHigh)
//			let grainLowCropped = scale(plate: grainLow)
//			
//			print("grainHigh.extent: \(grainHigh.extent)")
//			print("grainLow.extent: \(grainLow.extent)")
//			print("grainHighCropped.extent: \(grainHighCropped.extent)")
//			print("grainLowCropped.extent: \(grainLowCropped.extent)")
//			print("input.extent: \(input.extent)")
//			
//			
//			// Step 2: Apply saturation in spherical space
//			guard let plate = kernel.apply(
//				extent: input.extent,
//				roiCallback: { _, r in r },
//				arguments: [input, grainHighCropped, grainLowCropped, amountNorm]
//			) else {
//				fatalError("GlobalSaturation kernel failed")
//			}
//			
//			var cached = plate
//			
////			if !exportMode {
//				cached = plate.insertingIntermediate(cache: true)
////			}
//			
//			return cached.cropped(to: input.extent)
//		} else {
//			return input
//		}
//	}
//}


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
