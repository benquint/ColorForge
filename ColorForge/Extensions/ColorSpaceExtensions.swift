//
//  ColorSpaceExtensions.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import simd

extension CIImage {


	func replaceResultWithHald() -> CIImage {
		guard let url = Bundle.main.url(forResource: "CMS_arri", withExtension: "png") else {
			return self
		}
		guard let ciImage = CIImage(contentsOf: url) else {return self}
		
		return ciImage
	}
	
	// Copy selected channel to all the others
	func copyChannel(_ channel: Int) -> CIImage {
		let kernel = CIColorKernelCache.shared.copyChannel
		guard let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self, channel]
		) else {
			print("Failed to convert image to capture one")
			return self}
		return result
	}
	
    // Invert Color
    func invertColor() -> CIImage {
        let filter = CIFilter.colorInvert()
        filter.inputImage = self
        guard let result = filter.outputImage else {
            print("Color Invert Failed")
            return self
        }
        return result
    }
	
    func getBins() -> CIImage {
        let filter = CIFilter.areaHistogram()
        filter.inputImage = self
        filter.count = 128
        filter.scale = 50
        filter.extent = self.extent
        return filter.outputImage!
    }

    
    // MARK: - Convert to capture one input
    
    func convertToCaptureOneInput() -> CIImage {
        let kernel = CIColorKernelCache.shared.convertToC1
        guard let result = kernel.apply(
            extent: self.extent,
            roiCallback: { _, rect in rect },
            arguments: [self]
        ) else {
            print("Failed to convert image to capture one")
            return self}
        return result
    }
    
    func c1ToColorForge() -> CIImage {
        let kernel = CIColorKernelCache.shared.c1ToColorForge
        guard let result = kernel.apply(
            extent: self.extent,
            roiCallback: { _, rect in rect },
            arguments: [self]
        ) else {
            print("Failed to convert image to capture one")
            return self}
        return result
    }
    
    func filmStandard_to_linear() -> CIImage {
        let kernel = CIColorKernelCache.shared.filmStandardToLinear
        guard let result = kernel.apply(
            extent: self.extent,
            roiCallback: { _, rect in rect },
            arguments: [self]
        ) else {
            print("Failed to convert image to capture one")
            return self}
        return result
    }
	
	func scale0to1(
		_ wr: Float, _ wg: Float, _ wb: Float,
		_ br: Float, _ bg: Float, _ bb: Float
	) -> CIImage {
		let kernel = CIColorKernelCache.shared.scale0to1
		guard let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self, wr, wg, wb, br, bg, bb]
		) else {
			print("Failed to scale 0 - 1")
			return self}
		return result
	}
    
    func applyLift(_ lift: Float) -> CIImage {
        let kernel = CIColorKernelCache.shared.lift
        guard let result = kernel.apply(
            extent: self.extent,
            roiCallback: { _, _ in self.extent },
            arguments: [self, lift]
        ) else {return self}
        return result
    }
    
    
	// MARK: - ColorSpace Conversions
	
	func map_to_0_1() -> CIImage {
		let kernel = CIColorKernelCache.shared.mapOutputValues
		guard let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) else {return self}
		return result
	}
	
	func applyMatrix(_ rVector: CIVector, _ gVector: CIVector, _ bVector: CIVector, _ aVector: CIVector) -> CIImage {
		let filter = CIFilter.colorMatrix()
		filter.rVector = rVector
		filter.gVector = gVector
		filter.bVector = bVector
		filter.aVector = aVector
		return filter.outputImage ?? self
		
	}
    
	
	// Return channel, 0 for Red, 1 for Green, 2 for Blue and inverts
	func returnChannel(_ channel: Int) -> CIImage {
		let kernel = CIColorKernelCache.shared.returnChannelAndInvert
		guard let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self, channel]
		) else {return self}
		return result
	}
	
	
	// Convert to lab (normalised)
	func RGBtoLAB() -> CIImage {
		let convertRGBToLabFilter = CIFilter.convertRGBtoLab()
		convertRGBToLabFilter.inputImage = self
		convertRGBToLabFilter.normalize = true
		return convertRGBToLabFilter.outputImage!
	}
	
	func LABtoRGB() -> CIImage {
		let filter = CIFilter.convertLabToRGB()
		filter.inputImage = self
		filter.normalize = true
		return filter.outputImage!
	}

	
	// Converts from Arri Wide Gamut 3 to AdobeRGB
	func awg3ToAdobeRGB() -> CIImage {
		let filter = CIFilter.colorMatrix()
		filter.inputImage = self
		
		filter.rVector = CIVector(x: 1.136628, y: -0.004030, z: -0.132598, w: 0.0)
		filter.gVector = CIVector(x: -0.070573, y: 1.334613, z: -0.264040, w: 0.0)
		filter.bVector = CIVector(x: -0.023138, y: -0.162677, z: 1.185815, w: 0.0)
		filter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1) // Alpha unchanged
		filter.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0) // No bias
		
		guard let output = filter.outputImage else {
			fatalError("Failed to apply Arri Wide Gamut 3 to Adobe RGB matrix")
		}
		
		return output
	}
	
	// Converts the image from Display P3 (D65) to Arri Wide Gamut 3 using a color matrix
	func P3ToAWG() -> CIImage {
		let filter = CIFilter.colorMatrix()
		filter.inputImage = self
		
		// Each vector is a row of the matrix: [R_in, G_in, B_in, A_in]
		filter.rVector = CIVector(x: 0.760019, y: 0.132484, z: 0.107497, w: 0.0)
		filter.gVector = CIVector(x: 0.008408, y: 0.804728, z: 0.186864, w: 0.0)
		filter.bVector = CIVector(x: -0.001355, y: 0.085570, z: 0.915786, w: 0.0)
		filter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1) // Keep alpha unchanged
		filter.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0) // No bias
		
		return filter.outputImage!
	}
	
	/*
	 Sony sGamut.cine to AWG3
	 
	 0.974435  0.023802  0.001763
	-0.089226  1.071257  0.017969
	-0.035354  0.038226  0.997128
	 */
	
	// Converts the image from Sony sGamut.cine to Arri Wide Gamut 3 using a color matrix
	func sGamutCineToAWG3() -> CIImage {
		let filter = CIFilter.colorMatrix()
		filter.inputImage = self
		
		// Each vector is a row of the matrix: [R_in, G_in, B_in, A_in]
		filter.rVector = CIVector(x: 0.974435, y: 0.023802, z: 0.001763, w: 0.0)
		filter.gVector = CIVector(x: -0.089226, y: 1.071257, z: 0.017969, w: 0.0)
		filter.bVector = CIVector(x: -0.035354, y: 0.038226, z: 0.997128, w: 0.0)
		filter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1) // Keep alpha unchanged
		filter.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0) // No bias
		
		return filter.outputImage!
	}
	
	
	// Converts the image from Arri Wide Gamut 3 to Display P3 (D65) using a color matrix
	func AWGtoP3() -> CIImage {
		let filter = CIFilter.colorMatrix()
		filter.inputImage = self
		
		filter.rVector = CIVector(x: 1.317822, y: -0.204953, z: -0.112869, w: 0.0)
		filter.gVector = CIVector(x: -0.014538, y: 1.272477, z: -0.257939, w: 0.0)
		filter.bVector = CIVector(x: 0.003309, y: -0.119202, z: 1.115893, w: 0.0)
		filter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1) // Keep alpha unchanged
		filter.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0) // No bias
		
		return filter.outputImage!
	}
	
	
	func RGBtoSpherical() -> CIImage {
		let kernel = CIColorKernelCache.shared.rgbToSpherical
		let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) ?? self
		return result.cropped(to: self.extent)
	}
	
	func SphericaltoRGB() -> CIImage {
		let kernel = CIColorKernelCache.shared.sphericalToRgb
		let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) ?? self
		return result.cropped(to: self.extent)
	}
	
	// MARK: - Tone Mapping extensions
	
	// Linear tone mapping, assuming midtone value of 0.18
	func toneMapLin() -> CIImage {
		let kernel = CIColorKernelCache.shared.toneMapLinear
		return kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) ?? self
	}
	
	func gamutMap() -> CIImage {
		let kernel = CIColorKernelCache.shared.gamutMap
		return kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) ?? self
	}
	
    
    func sphGamutMap() -> CIImage {
        let kernel = CIColorKernelCache.shared.sphGamutMap
        return kernel.apply(
            extent: self.extent,
            roiCallback: {$1},
            arguments: [self]
        ) ?? self
    }
	
	// MARK: - Gamma Extensions
	
	// Apply Adobe Camera Raw Curve
	func applyCameraRawCurve() -> CIImage {
		let kernel = CIColorKernelCache.shared.adobeCRCurve
		return kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) ?? self
	}
	
	
	// Encode Log C3 from Linear
	func Lin2LogC() -> CIImage {
		let kernel = CIColorKernelCache.shared.encodeLogC
		return kernel.apply(
			extent: self.extent,
			roiCallback: { $1 },
			arguments: [self]
		) ?? self
	}
	
	func LogC2Lin() -> CIImage {
		let kernel = CIColorKernelCache.shared.decodeLogC
		return kernel.apply(
			extent: self.extent,
			roiCallback: { $1 },
			arguments: [self]
		) ?? self
	}
	
	func slogToLin() -> CIImage {
		let kernel = CIColorKernelCache.shared.decodeSLog3
		return kernel.apply(
			extent: self.extent,
			roiCallback: { $1 },
			arguments: [self]
		) ?? self
	}
	
	
	// Decode from gamma 2.2
	func decodeGamma22() -> CIImage {
		let filter = CIFilter.gammaAdjust()
		filter.inputImage = self
		filter.power = 2.2
		guard let result = filter.outputImage else {
			fatalError("DecodeGamma22 kernel failed")
		}
		return result
	}
	
	// Encode gamma 2.2
	func encodeGamma22() -> CIImage {
		let filter = CIFilter.gammaAdjust()
		filter.inputImage = self
		filter.power = 1.0 / 2.2
		guard let result = filter.outputImage else {
			fatalError("EncodeGamma22 kernel failed")
		}
		return result
	}
	
	// Decode sRGB gamma
	func SRGBtoLinear() -> CIImage {
		let filter = CIFilter.sRGBToneCurveToLinear()
		filter.inputImage = self
		guard let result = filter.outputImage else {
			fatalError("SRGBtoLinear kernel failed")
		}
		return result
	}
	
	// Encode sRGB
	func linearToSRGB() -> CIImage {
		let filter = CIFilter.linearToSRGBToneCurve()
		filter.inputImage = self
		guard let result = filter.outputImage else {
			fatalError("LinearToSRGB kernel failed")
		}
		return result
	}
	
	// Negative to Positive
	func CineonToLinear() -> CIImage {
		let kernel = CIColorKernelCache.shared.decodeCineon
		guard let result = kernel.apply(
			extent: self.extent,
			roiCallback: { _, rect in rect },
			arguments: [self]
		) else {return self}
		return result
	}
	
	func CineonToDisplay() -> CIImage {
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
    
    
    func cineonToNeg() -> CIImage {
        let dMinRed: Float = 0.0
        let dMinGreen: Float = 0.0
        let dMinBlue: Float = 0.0
        let redDensity: Float = 0.0
        let greenDensity: Float = 0.0
        let blueDensity: Float = 0.0
        let choice = 1
        
        let kernel = CIColorKernelCache.shared.decodeNegative
        
        guard let negative = kernel.apply(
            extent: self.extent,
            roiCallback: { _, _ in self.extent },
            arguments: [self, dMinRed, dMinGreen, dMinBlue, redDensity, greenDensity, blueDensity, choice]
        ) else {
            return self
        }
        
        return negative
    }
    
    func negToCineon() -> CIImage {
        let dMinRed: Float = 0.0
        let dMinGreen: Float = 0.0
        let dMinBlue: Float = 0.0
        let redDensity: Float = 0.0
        let greenDensity: Float = 0.0
        let blueDensity: Float = 0.0
        let choice = 1
        
        let kernel = CIColorKernelCache.shared.encodeNegative
        
        guard let cineon = kernel.apply(
            extent: self.extent,
            roiCallback: { _, _ in self.extent },
            arguments: [self, dMinRed, dMinGreen, dMinBlue, redDensity, greenDensity, blueDensity, choice]
        ) else {
            return self
        }
        
        return cineon
    }
	
	
	// MARK: - AWG4
	
	
	
	func awg4_to_linearP3() -> CIImage {
		let kernel = CIColorKernelCache.shared.AWG4_to_LinearP3
		guard let linearP3 = kernel.apply(
			extent: self.extent,
			roiCallback: { _, r in r },
			arguments: [self]
		) else {
			return self
		}
		
		return linearP3
	}
	
}
