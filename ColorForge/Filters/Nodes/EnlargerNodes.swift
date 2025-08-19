//
//  EnlargerNodes.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI


// MARK: - Combined
//struct EnlargerPrintChainNode: FilterNode {
//    let convertToNeg: Bool
//    let applyPrintMode: Bool
//
//    var isMask: Bool
//    var maskData: Any? = nil
//    let exposure: Float
//    let fStop: Float
//    let cyan: Float
//    let magenta: Float
//    let yellow: Float
//    let isInit: Bool
//
//    let bwMode: Bool
//    let useLegacy: Bool
//    let stockChoice: Int
//
//    let applyFlash: Bool
//    let previewFlash: Bool
//    let hand: CIImage
//    let flashColor: CIColor
//
//    func apply(to input: CIImage) -> CIImage {
//        if !isInit {
//            if convertToNeg && applyPrintMode {
//                let paperSoftenNode = PaperSoftenNode()
//                let enlargerNode = EnlargerV2Node(isMask: isMask, evSeconds: exposure, fstop: fStop, cyan: cyan, magenta: magenta, yellow: yellow, bwMode: bwMode, useLegacy: useLegacy)
//                let printCurveNode = PrintCurveNode(applyFlash: applyFlash, previewFlash: previewFlash, hand: hand, flashColor: flashColor)
//                let printGamutNode = PrintGamutNode(bwMode: bwMode, useLegacy: useLegacy)
//                let bwNode = BlackAndWhiteEnlargerNode(isMask: isMask, evSeconds: exposure, fstop: fStop, magenta: magenta, bwMode: bwMode, useLegacy: useLegacy)
//
//                let legacyEnlarger = LegacyEnlargerNode(isMask: isMask, evSeconds: exposure, cyan: cyan, magenta: magenta, yellow: yellow, bwMode: bwMode, stockChoice: stockChoice, useLegacy: useLegacy)
//                //				let paperColor = PaperColorNode(applyFlash: applyFlash, previewFlash: previewFlash, hand: hand, flashColor: flashColor)
//                //				let enlarger2 = enlargerFiltrationV2(exposure: exposure, cyan: cyan, magenta: magenta, yellow: yellow, applyPrintMode: applyPrintMode)
//
//                //				let step1 = paperSoftenNode.apply(to: input)
//                let step2 = enlargerNode.apply(to: input)
//                let step3 = printGamutNode.apply(to: step2)
//                let step4 = bwNode.apply(to: step3)
//                let step5 = legacyEnlarger.apply(to: step4)
//                //				let step1 = paperSoftenNode.apply(to: input)
//                //				let step2 = enlargerNode.apply(to: input)
//                //				let step4 = paperSoftenNode.apply(to: step3)
//
//
//                return step5
//            } else {
//                return input
//            }
//        } else {
//            let rect = CGRect(x: 0, y: 0, width: 1920, height: 1200)
//            let white = CIImage(color: .white).cropped(to: rect)
//            return white
//        }
//    }
//
//}


struct LegacyEnlargerNode: FilterNode {

	let applyPrintMode: Bool
	let convertToNeg: Bool
	let evSeconds: Float
	let cyan: Float
	let magenta: Float
	let yellow: Float
	let bwMode: Bool
	let stockChoice: Int
	let useLegacy: Bool
	
	
	
	func apply(to input: CIImage) -> CIImage {
		let lutModel = LutModel.shared
		
		if !convertToNeg { return input }
		if !useLegacy { return input }
		
		var ev: Float = evSeconds
		var cyanAdjusted: Float = cyan
		var magentaAdjusted: Float = magenta
		var yellowAdjusted: Float = yellow
		
		let linear = input
		
		
		let kernel = CIColorKernelCache.shared.legacyEnlarger
		guard let result = kernel.apply(
			extent: input.extent,
			roiCallback: { _, r in r },
			arguments: [linear, cyanAdjusted, magentaAdjusted, yellowAdjusted, ev]
		) else {
			print("❌ legacyEnlarger kernel failed to apply.")
			return input
		}
		
		return result.cropped(to: input.extent)
	}
	
}


struct LegacyPrintCurveAndGamutNode: FilterNode {
	let bwMode: Bool
	let convertToNeg: Bool
	let applyPrintMode: Bool
	let stockChoice: Int
	let useLegacy: Bool
	
