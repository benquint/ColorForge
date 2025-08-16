//
//  TextureNodes.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics


// MARK: - Blurs

struct GaussianBlurNode: FilterNode {
    let blurVal: Float
    
    func apply(to input: CIImage) -> CIImage {
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = input
        filter.radius = blurVal
        guard let result = filter.outputImage else {
            fatalError("Could not apply GaussianBlurNode")
        }
        return result
    }
}

struct BoxBlurNode: FilterNode {
    let blurVal: Float
    
    func apply(to input: CIImage) -> CIImage {
        let filter = CIFilter.gaussianBlur()
        filter.inputImage = input
        filter.radius = blurVal
        guard let result = filter.outputImage else {
            fatalError("Could not apply GaussianBlurNode")
        }
        return result
    }
}


// MARK: - Print Halation

struct PrintHalationNode: FilterNode {

    let printHalation_size: Float
    let printHalation_amount: Float
    let printHalation_darkenMode: Bool
    let printHalation_apply: Bool
    let isExport: Bool
    
    func apply(to input: CIImage) -> CIImage {

        guard printHalation_apply else {return input}
		guard !ImageViewModel.shared.isZoomed else {return input}

		
		// Print Halation
		let filter = PrintHalation()
		filter.inputImage = input
		filter.size = printHalation_size
		filter.amount = printHalation_amount
        filter.darken = printHalation_darkenMode

		guard let result = filter.outputImage else {
			return input
		}
		
		let cachedResult = result.insertingIntermediate(cache: true)

        
        return cachedResult.crop(input.extent)
    }
    
    
}


struct PrintHalationV2Node: FilterNode {
    let nativeWidth: Int
    let printHalation_size: Float
    let printHalation_amount: Float
    let printHalation_darkenMode: Bool
    let printHalation_apply: Bool
    let isExport: Bool
    
    func apply(to input: CIImage) -> CIImage {

        guard printHalation_apply else {return input}
//        guard !ImageViewModel.shared.isZoomed else {return input}

        let zoomScalar = ImageViewModel.shared.zoomScale
        
        let isDarken: Int
        if printHalation_darkenMode {
            isDarken = 0
        } else {
            isDarken = 1
        }
        
        let uiScalar = max(input.extent.width, input.extent.height) / CGFloat(nativeWidth)

        let sizeScaled = (printHalation_size * Float(uiScalar)) * Float(zoomScalar)
        
        let downScaleVal = CGFloat((Float(nativeWidth) / sizeScaled) / Float(nativeWidth))
        
        // Scale down and up to get blur
        let scaled = input.downAndUp(downScaleVal)
        let blendScaled = printHalation_amount / 100.0
        
        let kernel = CIColorKernelCache.shared.printHalationV2
        guard let result = kernel.apply(
            extent: input.extent,
            roiCallback: { $1 },
            arguments: [input, scaled, blendScaled, isDarken]
        ) else {
            print("Failed to apply printHalationV2")
            return input}
        
        
        let cachedResult = result.insertingIntermediate(cache: true)

        
        return cachedResult.crop(input.extent)
    }
    
    
}




// Currently supports

struct RealisticFilmGrainNode: FilterNode {
    let applyGrain: Bool
    let isExport: Bool
    let grain54_low: CIImage?
    let grain54_high: CIImage?
    let grain60mm_low: CIImage?
    let grain60mm_high: CIImage?
    let grain53mm_low: CIImage?
    let grain53mm_high: CIImage?
    let grain36mm_low: CIImage?
    let grain36mm_high: CIImage?
    let grain25mm_low: CIImage?
    let grain25mm_high: CIImage?
    let grain21mm_low: CIImage?
    let grain21mm_high: CIImage?
    let grain18mm_low: CIImage?
    let grain18mm_high: CIImage?
    let grain10mm_low: CIImage?
    let grain10mm_high: CIImage?
    let grain5mm_low: CIImage?
    let grain5mm_high: CIImage?
    let grain6mm_low: CIImage?
    let grain6mm_high: CIImage?
    let gateWidth: Int
    let amount: Float
    
