//
//  RawAdjustNodes.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI
import ImageIO




// MARK: - Debayer Filter Node

// Need to add in scaling logic, along with caching dynamically for contexts
// that support caching intermediates.
// RE scaling - Run at 1.0, to allow for zooming at later points in the pipeline.
struct DebayerNode: InitialFilterNode {
    let rawFileURL: URL
    let scale: Float
    
    func apply() -> (CIImage, SIMD2<Float>, Float) {
        
        
        
        guard let rawFilter = CIRAWFilter(imageURL: rawFileURL) else {
            fatalError("Failed to create CIRAWFilter")
        }

        
        let baselineExposure = rawFilter.baselineExposure
        print("Baseline Exposure: \(baselineExposure)")
        
        rawFilter.baselineExposure = 0.0
        rawFilter.isLensCorrectionEnabled = true
        rawFilter.shadowBias = 0.0
        rawFilter.boostAmount = 0.0
        rawFilter.localToneMapAmount = 0.0
        rawFilter.isGamutMappingEnabled = true
        rawFilter.extendedDynamicRangeAmount = 0.0
        rawFilter.scaleFactor = scale // Scaled to 70 percent of the screen
        rawFilter.boostShadowAmount = 0.0
        rawFilter.contrastAmount = 0.0
        rawFilter.detailAmount = 0.0
        rawFilter.exposure = 0.0
        rawFilter.sharpnessAmount = 0.0
        
        
        
        
        guard let output = rawFilter.outputImage else {
            fatalError("Failed to generate image from RAW file.")
        }
        
        print("Output extent: \(output.extent)")
        
        print("Baseline Exposure after: \(rawFilter.baselineExposure)")
        
        let chroma = rawFilter.neutralChromaticity
        let xySIMD = SIMD2(Float(chroma.x), Float(chroma.y))
        
        return (output, xySIMD, baselineExposure)
    }
}

struct DebayerFullNode: HRNode {
    let rawFileURL: URL
    let scale: Float
    
    func apply() -> CIImage {
        
        guard let rawFilter = CIRAWFilter(imageURL: rawFileURL) else {
            fatalError("Failed to create CIRAWFilter")
        }
        
        let baselineExposure = rawFilter.baselineExposure
        
        rawFilter.baselineExposure = 0.0
        rawFilter.isLensCorrectionEnabled = true
        rawFilter.shadowBias = 0.0
        rawFilter.boostAmount = 0.0
        rawFilter.localToneMapAmount = 0.0
        rawFilter.isGamutMappingEnabled = true
        rawFilter.extendedDynamicRangeAmount = 0.0
        rawFilter.scaleFactor = scale
        rawFilter.boostShadowAmount = 0.0
        rawFilter.contrastAmount = 0.0
        rawFilter.detailAmount = 0.0
        rawFilter.exposure = 0.0
        rawFilter.sharpnessAmount = 0.0
        
        
        
        
        guard let hrOutput = rawFilter.outputImage else {
            fatalError("Failed to generate image from RAW file.")
        }
        
        
        return hrOutput
    }
}

struct DebayerHaldNode: HRNode {
    let rawFileURL: URL
    
    func apply() -> CIImage {
        
        guard let rawFilter = CIRAWFilter(imageURL: rawFileURL) else {
            fatalError("Failed to create CIRAWFilter")
        }
        
        rawFilter.baselineExposure = 0.0
        rawFilter.isLensCorrectionEnabled = true
        rawFilter.shadowBias = 0.0
        rawFilter.boostAmount = 0.0
        rawFilter.localToneMapAmount = 0.0
        rawFilter.isGamutMappingEnabled = true
        rawFilter.extendedDynamicRangeAmount = 0.0
        rawFilter.scaleFactor = 1.0
        rawFilter.boostShadowAmount = 0.0
        rawFilter.contrastAmount = 0.0
        rawFilter.detailAmount = 0.0
        rawFilter.exposure = 0.0
        rawFilter.sharpnessAmount = 0.0
        
        guard let hrOutput = rawFilter.outputImage else {
            fatalError("Failed to generate image from RAW file.")
        }
        
        return hrOutput
    }
}


