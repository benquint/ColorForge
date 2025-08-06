//
//  MaskExtensions.swift
//  ColorForge
//
//  Created by admin on 27/06/2025.
//


import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI


extension CIImage {

	func linearGradientExtension(_ start: CGPoint, _ end: CGPoint) -> CIImage {
		let linearGradient = CIFilter.linearGradient()
		linearGradient.point0 = start
		linearGradient.point1 = end
		linearGradient.color0 = CIColor(red: 1, green: 0, blue: 0, alpha: 1)
		linearGradient.color1 = CIColor(red: 1, green: 0, blue: 0, alpha: 0)
		guard let mask = linearGradient.outputImage else {
			print("Failed to generate linear gradient")
			return self
		}
		
		print("Generated linear gradient from \(start) to \(end), mask extent: \(mask.extent)")
		
		return mask.cropped(to: self.extent)
	}
    
    
	func applyLinearGradientAndBlend(
		_ start: CGPoint,
		_ end: CGPoint,
		_ backgroundImage: CIImage
	) -> CIImage {

        let mask = self.createDitheredMaskImage(start, end)
        
        print("Mask Extent")
        
		let filter = CIFilter.blendWithMask()
		filter.inputImage = self
		filter.backgroundImage = backgroundImage
		filter.maskImage = mask
		

		guard let result = filter.outputImage else {
			fatalError("BlendWithMask kernel failed")
		}


		return result
	}
    
    
    func createDitheredMaskImage( _ start: CGPoint, _ end: CGPoint) -> CIImage {
        let white = CIImage(color: .white).cropped(to: self.extent)
        let black = CIImage(color: .black).cropped(to: self.extent)
        
        let linearGradient = CIFilter.linearGradient()
        linearGradient.point0 = start
        linearGradient.point1 = end
        linearGradient.color0 = CIColor.white
        linearGradient.color1 = CIColor.black
        
        let filter = CIFilter.blendWithMask()
        filter.inputImage = white
        filter.backgroundImage = black
        filter.maskImage = linearGradient.outputImage
        guard let mask = filter.outputImage else {return self}
		
        
        let kernel = CIColorKernelCache.shared.applySigmoidSmoothing

        
       guard let result = kernel.apply(
            extent: self.extent,
            roiCallback: { _, rect in rect },
            arguments: [mask]
        ) else {
            print("Failed to apply the sigmoid function to mask")
            return self}
        
        return result
    }
    
    func applyRadialMask(
        _ baseImage: CIImage,
        _ start: CGPoint, // center point
        _ width: CGFloat,
        _ height: CGFloat,
        _ feather: Float, // 0–100
        _ invert: Bool,
        _ opacity: Float
    ) -> CIImage {
        
        
        
        let rectRadius = min(width, height) / 2.0
        let radius0 = rectRadius * (1 - CGFloat(feather / 100))
        let radius1 = rectRadius

        // Step 1: Create circular radial gradient
        let radialGradient = CIFilter.radialGradient()
        radialGradient.center = CGPoint(x: 0, y: 0)
        radialGradient.radius0 = Float(radius0)
        radialGradient.radius1 = Float(radius1)
        radialGradient.color0 = CIColor.white
        radialGradient.color1 = CIColor.clear

        guard var mask = radialGradient.outputImage else {
            return self
        }

        // Step 2: Crop to bounding rect
        let cropRect = CGRect(x: -radius1, y: -radius1, width: radius1 * 2, height: radius1 * 2)
        mask = mask.cropped(to: cropRect)
		
		

        // Step 3: Scale to ellipse
        let scaleX = width / (radius1 * 2)
        let scaleY = height / (radius1 * 2)
        mask = mask.transformed(by: .init(scaleX: scaleX, y: scaleY))

        // Step 4: Translate to center
        mask = mask.transformed(by: .init(translationX: start.x, y: start.y))

		print("DEBUG MASK: Mask extent in extension = \(mask.extent)")

        // Step 6: Apply opacity (affects alpha channel)
        if opacity < 100 {
			
			mask = mask.applyingFilter("CIColorInvert")
            mask = mask.applyingFilter("CIColorMatrix", parameters: [
                "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(opacity) / 100)
            ])
			mask = mask.applyingFilter("CIColorInvert")
        }

        // Step 7: Composite onto black background
        let black = CIImage(color: .black).cropped(to: baseImage.extent)
        var fullMask = mask.composited(over: black)
		
		
		let kernel = CIColorKernelCache.shared.applySigmoidSmoothing
		
	   guard let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [fullMask]
		) else {
			print("Failed to apply the sigmoid function to mask")
			return self}
		
		
		fullMask = result
//        if let data = inverseData {
//            fullMask = colorCurves(data)
//        }
		

        
        
//		let kernel = CIColorKernelCache.shared.softenMask
//		
//	   guard let gammaAdjusted = kernel.apply(
//			extent: self.extent,
//			roiCallback: { _, rect in rect },
//			arguments: [fullMask]
//		) else {
//			print("Failed to convert image to capture one")
//			return self}
//		
//		fullMask = gammaAdjusted
		
        
        // Step 5: Invert if needed
        if invert {
            fullMask = fullMask.applyingFilter("CIColorInvert")
        }
		
		

        // Step 8: Blend with original using mask
        return self.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputBackgroundImageKey: baseImage,
            kCIInputMaskImageKey: fullMask
        ]).cropped(to: baseImage.extent)
    }
    
	
//	func applyLutAndNormaliseGradient(_ lutData: Data) -> {
//		let base = self
//		let filterApplied = base.applyLutData(lutData)
//		
//		
//		
//		
//	}
    

}


extension FilterNodeMaskable {
	func applyMasked(to input: CIImage) -> CIImage {
		guard isMask,
			  let mask = maskData as? ImageItem.LinearGradientMask else {
			print("""
				Masking Extension: No mask
				""")
			return apply(to: input)
		}
		
		// Base result of the masked effect
		let maskedEffect = apply(to: input)
		
		let applied = maskedEffect.applyLinearGradientAndBlend(mask.startPoint, mask.endPoint, input)
		
		
		// Apply linear gradient blend
		return applied.cropped(to: input.extent)
	}
}
