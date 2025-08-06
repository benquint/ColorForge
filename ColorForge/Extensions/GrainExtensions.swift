//
//  GrainExtensions.swift
//  ColorForge
//
//  Created by Ben Quinton on 11/07/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins

extension CIImage {
	
	
	// MARK: - New Sampler based
	
	
	func applySamplerGrain(
		numIterations: Int,
		grainRadiusMean: Float,
		grainRadiusStd: Float,
		sigma: Float,
		seed: Int
	) -> CIImage {
		
		// Helper function to generate Gaussian random numbers using Box-Muller transform
		func generateGaussianRandom(mean: Float, stdDev: Float) -> Float {
			let u1 = Float.random(in: 0.0...1.0)
			let u2 = Float.random(in: 0.0...1.0)
			
			let z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * Float.pi * u2)
			// Adjust for mean and standard deviation
			return z0 * stdDev + mean
		}
		
		let width = Int(self.extent.width)
		let height = Int(self.extent.height)
		
		print("\n\n Realistic Film Grain Kernel Debug:\n Image dimensions: \(width)x\(height)")
		
		let ag: Float = 1.0 / ceil(1.0 / grainRadiusMean)
		print("\n\n Realistic Film Grain Kernel Debug:\n Adjusted grain factor (ag): \(ag)")
		
		// Initialize arrays for lambda and exp_lambda
		var lambda = [Float](repeating: 0.0, count: 256)
		var exp_lambda = [Float](repeating: 0.0, count: 256)
		
		// Calculate lambda and exp_lambda
		for i in 0..<256 {
//			lambda[i] = -((ag * ag) / (
//				Float.pi * (grainRadiusMean * grainRadiusMean + grainRadiusStd * grainRadiusStd)
//			)) * log((255.0 - Float(i)) / 255.1)
			
			let logTerm = max((255.0 - Float(i)) / 255.1, 1e-6)
			lambda[i] = -((ag * ag) / (
				Float.pi * (grainRadiusMean * grainRadiusMean + grainRadiusStd * grainRadiusStd)
			)) * log(logTerm)
			
			exp_lambda[i] = exp(-lambda[i])
		}
		print("\n\n Realistic Film Grain Kernel Debug:\n Lambda[0] = \(lambda.first ?? 0), Lambda[255] = \(lambda.last ?? 0)")
		print("\n\n Realistic Film Grain Kernel Debug:\n expLambda[0] = \(exp_lambda.first ?? 0), expLambda[255] = \(exp_lambda.last ?? 0)")
		
		var x_gaussian = [Float](repeating: 0.0, count: numIterations)
		var y_gaussian = [Float](repeating: 0.0, count: numIterations)
		
		for i in 0..<numIterations {
			x_gaussian[i] = generateGaussianRandom(mean: 0.0, stdDev: sigma)
			y_gaussian[i] = generateGaussianRandom(mean: 0.0, stdDev: sigma)
		}
		print("\n\n Realistic Film Grain Kernel Debug:\n First 5 xGaussian: \(x_gaussian.prefix(5))")
		print("\n\n Realistic Film Grain Kernel Debug:\n First 5 yGaussian: \(y_gaussian.prefix(5))")
		
//		let lambdaData = Data(bytes: &lambda, count: lambda.count * MemoryLayout<Float>.size) as NSData
//		let expLambdaData = Data(bytes: &exp_lambda, count: exp_lambda.count * MemoryLayout<Float>.size) as NSData
//		let xGaussianData = Data(bytes: &x_gaussian, count: x_gaussian.count * MemoryLayout<Float>.size) as NSData
//		let yGaussianData = Data(bytes: &y_gaussian, count: y_gaussian.count * MemoryLayout<Float>.size) as NSData
		
		let lambdaData = lambda.withUnsafeBufferPointer { Data(buffer: $0) }
		let expLambdaData = exp_lambda.withUnsafeBufferPointer { Data(buffer: $0) }
		let xGaussianData = x_gaussian.withUnsafeBufferPointer { Data(buffer: $0) }
		let yGaussianData = y_gaussian.withUnsafeBufferPointer { Data(buffer: $0) }
		
