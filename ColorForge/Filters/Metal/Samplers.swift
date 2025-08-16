//
//  Samplers.swift
//  ColorForge
//
//  Created by admin on 20/07/2025.
//

import Foundation
import CoreImage


extension CIImage {
    
    func demosaicBilinear() -> CIImage {
        let filter = BilinearDemosaic()
        filter.inputImage = self
        guard let linear = filter.outputImage else {return self}
        
//        let encoded = linear.encodeGamma22()
        
        return linear
    }
    
}
/*
let sampler = CISampler(image: bayer, options: [
    kCISamplerWrapMode: kCISamplerWrapClamp,
    kCISamplerFilterMode: kCISamplerFilterNearest,
    kCISamplerAffineMatrix: CGAffineTransform.identity
])
*/
class BilinearDemosaic: CIFilter {
    var inputImage: CIImage?
    

    private var kernel: CIKernel = { () -> CIKernel in
        getKernel(function: "bilinearDemosaic")
    }()

    static private func getKernel(function: String) -> CIKernel {
        let url = Bundle.main.url(forResource: "CIKernels",
                                  withExtension: "metallib")!
        let data = try! Data(contentsOf: url)
        return try! CIKernel(functionName: function,
                             fromMetalLibraryData: data)
    }
    
    override var outputImage: CIImage? {
        guard let bayer = inputImage else { return inputImage }
        
//        let translated = bayer.transformed(by: .init(translationX: 0, y: -bayer.extent.origin.y))
        

//        print("\n\n\nBayer Extent: \(bayer.extent)\n\n\n")

//        let sampler = CISampler(image: translated, options: [kCISamplerWrapMode: kCISamplerWrapClamp])
        
        let sampler = CISampler(image: bayer, options: [
            kCISamplerWrapMode: kCISamplerWrapBlack,
            kCISamplerFilterMode: kCISamplerFilterNearest
        ])
        
        let args: [Any] = [
            sampler
        ]

        return kernel.apply(
            extent: bayer.extent,
            roiCallback: { _, rect in
                return rect.insetBy(dx: -2, dy: -2) // or -2 for safety
            },
            arguments: args
        )
    }
}

class Halation: CIFilter {
    var inputImage: CIImage?
    var size: Float = 6.0
    
    

    private var kernel: CIKernel = { () -> CIKernel in
        getKernel(function: "halationV2")
    }()

    static private func getKernel(function: String) -> CIKernel {
        let url = Bundle.main.url(forResource: "CIKernels",
                                  withExtension: "metallib")!
        let data = try! Data(contentsOf: url)
        return try! CIKernel(functionName: function,
                             fromMetalLibraryData: data)
    }
    
    override var outputImage: CIImage? {
        guard let input = inputImage else { return inputImage }

		let sampler = CISampler(image: input, options: [kCISamplerWrapMode: kCISamplerWrapBlack])
        
        let args: [Any] = [
			sampler,
            size,
            1
        ]

        return kernel.apply(
            extent: input.extent,
			roiCallback: { index, rect in
				// Expand the requested rect by the blur radius, but clamp to the input extent
				let expanded = rect.insetBy(dx: -CGFloat(ceil(4.5 * self.size)),
											 dy: -CGFloat(ceil(4.5 * self.size)))
				return expanded.intersection(input.extent)
			},
            arguments: args
        )
    }
}


class PrintHalation: CIFilter {
	var inputImage: CIImage?
	var size: Float = 6.0
	var amount: Float = 1.0
    var darken: Bool = true
	

	private var kernel: CIKernel = { () -> CIKernel in
		getKernel(function: "printHalation")
	}()

	static private func getKernel(function: String) -> CIKernel {
		let url = Bundle.main.url(forResource: "CIKernels",
								  withExtension: "metallib")!
		let data = try! Data(contentsOf: url)
		return try! CIKernel(functionName: function,
							 fromMetalLibraryData: data)
	}
	
	override var outputImage: CIImage? {
		guard let input = inputImage else { return inputImage }
        
        let isDarken: Int
        if darken {
            isDarken = 0
        } else {
            isDarken = 1
        }
        
        let width = input.extent.width
        let height = input.extent.height
        let longEdge = max(width, height)
        let refferenceLongEdge: Float = 1080.0
        let refferenceMaxSize: Float = 20.0
        let sizeScalar = Float(longEdge) / refferenceLongEdge
        
        let sizeScaled = (size / 10.0) * sizeScalar
        let blendScaled = amount / 100.0

		let sampler = CISampler(image: input, options: [kCISamplerWrapMode: kCISamplerWrapBlack])
		
		let args: [Any] = [
			sampler,
            sizeScaled,
            blendScaled,
            isDarken
		]

		return kernel.apply(
			extent: input.extent,
			roiCallback: { index, rect in
				// Expand the requested rect by the blur radius, but clamp to the input extent
				let expanded = rect.insetBy(dx: -CGFloat(ceil(4.5 * sizeScaled)),
											 dy: -CGFloat(ceil(4.5 * sizeScaled)))
				return expanded.intersection(input.extent)
			},
			arguments: args
		)
	}
}

class HistogramData: CIFilter {
    var inputImage: CIImage?
    var bins: Float = 256.0
    

    private var kernel: CIKernel = { () -> CIKernel in
        getKernel(function: "histogram")
    }()

    static private func getKernel(function: String) -> CIKernel {
        let url = Bundle.main.url(forResource: "CIKernels",
                                  withExtension: "metallib")!
        let data = try! Data(contentsOf: url)
        return try! CIKernel(functionName: function,
                             fromMetalLibraryData: data)
    }
    
    override var outputImage: CIImage? {
        guard let input = inputImage else { return inputImage }
        
        let scaleX = 256.0 / input.extent.width
        let scaleY = 256.0 / input.extent.height
        
        let scaled = input.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let sampler = CISampler(image: input, options: [kCISamplerWrapMode: kCISamplerWrapBlack])
        
        let args: [Any] = [
            sampler,
            bins
        ]

        return kernel.apply(
            extent: input.extent,
            roiCallback: { $1 },
            arguments: args
        )
    }
}



// MARK: - Gradient Samplers




class LinearGradientMaskSigmoid: CIFilter {
	var inputImage: CIImage?
	var maskImage: CIImage?
	var start: CGPoint = .zero
	var end: CGPoint = .zero
	

	private var kernel: CIKernel = { () -> CIKernel in
		getKernel(function: "linearGradientMetalRawExposure")
	}()

	static private func getKernel(function: String) -> CIKernel {
		let url = Bundle.main.url(forResource: "CIKernels",
								  withExtension: "metallib")!
		let data = try! Data(contentsOf: url)
		return try! CIKernel(functionName: function,
							 fromMetalLibraryData: data)
	}
	
	override var outputImage: CIImage? {
		guard let base = inputImage, let top = maskImage else { return inputImage }

		
		let startX = start.x
		let startY = start.y
		let endX = end.x
		let endY = end.y

		let samplerBase = CISampler(image: base, options:
										[kCISamplerWrapMode: kCISamplerWrapBlack])
		let samplerTop = CISampler(image: top, options:
									[kCISamplerWrapMode: kCISamplerWrapBlack])
		
		let args: [Any] = [
			samplerBase,
			samplerTop,
			startX,
			startY,
			endX,
			endY
		]

		return kernel.apply(
			extent: base.extent,
			roiCallback: { $1
			},
			arguments: args
		)
	}
}