    func apply(to input: CIImage) -> CIImage {
        print("[GrainNode] Starting apply() – applyGrain: \(applyGrain), isExport: \(isExport)")

        guard applyGrain else {
            print("[GrainNode] Skipping grain (applyGrain is false)")
            return input
        }
        
        let zoomScalar = ImageViewModel.shared.zoomScale
        
        var g_high: CIImage = input
        var g_low: CIImage = input
        
        var finalImage: CIImage = input
        let semaphore = DispatchSemaphore(value: 0)
        
        var scalar = 1.0
        
        if isExport {
            Task.detached(priority: .userInitiated) { @MainActor in
                // Make this a Void-returning task
                let (low, high) = await GrainModel.shared.loadFullSizePlate(input, gateWidth)
                g_high = high
                g_low = low


                finalImage = input.mixGrainAndApply(g_low, g_high, amount)

                semaphore.signal()
            }

            print("[GrainNode] Waiting for plates to finish")
            semaphore.wait()  // Wait until the detached task signals completion
            print("[GrainNode] Finished apply()")

            return finalImage.cropped(to: input.extent)
        } else {

            switch gateWidth {
            case 0: // 60mm Medium Format
                guard let high = grain60mm_high, let low = grain60mm_low else { return input }
                g_high = high
                g_low = low
                
            case 1: // 43.8mm (Crop Medium Sensor)
                guard let high = grain53mm_high, let low = grain53mm_low else { return input }
                g_high = high
                g_low = low
                
            case 2: // 36mm (Standard 35mm)
                guard let high = grain36mm_high, let low = grain36mm_low else { return input }
                g_high = high
                g_low = low
                
            case 3: // 18mm (Half Frame)
                guard let high = grain18mm_high, let low = grain18mm_low else { return input }
                g_high = high
                g_low = low
                
            case 4: // 21.95mm (Motion Standard 35mm)
                guard let high = grain21mm_high, let low = grain21mm_low else { return input }
                g_high = high
                g_low = low
                
            case 5: // 24.89mm (Motion Super35)
                guard let high = grain25mm_high, let low = grain25mm_low else { return input }
                g_high = high
                g_low = low
                
            case 6: // 10.26mm (Motion 16mm)
                guard let high = grain10mm_high, let low = grain10mm_low else { return input }
                g_high = high
                g_low = low
                
            case 7: // 4.8mm (Motion 8mm)
                guard let high = grain5mm_high, let low = grain5mm_low else { return input }
                g_high = high
                g_low = low
                
            case 8: // 5.79mm (Motion Super8)
                guard let high = grain6mm_high, let low = grain6mm_low else { return input }
                g_high = high
                g_low = low
                
            case 9: // 5x4 Large Format (127mm)
                guard let high = grain54_high, let low = grain54_low else { return input }
                g_high = high
                g_low = low
                
            default: // Fallback (use 5x4 grain)
                guard let high = grain54_high, let low = grain54_low else { return input }
                g_high = high
                g_low = low
            }
        }
        
        if !isExport {
            g_high = g_high.transformed(by: CGAffineTransform(scaleX: zoomScalar, y: zoomScalar))
            g_low = g_low.transformed(by: CGAffineTransform(scaleX: zoomScalar, y: zoomScalar))
        }
        
        let grainApplied = input.mixGrainAndApply(g_low, g_high, amount)

        print("[GrainNode] Finished apply()")
        return grainApplied.cropped(to: input.extent)
    }
}

	
//struct RealisticFilmGrainNode: FilterNode {
//	let applyGrain: Bool
//	
//	func apply(to input: CIImage) -> CIImage {
//		guard applyGrain else {return input}
//		
//		// Will move abovee
//		//			let stride: Int
//		let numIterations: Int = 12
//		let grainRadiusMean: Float = 0.1
//		let grainRadiusStd: Float = 0.02
//		let sigma: Float = 0.8
//		let seed: Int = 0
//		let zoom: Float = 1.0
//		
//		let (inputDarkest, inputLightest) = input.findLightestAndDarkest()
//		
//		let inputDarkAvg = (inputDarkest.x + inputDarkest.y + inputDarkest.z) / 3.0
//		let inputLightAvg = (inputLightest.x + inputLightest.y + inputLightest.z) / 3.0
//		
//		func grain(_ inputImage: CIImage) -> CIImage {
//			let filter = RealisticFilmGrain()
//			filter.inputImage = input
//			filter.numIterations = numIterations
//			filter.grainRadiusMean = grainRadiusMean
//			filter.grainRadiusStd = grainRadiusStd
//			filter.sigma = sigma
//			filter.seed = seed
//			filter.zoom = zoom
//			guard let result = filter.outputImage else {return input}
//			return result.cropped(to: input.extent)
//		}
//		
//		
//		let bwFilter = CIFilter.colorMonochrome()
//		bwFilter.inputImage = input
//		bwFilter.color = CIColor(red: 0.5, green: 0.5, blue: 0.5)
//		bwFilter.intensity = 1.0
//		guard let bwImage = bwFilter.outputImage else {return input}
//		
//		let grain = grain(bwImage)
//		
//		
//		let (outputDarkest, outputLightest) = grain.findLightestAndDarkest()
//		
//		let outputDarkAvg = (outputDarkest.x + outputDarkest.y + outputDarkest.z) / 3.0
//		let outputLightAvg = (outputLightest.x + outputLightest.y + outputLightest.z) / 3.0
//		
//		let lowVal = inputDarkAvg - outputDarkAvg
//		let highVal = (1.0 - (outputLightAvg - inputLightAvg)) - lowVal
//		
//		let kernel = CIColorKernelCache.shared.normaliseGrain
//		guard let result = kernel.apply(
//			extent: grain.extent,
//			roiCallback: { _, rect in rect },
//			arguments: [grain, lowVal, highVal]
//		) else {
//			print("Failed to normalise grain")
//			return grain
//		}
//					   
//		
//		
//		return result
//		
//
//		
//		
//		
//		
//		
//		
//
//			
//			
//			
//			// ***** Split channels and apply concurrently ***** //
////			
////			// Red
////			group.enter()
////			queue.async {
////				red = red.copyChannel(0)
//////				red = red.applySamplerGrain(numIterations: numIterations, grainRadiusMean: grainRadiusMean, grainRadiusStd: grainRadiusStd, sigma: sigma, seed: seed)
////				red = applyGrain(red)
////			}
////			
////			// Green
////			group.enter()
////			queue.async {
////				green = green.copyChannel(1)
//////				green = green.applySamplerGrain(numIterations: numIterations, grainRadiusMean: grainRadiusMean, grainRadiusStd: grainRadiusStd, sigma: sigma, seed: seed)
////				green = applyGrain(green)
////			}
////			
////			// Blue
////			group.enter()
////			queue.async {
////				blue = blue.copyChannel(2)
//////				blue = blue.applySamplerGrain(numIterations: numIterations, grainRadiusMean: grainRadiusMean, grainRadiusStd: grainRadiusStd, sigma: sigma, seed: seed)
////				blue = applyGrain(blue)
////			}
////			
////			group.wait()
////			
////			let kernel = CIColorKernelCache.shared.combineChannelsF3
////			guard let result = kernel.apply(
////				extent: input.extent,
////				roiCallback: { _, rect in rect },
////				arguments: [red, green, blue]
////			) else {
////				print("Failed to combine channels")
////				return input}
////			
////			return result.cropped(to: input.extent)
//			
//		}
//		
//	}
//    
    

