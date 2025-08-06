//
//  ColorForgeTests.swift
//  ColorForgeTests
//
//  Created by Ben Quinton on 21/05/2025.
//

import Testing
import CoreImage
import Metal
import MetalKit
@testable import ColorForge

struct ColorForgeTests {
	@Test
	func testRawAdjustPipeline() async throws {
		print("Running RawAdjust pipeline test...")

		// Initialize Metal layer for rendering
		let metalLayer = CAMetalLayer()
		metalLayer.device = MTLCreateSystemDefaultDevice()
		metalLayer.pixelFormat = .bgra8Unorm
		metalLayer.framebufferOnly = false
		metalLayer.drawableSize = CGSize(width: 1024, height: 1024)

		// Use shared CIContext with Metal support
		let context = RenderingManager.shared.mainImageContext

		// Locate UnitTest.DNG
		let url = URL(fileURLWithPath: "/Users/admin/Dropbox/Mac (3)/Documents/UnitTest.DNG")
		guard FileManager.default.fileExists(atPath: url.path) else {
			#expect(false, "UnitTest.DNG not found at specified file path.")
			return
		}

		// Force kernel initialization
		_ = CIColorKernelCache.shared

		// Run the RawAdjust pipeline
		let debayerNode = DebayerNode(rawFileURL: url)
		var image = debayerNode.apply(to: CIImage())

		image = timeAndLog("Temp and Tint") {
			TempAndTintNode(targetTemp: 6500, targetTint: 0, sourceTemp: 5000, sourceTint: 0).apply(to: image)
		}
		image = timeAndLog("Exposure") { RawExposureNode(exposure: 1.0).apply(to: image) }
		image = timeAndLog("Contrast") { RawContrastNode(contrast: 20.0).apply(to: image) }
		image = timeAndLog("Saturation") { GlobalSaturationNode(saturation: 10.0).apply(to: image) }
		image = timeAndLog("HDR") { HDRNode(hdrWhite: 10, hdrHighlight: 5, hdrShadow: 5, hdrBlack: 0).apply(to: image) }
		image = timeAndLog("HSD") {
			HueSaturationDensityNode(
				redHue: 0, redSat: 10, redDen: 0,
				greenHue: 0, greenSat: 10, greenDen: 0,
				blueHue: 0, blueSat: 10, blueDen: 0,
				cyanHue: 0, cyanSat: 10, cyanDen: 0,
				magentaHue: 0, magentaSat: 10, magentaDen: 0,
				yellowHue: 0, yellowSat: 10, yellowDen: 0
			).apply(to: image)
		}

		// Render to CAMetalLayer
		guard let drawable = metalLayer.nextDrawable() else {
			#expect(false, "Failed to get CAMetalLayer drawable")
			return
		}
		let colorSpace = CGColorSpace(name: CGColorSpace.extendedDisplayP3)!
		context.render(image, to: drawable.texture, commandBuffer: nil, bounds: image.extent, colorSpace: colorSpace)
		print("Rendered to CAMetalLayer drawable")

		// Optionally keep window open briefly
		RunLoop.current.run(until: Date(timeIntervalSinceNow: 3))
	}

	private func timeAndLog(_ label: String, block: () -> CIImage) -> CIImage {
		let start = CFAbsoluteTimeGetCurrent()
		let result = block()
		let elapsed = CFAbsoluteTimeGetCurrent() - start
		print("\(label) time: \(String(format: "%.3f", elapsed))s")
		return result
	}
}