	func apply(to input: CIImage) -> CIImage {
		
		if !convertToNeg { return input }
		if !useLegacy {return input}
		
		// Curve choice
		let curveChoice: Int
		switch stockChoice {
		case 4: curveChoice = 1
		default: curveChoice = 0
		}
		
		let curveResult: CIImage
		
		
		if curveChoice == 0 {
			let pckernel = CIColorKernelCache.shared.legacyPrintCurve
			guard let result = pckernel.apply(
				extent: input.extent,
				roiCallback: { _, r in r },
				arguments: [input]
			) else {
				print("❌ legacyPrintCurve kernel failed to apply.")
				return input
			}
			curveResult = result
		} else {
			let bwkernel = CIColorKernelCache.shared.legacyGrade0Curve
			guard let result = bwkernel.apply(
				extent: input.extent,
				roiCallback: { _, r in r },
				arguments: [input]
			) else {
				print("❌ legacyGrade0Curve kernel failed to apply.")
				return input
			}
			curveResult = result
		}
		
		let finalResult: CIImage
		
		// gamut - skip for tmax
		if curveChoice != 1 {
			finalResult = curveResult.applyLutColorSpace("NegToPrintGamut")
		} else {
			finalResult = curveResult
		}
		
		
		return finalResult.cropped(to: input.extent)
	}
}


extension Float {
    
    // 0 = EV, 1 = Cyan, 2 = Magenta, 3 = Yellow
    func calcCC(_ input: Int, _ fstop: Float) -> Float {
        let result: Float
        
        switch input {
            
        case 0:
            let stop = 2 * log2(fstop / 11.0)
            let ev = (log2(self / 12.0)) - stop
            result = ev
            break
            
        case 1:
            let cyanDensity = (self * 0.5632184) * 0.01
            let r_dmax: Float = 2.1466
            let cyanCC: Float = pow(10.0, -((cyanDensity / 0.002 - 95.0) / (1023.0 / r_dmax)))
            result = cyanCC
            break
            
        case 2:
            let magentaDensity = (self * 0.41666667) * 0.01
            let g_dmax: Float = 2.7104
            let magentaCC: Float = pow(10.0, -((magentaDensity / 0.002 - 95.0) / (1023.0 / g_dmax)))
            result = magentaCC
            break
            
        case 3:
            let yellowDensity = (self * 0.27011494) * 0.01;
            let b_dmax: Float = 3.1870
            let yellowCC: Float = pow(10.0, -((yellowDensity / 0.002 - 95.0) / (1023.0 / b_dmax)))
            result = yellowCC
            break
            
        default:
            result = 1.0
        }
        
        return result
    }
}


struct EnlargerV2Node: EnlargerNode {
    let tiffScanMode: Bool
	let applyPrintMode: Bool
	let convertToNeg: Bool
	let evSeconds: Float
	let fstop: Float
	let cyan: Float
	let magenta: Float
	let yellow: Float
	let bwMode: Bool
	let useLegacy: Bool
	
	func apply(to input: CIImage) -> (CIImage) {
		if useLegacy || bwMode {
			return input
		}
        
        if tiffScanMode {
            let evNeutral: Float = 0.5550
            let magentaNeutral: Float = 1.2039 - 0.96996
            let yellowNeutral: Float = 1.7429 - 0.91066
            
            
            let ev = evSeconds.calcCC(0, fstop) - evNeutral
            let cyanCC = cyan.calcCC(1, fstop)
            let magentaCC = magenta.calcCC(2, fstop) + magentaNeutral
            let yellowCC = yellow.calcCC(3, fstop) + yellowNeutral
            

            
            let kernel = CIColorKernelCache.shared.enlargerV2
            let result = kernel.apply(
                extent: input.extent,
                roiCallback: { _, r in r },
                arguments: [input, ev, cyanCC, magentaCC, yellowCC]
            ) ?? input
            
            return
                result.cropped(to: input.extent)
        } else {
            
            
            guard applyPrintMode else {return (input)}
            
            guard convertToNeg else {
                return input
            }
            
            let evNeutral: Float = 0.5550
            let magentaNeutral: Float = 1.2039 - 0.96996
            let yellowNeutral: Float = 1.7429 - 0.91066
            
            
            let ev = evSeconds.calcCC(0, fstop) - evNeutral
            let cyanCC = cyan.calcCC(1, fstop)
            let magentaCC = magenta.calcCC(2, fstop) + magentaNeutral
            let yellowCC = yellow.calcCC(3, fstop) + yellowNeutral
            
            
            
            
            
            let kernel = CIColorKernelCache.shared.enlargerV2
            let result = kernel.apply(
                extent: input.extent,
                roiCallback: { _, r in r },
                arguments: [input, ev, cyanCC, magentaCC, yellowCC]
            ) ?? input
            
            return result.cropped(to: input.extent)
        }
	}
	
}