struct EncodeFromSensorNode: FilterNode {
    let baselineExposure: Float
    
    func apply(to input: CIImage) -> CIImage {
        let kernel = CIColorKernelCache.shared.encodeSensor
        let encoded = kernel.apply(
            extent: input.extent,
            roiCallback: { _, r in r },
            arguments: [input, baselineExposure]
        ) ?? input
        
        return encoded
    }
}


// MARK: - Temp and Tint Filter
struct TempAndTintNode: FilterNode {
    let targetTemp: Float
    let targetTint: Float
    let sourceTemp: Float
    let sourceTint: Float
    let convertToNeg: Bool
    
    func apply(to input: CIImage) -> CIImage {
        var tempUsed = targetTemp
        if convertToNeg {
            tempUsed += 1650.0
        }
        
        let filter = CIFilter.temperatureAndTint()
        filter.inputImage = input
        // May need to swap this with the target nuetral, this would be init temp / tint in old app
        filter.neutral = CIVector(x: CGFloat(sourceTemp), y: CGFloat(sourceTint))
        filter.targetNeutral = CIVector(x: CGFloat(tempUsed), y: CGFloat(targetTint))
        guard let result = filter.outputImage else {
            fatalError("Unable to apply temperature and tint filter")
        }
        return result
    }
}

// MARK: - Raw Exposure
struct RawExposureNode: FilterNode {

    let exposure: Float
    let convertToNeg: Bool
    let applyScanMode: Bool
    let bwMode: Bool
    let isLut: Bool
    
    func apply(to input: CIImage) -> CIImage {
        var exposureAdjusted = exposure
        if convertToNeg && !bwMode {
            exposureAdjusted += 2.0
        }
        
        if applyScanMode {
            exposureAdjusted += 2.0
        }
        
        let kernelInput: CIImage = input

        
        let kernel = CIColorKernelCache.shared.exposure
        let exposed = kernel.apply(
            extent: kernelInput.extent,
            roiCallback: { _, r in r },
            arguments: [kernelInput, exposureAdjusted]
        ) ?? kernelInput
        
        
        // Convert the result to Arri Log C 3
        return exposed
    }
}


// MARK: - Raw Contrast filter
struct RawContrastNode: FilterNode {

    let contrast: Float
    
    func apply(to input: CIImage) -> CIImage {
        let normalizedContrast = (contrast / 100.0)
        let kernel = CIColorKernelCache.shared.contrast
        return kernel.apply(
            extent: input.extent,
            roiCallback: { _, r in r },
            arguments: [input, normalizedContrast]
        ) ?? input
    }
}


// MARK: - Global Saturation filter

// NOTE: For some reason this node is adding a black border, only this node, it doesnt seem to respect the initial context, all others seem to be fine.
struct GlobalSaturationNode: FilterNode {

    let saturation: Float
    
    func apply(to input: CIImage) -> CIImage {
        
        let normalized = (saturation / 100.0) + 1.0
        let kernel = CIColorKernelCache.shared.globalSaturation
        
        // Step 1: Convert to spherical space using node
        let sphericalInput = input.clampedToExtent()
        
        // Step 2: Apply saturation in spherical space
        guard let saturated = kernel.apply(
            extent: sphericalInput.extent,
            roiCallback: { _, r in r },
            arguments: [sphericalInput, normalized]
        ) else {
            fatalError("GlobalSaturation kernel failed")
        }
        
        // Step 3: Convert back to RGB using node
        let result = saturated.clampedToExtent()
        
        //		print("\nGlobalSaturationNode Extent Debug:\n\nInput Extent: \(input.extent)\nSpherical Extent: \(sphericalInput.extent)\nSaturated Extent: \(saturated.extent)\nResult Extent: \(result.extent)")
        
        return result.cropped(to: input.extent)
    }
}

// MARK: - HDR Filter
struct HDRNode: FilterNode {

    let hdrWhite: Float
    let hdrHighlight: Float
    let hdrShadow: Float
    let hdrBlack: Float
    
