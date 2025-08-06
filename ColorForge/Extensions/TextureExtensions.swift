//
//  TextureExtensions.swift
//  ColorForge
//
//  Created by admin on 30/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

extension CIImage {
	
	
	// MARK: - Blur Extensions
	
	func applyBlurAndComposite(_ blurRadius: CGFloat, _ blendSource: CIImage, _ opacity: Float) -> CIImage? {
		
		var input = self
		
		// Step 1: Clamp the edges of the input image
		let clampedImage = input.clampedToExtent()

		
		let blurredImage = clampedImage.gaussianBlur(blurRadius)
		
		// Insert a cacheable intermediate for the blurred image
		let cachedBlurredImage = blurredImage
		
		// Crop blurred image to input extent
		let croppedBlurredImage = cachedBlurredImage
		
		// Create an alpha mask
		let alphaFilter = CIFilter(name: "CIConstantColorGenerator")!
		alphaFilter.setValue(CIColor(red: 1, green: 1, blue: 1, alpha: CGFloat(opacity)), forKey: kCIInputColorKey)
		
		guard let alphaImage = alphaFilter.outputImage else {
			print("Failed to create alpha image")
			return nil
		}
		
		// Blend the blurred image with the alpha mask
		let blendWithAlphaFilter = CIFilter(name: "CIMultiplyCompositing")!
		blendWithAlphaFilter.setValue(croppedBlurredImage, forKey: kCIInputImageKey)
		blendWithAlphaFilter.setValue(alphaImage, forKey: kCIInputBackgroundImageKey)
		
		guard let blurredWithAlphaImage = blendWithAlphaFilter.outputImage else {
			print("Failed to apply multiply blend with alpha")
			return nil
		}
		
		// Insert a cacheable intermediate for the alpha-blended image
		let cachedBlurredWithAlphaImage = blurredWithAlphaImage/*.insertingIntermediate(cache: true)*/
		
		// Composite the result over the blendSource
		let blendFilter = CIFilter(name: "CISourceOverCompositing")!
		blendFilter.setValue(cachedBlurredWithAlphaImage, forKey: kCIInputImageKey)
		blendFilter.setValue(blendSource, forKey: kCIInputBackgroundImageKey)
		
		// With Caching
		if let compositeImage = blendFilter.outputImage {
			return compositeImage
		} else {
			print("Failed to composite image")
			return nil
		}
	}
	
	func outputBlur() -> CIImage {
		let filter = CIFilter.gaussianBlur()
		filter.inputImage = self
		filter.radius = 0.8
		guard let result = filter.outputImage else {
			fatalError("outputBlur extension failed")
		}
		return result
	}
	
//	func blurAndFade(_ blurVal: CGFloat, _ opacity: Float) -> CIImage {
//		let blurred = self.gaussianBlur(blurVal)
//		let blend = self.blendWithOpacityPercent(blurred, opacity)
//		return blend
//	}
	
	func blurAndFade(_ blurVal: CGFloat, _ opacity: Float, extent: CGRect) -> CIImage {
		let blurred = self.gaussianBlur(blurVal).cropped(to: extent)
		let blend = self.blendWithOpacityPercent(blurred, opacity)
		return blend
	}
	
	func gaussianBlur(_ blurVal: CGFloat) -> CIImage {
		let inputImage = self.clampedToExtent()
		let log = inputImage.LogC2Lin()
		let filter = CIFilter.gaussianBlur()
		filter.inputImage = log
		filter.radius = Float(blurVal)
		guard let result = filter.outputImage else {
			fatalError("GuassianBlur extension failed")
		}
		return result.Lin2LogC()
	}
	
	func blurHald(_ blurVal: CGFloat) -> CIImage {
		let inputImage = self.clampedToExtent()
		let filter = CIFilter.gaussianBlur()
		filter.inputImage = inputImage
		filter.radius = Float(blurVal)
		guard let result = filter.outputImage else {
			fatalError("GuassianBlur extension failed")
		}
		return result.cropped(to: self.extent)
	}
	