// MARK: - Maskable Enlarger

struct EnlargerV2MaskNode: FilterNode {
	

	let applyPrintMode: Bool
	let convertToNeg: Bool
	let evSeconds: Float // Now Stops
	let fstop: Float
	let bwMode: Bool
    let cyan: Float
    let magenta: Float
    let yellow: Float
	
	func apply(to input: CIImage) -> CIImage {
		if !convertToNeg && !applyPrintMode { return input }
		if bwMode { return input }
		else {
			


			let ev = evSeconds
			
			let cyanDensity = ((cyan + 33.71) * 0.5632184) * 0.01
			let magentaDensity = (((magenta + 93.61) - 48.0) * 0.41666667) * 0.01
			let yellowDensity = (((yellow + 157.33) - 87.0) * 0.27011494) * 0.01;
			
			
			
			let r_dmax: Float = 2.1466
			let g_dmax: Float = 2.7104
			let b_dmax: Float = 3.1870
			
			let cyanCC: Float = pow(10.0, -((cyanDensity / 0.002 - 95.0) / (1023.0 / r_dmax)))
			let magentaCC: Float = pow(10.0, -((magentaDensity / 0.002 - 95.0) / (1023.0 / g_dmax)))
			let yellowCC: Float = pow(10.0, -((yellowDensity / 0.002 - 95.0) / (1023.0 / b_dmax)))
			
	
			
			let kernel = CIColorKernelCache.shared.enlargerV2Masked
			let result = kernel.apply(
				extent: input.extent,
				roiCallback: { _, r in r },
				arguments: [input, ev, cyanCC, magentaCC, yellowCC]
			) ?? input
			
			return result.cropped(to: input.extent)
		}
	}

}


// MARK: - Print Curve filter
// Expects image in gamma 2.2
struct PrintCurveNode: FilterNode {
	let applyPrintMode: Bool
	let applyFlash: Bool
	let convertToNeg: Bool
	let previewFlash: Bool
	let hand: CIImage
	let flashColor: CIColor
	
	func apply(to input: CIImage) -> CIImage {
		
		if !convertToNeg {return input}
		if !applyPrintMode {return input}
		
		let kernel = CIColorKernelCache.shared.printCurve
		
		let paperColor = CIColor(red: 0.976, green: 0.976, blue: 0.985, alpha: 1.0)
		let paperInit = CIImage(color: paperColor).cropped(to: input.extent)
		
		let inputWidth = input.extent.width
		let inputHeight = input.extent.height
		let handScale = (inputHeight / hand.extent.height) * 0.7
		let handScaled = hand.transformed(by: CGAffineTransform(scaleX: handScale, y: handScale))
		let handTranslated = handScaled.transformed(by: CGAffineTransform(
			translationX: inputWidth - handScaled.extent.width, y: 0))
		let black = CIImage(color: .white).cropped(to: input.extent)
		let handMask = handTranslated.composited(over: black).cropped(to: input.extent)
		
//        if previewFlash {
//            let (r, g, b) = input.findAverage()
//            FilterPipeline.shared.flashColor = CIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
//            print("\nFlash Color: \(flashColor)\n")
//            let maskedInput = paperInit.blendWithMask(handMask, input).cropped(to: input.extent)
//            let previewSoftened = PaperSoftenNode().apply(to: maskedInput).cropped(to: input.extent)
//
//            return previewSoftened
//        }
		
		let paperFlashed = CIImage(color: flashColor).cropped(to: input.extent)
		
		var paper: CIImage
		var applyFlashInt: Int = 0
		if applyFlash {
			paper = paperFlashed
			applyFlashInt = 1
		} else {
			paper = paperInit
			applyFlashInt = 0
		}
		
		let result = kernel.apply(
			extent: input.extent,
			roiCallback: { _, r in r },
			arguments: [input, paper, applyFlashInt]
		) ?? input
		
		return result
	}
}





