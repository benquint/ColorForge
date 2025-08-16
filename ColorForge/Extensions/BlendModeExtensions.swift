//
//  BlendModeExtensions.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins


extension CIImage {
	
	// Blend two images, with opacity value 0-100
	func blendWithOpacityPercent(_ foregroundImage: CIImage, _ opacity: Float) -> CIImage {
		let normalizedOpacity = min(max(opacity / 100.0, 0.0), 1.0)
		let kernel = CIColorKernelCache.shared.blendWithOpacity
		return kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self, foregroundImage, normalizedOpacity]
		) ?? self
	}
	
	// Add and blend
	func addAndBlend(_ blendVal: Float, _ addImage: CIImage) -> CIImage {
		let addResult = self.add(addImage)
		let blend = self.blendWithOpacityPercent(addResult, blendVal)
		return blend
	}
	
	// Subtract blend mode: inputImage - backgroundImage
	func subtract(_ subtractImage: CIImage) -> CIImage {
		guard let filter = CIFilter(name: "CISubtractBlendMode") else {
			print("CISubtractBlendMode filter not available")
			return self
		}
		filter.setValue(subtractImage, forKey: kCIInputImageKey)
		filter.setValue(self, forKey: kCIInputBackgroundImageKey)
        
        guard let result = filter.outputImage else {return self}
        
        return result
	}
    
    
    
    func add(_ addImage: CIImage) -> CIImage {
        let kernel = CIColorKernelCache.shared.addTwoImages
        return kernel.apply(
            extent: self.extent,
            roiCallback: { _, rect in rect },
            arguments: [self, addImage]
        ) ?? self
    }

	func overlayBlend(_ blendImage: CIImage) -> CIImage {
		let filter = CIFilter.overlayBlendMode()
		filter.inputImage = self
		filter.backgroundImage = blendImage
		guard let result = filter.outputImage else {
			fatalError("OverlayBlendMode kernel failed")
		}
		return result
	}
    
    func arriOverlay(_ blendImage: CIImage) -> CIImage {
        let kernel = CIColorKernelCache.shared.arriOverlayBlend
        return kernel.apply(
            extent: self.extent,
            roiCallback: { _, rect in rect },
            arguments: [self, blendImage]
        ) ?? self
    }
    
    func arriSoftLight(_ blendImage: CIImage) -> CIImage {
        let kernel = CIColorKernelCache.shared.arriSoftLightBlend
        return kernel.apply(
            extent: self.extent,
            roiCallback: {$1},
            arguments: [self, blendImage]
        ) ?? self
    }
	
	func softlightBlend(_ blendImage: CIImage) -> CIImage {
		let filter = CIFilter.softLightBlendMode()
		filter.inputImage = self
		filter.backgroundImage = blendImage
		guard let result = filter.outputImage else {
			fatalError("OverlayBlendMode kernel failed")
		}
		return result
	}
	
	func blendWithMask(_ maskImage: CIImage, _ foregroundImage: CIImage) -> CIImage {
		let filter = CIFilter.blendWithMask()
		filter.inputImage = foregroundImage
		filter.backgroundImage = self
		filter.maskImage = maskImage
		guard let result = filter.outputImage else {
			fatalError("BlendWithMask kernel failed")
		}
		return result
		
	}
    
    func metalMask(_ maskImage: CIImage, _ foregroundImage: CIImage) -> CIImage {
        
        let baseCropped = self.crop(self.extent)
        let foreGroundCropped = foregroundImage.crop(self.extent)
        let maskCropped = maskImage.crop(self.extent)
        
        let width: Float = Float(self.extent.width)
        let height: Float = Float(self.extent.height)

        let kernel = CIColorKernelCache.shared.blendWithMaskMetal
        guard let result = kernel.apply(
            extent: self.extent,
            roiCallback: { _, _ in self.extent },
            arguments: [baseCropped, foreGroundCropped, maskCropped, width, height]
        ) else {
            print("Metal masking failed")
            return self
        }
        
        let resultCropped = result.crop(self.extent)
        
        print("THOG Masked Final Extent = \(resultCropped.extent)")
        
        return resultCropped.crop(self.extent)
    }
    
    func colorBlendMode(_ foregroundImage: CIImage) -> CIImage {
        let colorBlendModeFilter = CIFilter.colorBlendMode()
        colorBlendModeFilter.inputImage = foregroundImage
        colorBlendModeFilter.backgroundImage = self
        return colorBlendModeFilter.outputImage!
    }
    
    func mixGrainAndApply(_ grainLow: CIImage, _ grainHigh: CIImage, _ amount: Float) -> CIImage {
        let kernel = CIColorKernelCache.shared.mixGrainAndApply
        guard let result = kernel.apply(
            extent: self.extent,
            roiCallback: { _, _ in self.extent },
            arguments: [self, grainLow, grainHigh, amount]
        ) else {
            print("Metal masking failed")
            return self
        }
        return result
        
    }
    
    func blendWithMaskBackground(_ maskImage: CIImage, _ backgroundImage: CIImage) -> CIImage {
        let filter = CIFilter.blendWithMask()
        filter.inputImage = self
        filter.backgroundImage = backgroundImage
        filter.maskImage = maskImage
        guard let result = filter.outputImage else {
            fatalError("BlendWithMask kernel failed")
        }
        return result
        
    }
    
    
    func multiply(_ multiplyImage: CIImage) -> CIImage {
        let kernel = CIColorKernelCache.shared.multiplyTwoImages
        return kernel.apply(
            extent: self.extent,
            roiCallback: { _, rect in rect },
            arguments: [self, multiplyImage]
        ) ?? self
    }
  
	
	func multiplyByVal(_ value: Float, _ channel: Int) -> CIImage {
		let kernel = CIColorKernelCache.shared.multiplyByValue
		return kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self, value, channel]
		) ?? self
	}
	
	func scaleWP_BP() -> CIImage {
		let kernel = CIColorKernelCache.shared.scaleWP_BP
		return kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) ?? self
	}
    
    func mixNoise(_ noise2: CIImage, _ noise3: CIImage, _ size: Float) -> CIImage {
        let kernel = CIColorKernelCache.shared.perlinNoiseMix
        return kernel.apply(
            extent: self.extent,
            roiCallback: {$1},
            arguments: [self, noise2, noise3, size]
        ) ?? self
    }
}
