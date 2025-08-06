//
//  MainMetalView.swift
//  ColorForge
//
//  Created by admin on 01/06/2025.
//

import Foundation
import CoreImage
import Metal
import MetalKit
import SwiftUI


class MainMetalView: MTKView {
	var context: CIContext
	var commandQueue: MTLCommandQueue
	var destImage: CIImage
	var destRect: CGRect
	var destPoint = CGPoint.zero
	
	init(frame frameRect: CGRect, ciImage: CIImage) {
		let dev = RenderingManager.shared.device
		context = RenderingManager.shared.mainImageContext  // Reuse the pre-initialized context
		commandQueue = dev.makeCommandQueue()!
		destImage = ciImage
		destRect = frameRect
		super.init(frame: frameRect, device: dev)
		self.sampleCount = 8 // 4x MSAA; can be 2, 4, or 8
		self.preferredFramesPerSecond = 12
		
		framebufferOnly = false
		colorPixelFormat = .bgra8Unorm

		// Set Metal clear color to white
		self.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 1)
	}

	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	override func draw(_ rect: CGRect) {
		guard let drawable = currentDrawable else { return }

		let drawableSize = CGSize(width: drawable.texture.width, height: drawable.texture.height)
		let imageExtent = destImage.extent

		// Adjust drawableSize to match imageExtent (scaledExtent)
		let targetWidth = imageExtent.width
		let targetHeight = imageExtent.height
		let dx = (drawableSize.width - targetWidth) / 2
		let dy = (drawableSize.height - targetHeight) / 2
		let destRect = CGRect(x: dx, y: dy, width: targetWidth, height: targetHeight)

		guard let commandBuffer = commandQueue.makeCommandBuffer() else { return }
		let rd = CIRenderDestination(width: Int(drawableSize.width),
									 height: Int(drawableSize.height),
									 pixelFormat: colorPixelFormat,
									 commandBuffer: commandBuffer) {
			return drawable.texture
		}

		do {
			// Composite image is already prepared with white background
			try context.startTask(toRender: destImage,
								  from: destImage.extent,
								  to: rd,
								  at: destRect.origin)
			commandBuffer.present(drawable)
			commandBuffer.commit()
		} catch {
			print("Render failed: \(error)")
		}
	}

	
	func updateImage(_ ciImage: CIImage) {
		self.destImage = ciImage
		self.destRect = ciImage.extent
		self.setNeedsDisplay(bounds) // or self.needsDisplay = true
	}
}