// MARK: - Print Gamut LUT node
struct PrintGamutNode: FilterNode {
    let tiffScanMode: Bool
	let convertToNeg: Bool
	let applyPrintMode: Bool
	let bwMode: Bool
	let useLegacy: Bool
	let applyFlash: Bool
	let flash: CIImage
	
	func apply(to input: CIImage) -> CIImage {
		//		let resourceName = "NegToPrintGamut"
		// LVT_neg_to_print
        if tiffScanMode {
            if !applyPrintMode {return input}
            
            if bwMode { return input } else {
                let resourceName = "LVT_sRGB_Neg_to_Print"
                
                if applyFlash {
                    let multiplied = input.multiply(flash)
                    let result = multiplied.applyLutColorSpace(resourceName)
                    
//                    let modified = result.applyLutColorSpace("PostPrint")
                    
                    return result.cropped(to: input.extent)
                } else {
                    let outputImage = input.applyLutColorSpace(resourceName)
//                    let modified = outputImage.applyLutColorSpace("PostPrint")
                    
                    return outputImage.cropped(to: input.extent)
                }
            }
        } else {
            
            if !convertToNeg { return input }
            if !applyPrintMode {return input}
            if useLegacy { return input }
            
            if bwMode { return input } else {
                let resourceName = "LVT_sRGB_Neg_to_Print"
                
                if applyFlash {
                    let multiplied = input.multiply(flash)
                    let result = multiplied.applyLutColorSpace(resourceName)
                    return result.cropped(to: input.extent)
                } else {
                    let outputImage = input.applyLutColorSpace(resourceName)
//                    let modified = outputImage.applyLutColorSpace("PostPrint")
                    return outputImage.cropped(to: input.extent)
                }
            }
        }
	}
}


// MARK: - Black and white enlarger

struct BlackAndWhiteEnlargerNode: FilterNode {
	let applyPrintMode: Bool
	let convertToNeg: Bool
	let evSeconds: Float
	let fstop: Float
	let magenta: Float // contrast
	let bwMode: Bool
	let useLegacy: Bool
	
	func apply(to input: CIImage) -> CIImage {
		
		if !convertToNeg { return input }
		if !applyPrintMode {return input}
		if useLegacy {return input}
		if bwMode {
			let evSecondsAdjusted = evSeconds + 8.0
			let magentaAdjusted = magenta + 48.0
			
			let stop = 2 * log2(fstop / 11.0)
			let ev = (log2(evSecondsAdjusted / 12.0)) - stop
			
			let magentaDensity = ((magentaAdjusted - 48.0) * 0.41666667) * 0.01
			let dMinGreen_KodakPortra: Float = 0.206
			let g_dmax: Float = 2.7104
			let magentaCC: Float = pow(10.0, -((magentaDensity / 0.002 - 95.0) / (1023.0 / g_dmax)))
			
			let kernel = CIColorKernelCache.shared.enlargerBW
			return kernel.apply(
				extent: input.extent,
				roiCallback: { _, r in r },
				arguments: [input, ev, magentaCC]
			) ?? input
		} else {return input}
	}
}



// MARK: - Paper Nodes
struct PaperSoftenNode: FilterNode {
	let applyPrintMode: Bool
	let convertToNeg: Bool
    
	
	func apply(to input: CIImage) -> CIImage {
		if !convertToNeg { return input }
		if !applyPrintMode { return input }
        
        var zoomScalar = ImageViewModel.shared.zoomScale
        
        let printWidthMM = 406.4
        let inputWidth = max(input.extent.width, input.extent.height)
        let pixelsPerMM = (inputWidth / printWidthMM) * zoomScalar
        
        
        
        let epsilon: CGFloat = 0.0001
        var lpmm15 = pixelsPerMM / 15.0 * 2.0
        lpmm15 = min(1.0 / max(lpmm15, epsilon), 1.0)
        
        if lpmm15 == 1.0 { return input }
        
        let blurred = input.downAndUp(lpmm15)
        
        let bandKernel = CIColorKernelCache.shared.mtfBandKernel
        
        let result = bandKernel.apply(
            extent: input.extent,
            roiCallback: {$1},
            arguments: [
                input, blurred, 0.5, 0.5, 0.5
            ]
        ) ?? input
        
        let cropped = result.crop(input.extent)
        
		return cropped
	}
}

