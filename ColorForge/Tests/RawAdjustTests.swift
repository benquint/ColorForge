////
////  RawAdjustTests.swift
////  ColorForge
////
////  Created by admin on 27/05/2025.
////
//
//import Foundation
//import CoreImage
//import Metal
//import MetalKit
//import AppKit
//
//public func testRawAdjustPipeline() {
//	print("Running full RawAdjust pipeline with detailed timing...")
//
//	let totalStart = CFAbsoluteTimeGetCurrent()
//	let renderSize = CGSize(width: 1920, height: 1080)
//	let colorSpace = CGColorSpace(name: CGColorSpace.extendedDisplayP3)!
//	let context = RenderingManager.shared.mainImageContext
//
//	guard let url = Bundle.main.url(forResource: "BMW_X_PAULAINSWORTH_Day01_0546", withExtension: "DNG") else {
//		print("UnitTest.DNG not found in app bundle.")
//		return
//	}
//
//	// === CAMetalLayer Pipeline ===
//	let cametalStart = CFAbsoluteTimeGetCurrent()
//
//	// Build Metal layer
//	let metalLayer = CAMetalLayer()
//	metalLayer.device = MTLCreateSystemDefaultDevice()
//	metalLayer.pixelFormat = .bgra8Unorm
//	metalLayer.framebufferOnly = false
//	metalLayer.drawableSize = renderSize
//
//	// Debayer Timing
//	let debayerNode = DebayerNode(rawFileURL: url)
//	let debayerStart = CFAbsoluteTimeGetCurrent()
//	var image = debayerNode.apply()
//	let debayerElapsed = CFAbsoluteTimeGetCurrent() - debayerStart
//	print("Debayer time: \(String(format: "%.6f", debayerElapsed))s")
//
//	// Combined Filter Timing (excluding debayer)
//	let filtersStart = CFAbsoluteTimeGetCurrent()
//
//	/*
//	 Notes:
//	 
//	 Spherical saturation is causing issues in areas of high saturation
//	 */
//	image = timeAndLog("Temp and Tint") { TempAndTintNode(targetTemp: 6500, targetTint: 0, sourceTemp: 5000, sourceTint: 0).apply(to: image) }
//	image = timeAndLog("Exposure") { RawExposureNode(exposure: 2.2).apply(to: image) }
//	print("Result from Exposure extent: \(image.extent)")
//	image = timeAndLog("Contrast") { RawContrastNode(contrast: 0.0).apply(to: image) }
//	print("Result from Contrast extent: \(image.extent)")
//	image = timeAndLog("Saturation") { GlobalSaturationNode(saturation: 40.0).apply(to: image) }
//	image = timeAndLog("HDR") { HDRNode(hdrWhite: 100, hdrHighlight: 0, hdrShadow: 0, hdrBlack: 0).apply(to: image) }
//	image = timeAndLog("HSD") {
//		HueSaturationDensityNode(
//			redHue: 0, redSat: 10, redDen: 0,
//			greenHue: 0, greenSat: 10, greenDen: 0,
//			blueHue: 0, blueSat: 10, blueDen: 0,
//			cyanHue: 0, cyanSat: 10, cyanDen: 0,
//			magentaHue: 0, magentaSat: 10, magentaDen: 0,
//			yellowHue: 0, yellowSat: 10, yellowDen: 0
//		).apply(to: image)
//	}
//	
//	image = timeAndLog("MTF") { MTFCurveNode(format: 0).apply(to: image) }
////	image = timeAndLog("Grain") { GrainNode().apply(to: image) }
//	image = timeAndLog("PortraLut") { Portra400Node().apply(to: image) }
//	image = timeAndLog("NegativeConvert") { DecodeNegativeNode().apply(to: image) }
//	image = timeAndLog("EnlargerFilter") { EnlargerPrintChainNode(exposure: 0.0, cyan: 0.0, magenta: 30.0, yellow: 40.0).apply(to: image) }
//	
//	
//	
//
//	let filtersElapsed = CFAbsoluteTimeGetCurrent() - filtersStart
//	print("Combined filter nodes (Temp and Tint, Exposure, Contrast, Saturation, HDR, HSD) time: \(String(format: "%.6f", filtersElapsed))s")
//
//	// Render to CAMetalLayer
//	if let drawable = metalLayer.nextDrawable() {
//		context.render(image, to: drawable.texture, commandBuffer: nil, bounds: image.extent, colorSpace: colorSpace)
//		print("Rendered to CAMetalLayer drawable")
//	} else {
//		print("Failed to get CAMetalLayer drawable")
//	}
//
//	let cametalElapsed = CFAbsoluteTimeGetCurrent() - cametalStart
//	print("CAMetalLayer full pipeline time: \(String(format: "%.6f", cametalElapsed))s")
//
//	print("Final image extent: \(image.extent)")
//
//	saveImage(image)
//	
//	// === Total Pipeline Time ===
//	let totalElapsed = CFAbsoluteTimeGetCurrent() - totalStart
//	print("Total time for CAMetalLayer pipeline: \(String(format: "%.6f", totalElapsed))s")
//}
//
//private func timeAndLog(_ label: String, block: () -> CIImage) -> CIImage {
//	let start = CFAbsoluteTimeGetCurrent()
//	let result = block()
//	let elapsed = CFAbsoluteTimeGetCurrent() - start
//	print("\(label) time: \(String(format: "%.6f", elapsed))s")
//	return result
//}
//
//
//private func saveImage(_ image: CIImage) {
//	DispatchQueue.global(qos: .userInitiated).async {
//		let context = RenderingManager.shared.mainImageContext
//		
//		let width = image.extent.width
//		let height = image.extent.height
//		let outputColorSpace = CGColorSpace(name: CGColorSpace.adobeRGB1998)!
//		let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
//		
//		guard let cgImage = context.createCGImage(image, from: image.extent) else {
//			print("Failed to create CGImage.")
//			return
//		}
//		
//		guard let cgContext = CGContext(
//			data: nil,
//			width: Int(width),
//			height: Int(height),
//			bitsPerComponent: 16,
//			bytesPerRow: 0,
//			space: outputColorSpace,
//			bitmapInfo: bitmapInfo.rawValue
//		) else {
//			print("Failed to create CGContext.")
//			return
//		}
//		
//		// Draw the CGImage into the context
//		cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
//		
//		guard let outputCGImage = cgContext.makeImage() else {
//			print("Failed to create output CGImage.")
//			return
//		}
//		
//		let bitmapRep = NSBitmapImageRep(cgImage: outputCGImage)
//		let fileType: NSBitmapImageRep.FileType = .tiff
//		var fileProperties: [NSBitmapImageRep.PropertyKey: Any] = [:]
//		
//		guard let fileData = bitmapRep.representation(using: fileType, properties: fileProperties) else {
//			print("Failed to create file data from CGImage.")
//			return
//		}
//		
//		let fileManager = FileManager.default
//		let sandboxURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
//		let outputFolderURL = sandboxURL.appendingPathComponent("UnitTestOutput")
//		let outputFileURL = outputFolderURL.appendingPathComponent("unitTest.tiff")
//		
//		do {
//			try fileManager.createDirectory(at: outputFolderURL, withIntermediateDirectories: true, attributes: nil)
//			try fileData.write(to: outputFileURL)
//			print("Saved TIFF image to: \(outputFileURL.path)")
//		} catch {
//			print("Failed to save TIFF image: \(error)")
//		}
//	}
//}
//
//
//class RawAdjustTests: ObservableObject {
//	static let shared = RawAdjustTests()
//	public var inputWidth: CGFloat?
//	public var inputHeight: CGFloat?
//	public var inputRect: CGRect = .zero
//	
//	// Published variables
//	@Published var temp: Float = 5500.0
//	@Published var tint: Float = 0.0
//	@Published var exposure: Float = 0.0
//	@Published var contrast: Float = 0.0
//	@Published var saturation: Float = 0.0
//	
//	@Published var hdrWhite: Float = 0.0
//	@Published var hdrHighlight: Float = 0.0
//	@Published var hdrShadow: Float = 0.0
//	@Published var hdrBlack: Float = 0.0
//
//	@Published var applyMTF: Bool = false
//	
//	@Published var convertToNeg: Bool = false
//	@Published var applyPrintMode: Bool = false
//	
//	@Published var applyGrain: Bool = false
//	@Published var grainAmount: Float = 50.0
//	
//	@Published var enlargerExp: Float = 0.0
//	@Published var cyan: Float = 0.0
//	@Published var magenta: Float = 0.0
//	@Published var yellow: Float = 0.0
//	
//	
//	
//	private var cachedDebayered: CIImage?
//	
//	func loadDebayered() {
//			if cachedDebayered == nil {
//				guard let url = Bundle.main.url(forResource: "BMW_X_PAULAINSWORTH_Day01_0546", withExtension: "DNG") else {
//					fatalError("URL Failed")
//				}
//				cachedDebayered = DebayerNode(rawFileURL: url).apply()
//				inputRect = cachedDebayered?.extent ?? .zero
//			}
//		}
//	
//	func runTestPipeline() -> CIImage {
//		// Ensure debayered image is loaded
//		loadDebayered()
//		guard let baseImage = cachedDebayered else {
//			fatalError("Debayered image missing")
//		}
//		
//		var processImage = baseImage
//		GrainModel.shared.scaleGrainPlates(processImage.extent)
//		processImage = TempAndTintNode(targetTemp: temp, targetTint: tint, sourceTemp: 5000, sourceTint: 0).apply(to: processImage)
//		processImage = RawExposureNode(exposure: exposure).apply(to: processImage)
//		processImage = RawContrastNode(contrast: contrast).apply(to: processImage)
//		processImage = GlobalSaturationNode(saturation: saturation).apply(to: processImage)
//		processImage = HDRNode(hdrWhite: hdrWhite, hdrHighlight: hdrHighlight, hdrShadow: hdrShadow, hdrBlack: hdrBlack).apply(to: processImage)
//		if applyMTF {
//			processImage = MTFCurveNode(format: 3).apply(to: processImage)
//		}
//		if applyGrain {
//			processImage = GrainNode(grainAmount: grainAmount).apply(to: processImage)
//		}
//		if convertToNeg {
//			processImage = Portra400Node().apply(to: processImage)
//			processImage = DecodeNegativeNode().apply(to: processImage)
//			if applyPrintMode {
//				processImage = EnlargerPrintChainNode(exposure: enlargerExp, cyan: cyan, magenta: magenta, yellow: yellow).apply(to: processImage)
//			}
//		} else {
//			
//		}
//		
//		return processImage
//	}
//}
//
//