	func blurAndDesaturate(_ blurRadius: CGFloat) -> CIImage {
		let inputImage = self.clampedToExtent()
		let filter1 = CIFilter.gaussianBlur()
		filter1.inputImage = self
		filter1.radius = Float(blurRadius)
		guard let result = filter1.outputImage else {
			fatalError("GuassianBlur extension failed")
		}
		
		let filter2 = CIFilter.colorControls()
		filter2.inputImage = result
		filter2.saturation = 0
		guard let finalResult = filter2.outputImage else {
			fatalError("GuassianBlur extension failed")
		}
		return finalResult
	}
	
	func boxBlur(_ blurVal: CGFloat) -> CIImage {
		let filter = CIFilter.boxBlur()
		filter.inputImage = self
		filter.radius = Float(blurVal)
		guard let result = filter.outputImage else {
			fatalError("GuassianBlur extension failed")
		}
		return result
	}
	
	
	
	// MARK: - Sharpen Extensions
	
	func unsharpMask(_ radius: Float, _ amount: Float) -> CIImage {
		let filter = CIFilter.unsharpMask()
		filter.inputImage = self
		filter.intensity = amount
		filter.radius = radius
		guard let result = filter.outputImage else {
			fatalError("UnsharpMask extension failed")
		}
		return result
	}
	
	// MARK: - Noise / Dithering
	func dither(_ amount: Float) -> CIImage {
		let filter = CIFilter.dither()
		filter.inputImage = self
		filter.intensity = amount
		guard let result = filter.outputImage else {
			fatalError("Dither extension failed")
		}
		return result
	}
	

	
	// MARK: - Tile Grain Plates for Export

	
	func tiledToCover(_ targetSize: CGSize) -> CIImage {
		// Crop to square if needed (grain plates are square)
		let grain = self.cropped(to: CGRect(
			x: 0,
			y: 0,
			width: min(self.extent.width, self.extent.height),
			height: min(self.extent.width, self.extent.height)
		))
		
		// Create the mask with edge blur
		let foreground = CIImage(color: .white).cropped(to: grain.extent)
		let background = CIImage(color: .black).cropped(to: grain.extent)
		let blur: CGFloat = 10.0
		let mask = foreground.gaussianBlur(blur).composited(over: background).cropped(to: background.extent)

		// Masked grain plate
		let clear = CIImage(color: .clear).cropped(to: background.extent)
		let maskedGrain = clear.blendWithMask(mask, grain)

		let xShift = grain.extent.width
		let yShift = grain.extent.height
		let tileAmountX = Int(ceil(targetSize.width / xShift))
		let tileAmountY = Int(ceil(targetSize.height / yShift))
		
		// Output canvas
		var output = CIImage(color: .gray).cropped(to: CGRect(origin: .zero, size: targetSize))

		// Tile row-by-row
		for row in 0..<tileAmountY {
			let yOffset = CGFloat(row) * yShift
			for col in 0..<tileAmountX {
				let xOffset = CGFloat(col) * xShift
				let transform = CGAffineTransform(translationX: xOffset, y: yOffset)
				let shifted = maskedGrain.transformed(by: transform)
				output = shifted.composited(over: output)
			}
		}
		
		return output.cropped(to: CGRect(origin: .zero, size: targetSize))
	}

    // MARK: - Noise
    
    func perlinColor(_ scale: Float, _ variance: Float, _ amount: Float) -> CIImage {
        let width = self.extent.width
        let height = self.extent.height
    
        let safeInput = self.clampedToExtent()
        
        let varianceNorm = variance / 100.0
        
        let xyMax = 1.0 * variance
        
        let x = Float.random(in: 0...xyMax)
        let y = Float.random(in: 0...xyMax)

        let kernel = CIColorKernelCache.shared.perlinNoiseColorGradient
        
        guard let noise = kernel.apply(
            extent: self.extent,
            roiCallback: {$1},
            arguments: [safeInput, width, height, scale, x, y, amount]
        ) else {
            fatalError("Perlin Noise Color kernel failed")
        }
                print("THOG Noise Final Extent = \(noise.extent)")
        
        let noiseCropped = noise.cropped(to: self.extent)
        

        
        
        return noiseCropped
    }
    