struct PaperColorNode: FilterNode {
	let applyFlash: Bool
	let previewFlash: Bool
	let hand: CIImage
	let flashColor: CIColor
	
	func apply(to input: CIImage) -> CIImage {
		let paperColor = CIColor(red: 0.976, green: 0.976, blue: 0.985, alpha: 1.0)
		let paper = CIImage(color: paperColor).cropped(to: input.extent)
		
		let inputWidth = input.extent.width
		let inputHeight = input.extent.height
		let handScale = (inputHeight / hand.extent.height) * 0.7
		let handScaled = hand.transformed(by: CGAffineTransform(scaleX: handScale, y: handScale))
		let handTranslated = handScaled.transformed(by: CGAffineTransform(
			translationX: inputWidth - handScaled.extent.width, y: 0))
		let black = CIImage(color: .white).cropped(to: input.extent)
		let handMask = handTranslated.composited(over: black).cropped(to: input.extent)
		
//        if previewFlash {
//            let (r, g, b) = input.findAverage()
//            FilterPipeline.shared.flashColor = CIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0)
//            print("\nFlash Color: \(flashColor)\n")
//            let maskedInput = paper.blendWithMask(handMask, input).cropped(to: input.extent)
//            let previewSoftened = PaperSoftenNode().apply(to: maskedInput).cropped(to: input.extent)
//
//            return maskedInput
//        }
		
		let paperFlashed = CIImage(color: flashColor)
		
		var finalResult: CIImage = input
		
		if applyFlash {
			finalResult = input.multiply(paperFlashed)
		} else {
			finalResult = input.multiply(paper)
		}
		
		return input
	}
	
}
	
struct PaperNode: FilterNode {
	let convertToNeg: Bool
	
	let showPaperMask: Bool
	
	let imageScale: CGFloat
	
	let maskScale: CGFloat
	let maskXshift: CGFloat
	let maskYshift: CGFloat
	
	
	
	func apply(to input: CIImage) -> CIImage {
		
		if !showPaperMask {return input}
		
		print("Applying borders")
		
		func applyKernel(_ base: CIImage, _ shrunk: CIImage,
						 _ mask: CIImage, _ blurred: CIImage,
						 _ convertToNeg: Bool) -> CIImage {
			var choice: Int = 0
			if convertToNeg {
				choice = 1
			} else {
				choice = 0
			}
			
			
			let kernel = CIColorKernelCache.shared.blendPaper
			return kernel.apply(
				extent: inputRect,
                roiCallback: { _, _ in inputRect },
				arguments: [base, shrunk, mask, blurred, choice]
			) ?? input
		}
		
			 
		let inputRect = input.extent
		
		let (shrunk, mask) = input.scaleAndReturnPaperBorders()
		
		
        let shrunkCanvas = CIImage(color: convertToNeg ? .black : .white).crop(input.extent)
		

		
		// Step 1: Apply scaling only
		let shrunkScaledTemp = shrunk.transformed(by: CGAffineTransform(scaleX: imageScale, y: imageScale))

		// Step 2: Use the *scaled* extent to compute the new center
		let newImgCenter = CGPoint(x: shrunkScaledTemp.extent.midX, y: shrunkScaledTemp.extent.midY)

		// Step 3: Translate back into original position using scaled center
		let imageTransform = CGAffineTransform(translationX: inputRect.midX - newImgCenter.x,
											   y: inputRect.midY - newImgCenter.y)

		// Step 4: Apply translation to the already-scaled image
		let shrunkScaled = shrunkScaledTemp.transformed(by: imageTransform)
			.composited(over: shrunkCanvas)
			.cropped(to: inputRect)
		
		
		
		// Step 1: Apply scaling only
		let maskScaled = mask.transformed(by: CGAffineTransform(scaleX: maskScale, y: maskScale))

		// Step 2: Use the *scaled* extent to compute the new center
		let newMaskCenter = CGPoint(x: maskScaled.extent.midX, y: maskScaled.extent.midY)

		// Step 3: Translate based on the scaled center and shift values
		let shiftedTransform = CGAffineTransform(translationX: -newMaskCenter.x * maskXshift,
												 y: -newMaskCenter.y * maskYshift)

		// Step 4: Apply shift to the already-scaled image
		let maskTranslated = maskScaled.transformed(by: shiftedTransform)
		

		
		

		var dither: Float = 0.2
		if convertToNeg { dither = 0.05}
		
		let blurVal: CGFloat = 50 * imageScale
		let shrunkBlurred = shrunkScaled.gaussianBlur(blurVal)
		
		let blurDithered = shrunkBlurred.dither(dither)
		
		var base = CIImage(color: CIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)).cropped(to: input.extent)
		base = base.dither(dither)
		