    func apply(to input: CIImage) -> CIImage {
        // Normalize parameters by dividing by 100
        let normalizedWhite = hdrWhite / 100
        let normalizedHighlight = -(hdrHighlight / 100)
        let normalizedShadow = hdrShadow / 100
        let normalizedBlack = hdrBlack / 100
        
        
        // Apply HDR kernel (which expects LogC input)
        let kernel = CIColorKernelCache.shared.hdrKernel
        
        let arguments: [Any] = [
            input,
            normalizedWhite,
            normalizedHighlight,
            normalizedShadow,
            normalizedBlack
        ]
        
        guard let result = kernel.apply(
            extent: input.extent,
            roiCallback: { _, r in r },
            arguments: arguments
        ) else {
            fatalError("HDR kernel failed")
        }
        
        return result
    }
}

// MARK: - HSD Filter
struct HueSaturationDensityNode: FilterNode {

    // Input values for each color group
    let redHue: Float
    let redSat: Float
    let redDen: Float
    
    let greenHue: Float
    let greenSat: Float
    let greenDen: Float
    
    let blueHue: Float
    let blueSat: Float
    let blueDen: Float
    
    let cyanHue: Float
    let cyanSat: Float
    let cyanDen: Float
    
    let magentaHue: Float
    let magentaSat: Float
    let magentaDen: Float
    
    let yellowHue: Float
    let yellowSat: Float
    let yellowDen: Float
    
    func apply(to input: CIImage) -> CIImage {
        let hueScalar: Float = 0.000833
        
        
        let kernel = CIColorKernelCache.shared.hsdKernel
        let sphericalInput = input.clampedToExtent()
        
        let arguments: [Any] = [
            sphericalInput,
            
            (redHue / 2.0) * hueScalar, (redSat / 200) + 1, redDen / 200,
            (greenHue / 2.0) * hueScalar, (greenSat / 200) + 1, greenDen / 200,
            (blueHue / 2.0) * hueScalar, (blueSat / 200) + 1, blueDen / 200,
            (cyanHue / 2.0) * hueScalar, (cyanSat / 200) + 1, cyanDen / 200,
            (magentaHue / 2.0) * hueScalar, (magentaSat / 200) + 1, magentaDen / 200,
            (yellowHue / 2.0) * hueScalar, (yellowSat / 200) + 1, yellowDen / 200
        ]
        
        guard let result = kernel.apply(
            extent: sphericalInput.extent,
            roiCallback: { _, r in r },
            arguments: arguments
        ) else {
            fatalError("HSD kernel failed")
        }
        
        let sphericalResult = result.clampedToExtent()
        
        return sphericalResult.cropped(to: input.extent)
    }
}

/*
 Expects image in Spherical Coordinates.
 Color choices are:
 0 = Red
 1 = Green
 2 = Blue
 3 = Cyan
 4 = Magenta
 5 = Yellow
 */

struct PreviewHueRangeNode: FilterNode {
    let previewRed: Bool
    let previewGreen: Bool
    let previewBlue: Bool
    let previewCyan: Bool
    let previewMagenta: Bool
    let previewYellow: Bool
    
    func apply(to input: CIImage) -> CIImage {
        //		let spherical = input.clampedToExtent().RGBtoSpherical()
        
        // Determine the color choice
        let colorChoice: Int
        if previewRed {
            colorChoice = 0
        } else if previewGreen {
            colorChoice = 1
        } else if previewBlue {
            colorChoice = 2
        } else if previewCyan {
            colorChoice = 3
        } else if previewMagenta {
            colorChoice = 4
        } else if previewYellow {
            colorChoice = 5
        } else {
            return input
        }
        
        let kernel = CIColorKernelCache.shared.previewHSD
        guard let maskImage = kernel.apply(
            extent: input.extent,
            roiCallback: { _, r in r },
            arguments: [input, colorChoice]
        ) else {
            fatalError("Kernel apply failed")
        }
        
        
        // Blend original image and gray using mask alpha
        let gray = CIImage(color: CIColor(red: 0.391, green: 0.391, blue: 0.391, alpha: 1))
            .cropped(to: input.extent)
        
        
        let final = input.blendWithMask(maskImage, gray)
        
        return final.cropped(to: input.extent)
    }
}


