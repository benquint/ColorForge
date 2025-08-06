////
////  RawAdjustTests.swift
////  ColorForgeTests
////
////  Created by admin on 27/05/2025.
////
//
//import XCTest
//import CoreImage
//import Metal
//import MetalKit
//@testable import ColorForge
//
//final class RawAdjustNodeTests: XCTestCase {
//	
//	var rawURL: URL!
//	var context: CIContext!
//	var metalLayer: CAMetalLayer!
//	
//	override func setUp() {
//		super.setUp()
//		// Initialize Metal layer for rendering
//		metalLayer = CAMetalLayer()
//		metalLayer.device = MTLCreateSystemDefaultDevice()
//		metalLayer.pixelFormat = .bgra8Unorm
//		metalLayer.framebufferOnly = false
//		metalLayer.drawableSize = CGSize(width: 1024, height: 1024) // Set size to desired output
//		
//		// Use shared CIContext with Metal support
//		context = RenderingManager.shared.mainImageContext
//		
//		// Locate test RAW file
//		guard let url = Bundle(for: type(of: self)).url(forResource: "UnitTest", withExtension: "DNG") else {
//			XCTFail("UnitTest.DNG not found in bundle.")
//			return
//		}
//		rawURL = url
//		
//		// Force kernel initialization
//		_ = CIColorKernelCache.shared
//	}
//	
//	func testRawAdjustPipelineRendering() {
//		print("Running RawAdjust pipeline test...")
//		
//		let debayerNode = DebayerNode(rawFileURL: rawURL)
//		var image = debayerNode.apply(to: CIImage())
//		
//		image = timeAndLog("Temp and Tint") {
//			TempAndTintNode(targetTemp: 6500, targetTint: 0, sourceTemp: 5000, sourceTint: 0).apply(to: image)
//		}
//		image = timeAndLog("Exposure") { RawExposureNode(exposure: 1.0).apply(to: image) }
//		image = timeAndLog("Contrast") { RawContrastNode(contrast: 20.0).apply(to: image) }
//		image = timeAndLog("Saturation") { GlobalSaturationNode(saturation: 10.0).apply(to: image) }
//		image = timeAndLog("HDR") { HDRNode(hdrWhite: 10, hdrHighlight: 5, hdrShadow: 5, hdrBlack: 0).apply(to: image) }
//		image = timeAndLog("HSD") {
//			HueSaturationDensityNode(
//				redHue: 0, redSat: 10, redDen: 0,
//				greenHue: 0, greenSat: 10, greenDen: 0,
//				blueHue: 0, blueSat: 10, blueDen: 0,
//				cyanHue: 0, cyanSat: 10, cyanDen: 0,
//				magentaHue: 0, magentaSat: 10, magentaDen: 0,
//				yellowHue: 0, yellowSat: 10, yellowDen: 0
//			).apply(to: image)
//		}
//		
//		// Render to CAMetalLayer
//		guard let drawable = metalLayer.nextDrawable() else {
//			XCTFail("Failed to get CAMetalLayer drawable")
//			return
//		}
//		let colorSpace = CGColorSpace(name: CGColorSpace.extendedDisplayP3)!
//		context.render(image, to: drawable.texture, commandBuffer: nil, bounds: image.extent, colorSpace: colorSpace)
//		print("Rendered to CAMetalLayer drawable")
//		
//		// Optionally hold the layer open
//		RunLoop.current.run(until: Date(timeIntervalSinceNow: 3))
//	}
//	
//	private func timeAndLog(_ label: String, block: () -> CIImage) -> CIImage {
//		let start = CFAbsoluteTimeGetCurrent()
//		let result = block()
//		let elapsed = CFAbsoluteTimeGetCurrent() - start
//		print("\(label) time: \(String(format: "%.3f", elapsed))s")
//		return result
//	}
//}