		let result = applyKernel(base, shrunkScaled, maskTranslated, blurDithered, convertToNeg)

		
		
        return result.crop(input.extent)
	
	}
	
}

struct AddPaperBlackNode: FilterNode {
	
	
	func apply(to input: CIImage) -> CIImage {
		let paperBlack = input.scalePaperBlack()
		let added = input.add(paperBlack)
		let blend = input.blendWithOpacityPercent(added, 40)
		
		
		return blend.cropped(to: input.extent)
	}
}

// Returns the flash color to be used later
struct FlashNode: FilterNode {
	let applyPrintMode: Bool
	let previewFlash: Bool
	let applyFlash: Bool
	let flashEV: Float
	let flashFStop: Float
	let flashCyan: Float
	let flashMagenta: Float
	let flashYellow: Float
	let hand: CIImage
	
	func apply(to input: CIImage) -> CIImage {
		
		guard applyFlash && applyPrintMode else {return input}
		
		
		
		
		//  *********** Base color and paper setup ***********  //
		
		let base = CIImage(color: CIColor(red: 0.466, green: 0.206, blue: 0.109, alpha: 1.0)).cropped(to: input.extent)
		let paper = CIImage(color: CIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)).cropped(to: input.extent)
		
		
		
		
		//  *********** Enlarger variable setup ***********  //
		
		let stop = 2 * log2(flashFStop / 11.0)
		let ev = (log2(flashEV / 12.0)) - stop
		
		let cyanDensity = (flashCyan * 0.5632184) * 0.01
		let magentaDensity = ((flashMagenta - 12) * 0.41666667) * 0.01
		let yellowDensity = ((flashYellow - 81) * 0.27011494) * 0.01;

		let r_dmax: Float = 2.1466
		let g_dmax: Float = 2.7104
		let b_dmax: Float = 3.1870
		
		let cyanCC: Float = pow(10.0, -((cyanDensity / 0.002 - 95.0) / (1023.0 / r_dmax)))
		let magentaCC: Float = pow(10.0, -((magentaDensity / 0.002 - 95.0) / (1023.0 / g_dmax)))
		let yellowCC: Float = pow(10.0, -((yellowDensity / 0.002 - 95.0) / (1023.0 / b_dmax)))
		
		
		
		
		//  *********** Apply Kernel ***********  //
		
		let kernel = CIColorKernelCache.shared.enlargerV2
		let result = kernel.apply(
			extent: input.extent,
			roiCallback: { _, r in r },
			arguments: [base, ev, cyanCC, magentaCC, yellowCC]
		) ?? input
		
		
		
		
		
		//  *********** Flash Preview Logic ***********  //
		
		if previewFlash {
			let mask = CIImage(color: .white).cropped(to: input.extent)
			var scalar: CGFloat = 1.0
			let aspect = input.extent.width / input.extent.height
			var handScaled = hand
			
			if aspect > 1 {
				scalar = (hand.extent.height / input.extent.height) * 0.4
			} else {
				scalar = (hand.extent.width / input.extent.width) * 0.4
			}
			
			handScaled = handScaled.transformed(by: CGAffineTransform(scaleX: scalar, y: scalar))
			let scaledWidth = handScaled.extent.width
			let xShift = input.extent.width - scaledWidth
			
			handScaled = handScaled.transformed(by: CGAffineTransform(translationX: xShift, y: 0))
		 
			handScaled = handScaled.composited(over: mask)

			let maskedResult = paper.metalMask(handScaled, result)
			

			
			
			let resourceName = "LVT_sRGB_Neg_to_Print"
			
			let lutApplied = maskedResult.applyLutColorSpace(resourceName)
			
			print("""
				
				PrintFlashDebug - Preview:
				
				Hand Extent = \(hand.extent)
				Hand Scaled Extent = \(handScaled.extent)
				Hand Scale = \(scalar)
				
				Final Result Extent = \(lutApplied.extent)
				
				""")
			
			return maskedResult.cropped(to: input.extent)
		} else {
			return result.cropped(to: input.extent)
		}
		
	}
}
	