    func perlinNoise(_ scale: Float, _ offsetX: Float, _ offsetY: Float) -> CIImage {
        let width = self.extent.width
        let height = self.extent.height
        
        let x = offsetX / 100.0
        let y = offsetY / 100.0
        
        let kernel = CIColorKernelCache.shared.perlinNoise
        
        guard let noise = kernel.apply(
            extent: self.extent,
            roiCallback: { _, _ in self.extent },
            arguments: [self, width, height, scale, x, y]
        ) else {
            fatalError("Perlin Noise kernel failed")
        }
        
        
        let noiseCropped = noise.crop(self.extent)
        
        print("THOG Noise Final Extent = \(noiseCropped.extent)")
        
        
        return noiseCropped
    }
    
    func randGradient() -> CIImage {
        let canvas = CIImage.clear.crop(self.extent)
        let width = self.extent.width
        let height = self.extent.height
        
        // Randomly pick and X / Y coord
        let randX = CGFloat.random(in: 0...width)
//        let randY = CGFloat.random(in: 0...height)
        
        let randGreen = CGFloat.random(in: 0...0.2)
        let randBlue = CGFloat.random(in: 0...0.2)
        
        let filter = CIFilter.linearGradient()
        filter.point0 = CGPoint(x: 10.0, y: 0)
        filter.point1 = CGPoint(x: width, y: height)
        filter.color0 = CIColor(red: 0, green: 0.3, blue: 0)
        filter.color1 = CIColor(red: 0.1, green: 0.05, blue: 0.3)
        guard let gradient = filter.outputImage else {
            print("Gradient Failed")
            return self
        }
        
        let final = gradient.composited(over: canvas)
        
        let finalCropped = final.crop(self.extent)
        
        print("THOG Gradient Final Extent = \(finalCropped.extent)")
        
        return finalCropped
    }
    
	
	// MARK: - Print Halation
	
	func applyGaussianBlurAndComposite(blurRadius: CGFloat, blendSource: CIImage, opacity: Float) -> CIImage {
		// Clamp edges to prevent blur effect from spreading outside the image bounds
		let input = self
		
		let clampedImage = input
		
		guard let gaussianBlurFilter = CIFilter(name: "CIGaussianBlur") else { return self }
		gaussianBlurFilter.setValue(clampedImage, forKey: kCIInputImageKey)
		gaussianBlurFilter.setValue(blurRadius, forKey: kCIInputRadiusKey)
		
		guard let blurredImage = gaussianBlurFilter.outputImage else {
			print("Failed to apply Gaussian Blur")
			return self
		}
		
		// Create an alpha image using CIConstantColorGenerator
		let alphaFilter = CIFilter(name: "CIConstantColorGenerator")!
		alphaFilter.setValue(CIColor(red: 1, green: 1, blue: 1, alpha: CGFloat(opacity)), forKey: kCIInputColorKey)
		
		guard let alphaImage = alphaFilter.outputImage else {
			print("Failed to create alpha image")
			return self
		}
		
		// Blend the blurred image with the alpha image
		let blendWithAlphaFilter = CIFilter(name: "CIMultiplyCompositing")!
		blendWithAlphaFilter.setValue(blurredImage, forKey: kCIInputImageKey)
		blendWithAlphaFilter.setValue(alphaImage, forKey: kCIInputBackgroundImageKey)
		
		guard let blurredWithAlphaImage = blendWithAlphaFilter.outputImage else {
			print("Failed to apply multiply blend with alpha")
			return self
		}
		
		// Composite the result over the blendSource
		let blendFilter = CIFilter(name: "CISourceOverCompositing")
		blendFilter?.setValue(blurredWithAlphaImage, forKey: kCIInputImageKey)
		blendFilter?.setValue(blendSource, forKey: kCIInputBackgroundImageKey)
		
		if let compositeImage = blendFilter?.outputImage {
			return compositeImage // Crop back to original extent
		} else {
			print("Failed to composite image")
			return self
		}
	}
	
	// MARK: - Grain July25
    
   
	
	
	
	
}