// Need to handle is zoomed
struct NoiseGrainNode: FilterNode {
    let isExport: Bool
	let applyGrain: Bool
    
    func apply(to input: CIImage) -> CIImage {
		guard applyGrain else {return input}
		
		let width = input.extent.width
		let height = input.extent.height
		
		let gray = CIImage(color: .gray).cropped(to: input.extent)
		
		var plate = gray

		if isExport {
			guard let full_plate = GrainModel.shared.initialGrainPlate else {return input}
			plate = full_plate
		} else {
			guard let cgImage = GrainModel.shared.initialGrainPlate2048 else {return input}
			plate = CIImage(cgImage: cgImage)
		}
		
		let aspectRatio = width / height
		let plateLongEdge = plate.extent.height
		var scale: CGFloat = 1.0
		
		if aspectRatio > 1.0 {
			plate = plate.oriented(.right)
		}
		
		scale = max(width / plate.extent.height, height / plate.extent.height)
		
		plate = plate.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
		
		let result = input.arriSoftLight(plate)
        
        return result.cropped(to: input.extent)
//		return input
    }
}



// Need to handle is zoomed
struct NoiseGrainNodeV2: FilterNode {
    let isExport: Bool
    let uiScale: Float
    let id: UUID
    
    func apply(to input: CIImage) -> CIImage {
        
        let grain = GrainModel.shared.generateGrain(id, input, 1.0, uiScale, isExport: isExport)
        
        let blend = input.arriSoftLight(grain)
        
        return blend.cropped(to: input.extent)
    }
}

struct MTFTestNode: FilterNode {
    func apply(to input: CIImage) -> CIImage {
        
        guard let chartURL = Bundle.main.url(forResource: "TestChart_3000", withExtension: "tif") else {
            print("Failed to load GrainDesaturatedP400.png from bundle.")
            return input
        }
        
        guard let testChart = CIImage(contentsOf: chartURL) else {
            print("Failed to create CIImage from grain file.")
            return input
        }
        
        
        let scale = ImageViewModel.shared.downAndUpScale
        
        if scale != 1.0 {
            
            let result = testChart.downAndUp(scale).cropped(to: testChart.extent)
            
            debugSave(result, "MTFResult_ScaledTo\(scale)")
            
            
            return result
            
        } else {
            return input
        }
    }
}