		print("\n\n Realistic Film Grain Kernel Debug:\n Prepared data buffers (lambda: \(lambda.count), xGaussian: \(x_gaussian.count))")
		print("\n\n Realistic Film Grain Kernel Debug:\n numIterations = \(numIterations), grainRadiusMean = \(grainRadiusMean), grainRadiusStd = \(grainRadiusStd), sigma = \(sigma), seed = \(seed)")
		
		let sampler = CISampler(image: self)
		let kernel = CIColorKernelCache.shared.realisticFilmGrain
		
		guard let grain = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [
				sampler,
				width, height,
				numIterations,
				grainRadiusMean,
				grainRadiusStd,
				sigma,
				seed,
				lambdaData,
				expLambdaData,
				xGaussianData,
				yGaussianData
			]
		) else {
			print("\n\n Realistic Film Grain Kernel Debug:\n Kernel failed to apply — returning original image")
			return self
		}
		
		print("\n\n Realistic Film Grain Kernel Debug:\n Kernel applied successfully — returning grain image")
		return grain
	}
	
	
    
	
	// MARK: - OLD
    
    func modifyNoise( _ baseBlur: Float, _ blurPasses: Int) -> CIImage {
        let filter = CIFilter.colorMonochrome()
        filter.inputImage = self
        filter.color = CIColor(red: 0.5, green: 0.5, blue: 0.5)
        filter.intensity = 1
        guard let desat = filter.outputImage else {return self}
        
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = desat
        contrastFilter.contrast = 0.1
        guard let lowContrast = contrastFilter.outputImage else {return desat}
        
        let blurFilter = CIFilter.gaussianBlur()
        blurFilter.inputImage = lowContrast
        blurFilter.radius = 0.2
        guard let blurred = blurFilter.outputImage else {return lowContrast}
        
        
        let result = blurred.blurAndBlendLooped(baseBlur, blurPasses)
        
        return result
    }
    
    
    func blurAndBlendLooped( _ initialBlurVal: Float, _ passes: Int) -> CIImage {
        var currentImage = self
        let powVal = 1.0 + initialBlurVal
        
        var nextBlurVal = initialBlurVal
        
        for _ in 0..<passes {
            
            let blendVal = (1.0 - pow(nextBlurVal, powVal)) * 100.0
            
            let blurFilter = CIFilter.gaussianBlur()
            blurFilter.inputImage = currentImage
            blurFilter.radius = nextBlurVal
            guard let blurred = blurFilter.outputImage else {
                return self // fallback to last good image
            }
            
            let sharpenFilter = CIFilter.unsharpMask()
            sharpenFilter.inputImage = blurred
            sharpenFilter.radius = nextBlurVal / 2.0
            sharpenFilter.intensity = 0.1
            guard let sharpened = sharpenFilter.outputImage else {
                return self
            }
            
            
            
            nextBlurVal = pow(nextBlurVal, (1.0 / powVal))
            
            currentImage = self.blendWithOpacityPercent(sharpened, blendVal)
            
  
        }
        
        return currentImage
        
    }
    
    
    func blendWithSmoothStep(_ noise: CIImage, _ maskImage: CIImage, _ fade: Float, _ lowStep: Float, _ highStep: Float) -> CIImage {
        let kernel = CIColorKernelCache.shared.smoothStepMetal
        
        guard let result = kernel.apply(
            extent: self.extent,
            roiCallback: { _, rect in rect },
            arguments: [self, noise, maskImage, fade, lowStep, highStep]
        ) else {return self}
        
        return result
    }
    
    /*
     let kernel = CIColorKernelCache.shared.decodeCineon
     guard let linear = kernel.apply(
         extent: self.extent,
         roiCallback: { _, rect in rect },
         arguments: [self]
     ) else {return self}
     
     let tonemapped = linear.toneMapLin()
     let displayGamma = tonemapped.encodeGamma22()
     
     return displayGamma
 }
     */
	
    
}
