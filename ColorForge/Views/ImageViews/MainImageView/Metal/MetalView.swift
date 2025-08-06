//
//  MetalView.swift
//  ColorForge
//
//  Created by admin on 03/06/2025.
//

import SwiftUI
import MetalKit
import AppKit

struct MetalView: ViewRepresentable {
	@StateObject var renderer: Renderer
	
	func makeView(context: Context) -> MTKView {
		let view = MTKView(frame: .zero, device: renderer.device)
		
		view.isPaused = true
		view.enableSetNeedsDisplay = true
		view.framebufferOnly = false
		view.delegate = renderer
		
		renderer.view = view
		
		if let layer = view.layer as? CAMetalLayer {
			layer.wantsExtendedDynamicRangeContent = false
			layer.colorspace = CGColorSpace(name: CGColorSpace.adobeRGB1998)
			view.colorPixelFormat = .bgra8Unorm
		}
		
		
		
		
		// ***** Have Disabled XDR Support for now until further testing ***** //
		
		
//		if let layer = view.layer as? CAMetalLayer {
//			// Enable EDR if available
//			if let screen = view.window?.screen, screen.maximumExtendedDynamicRangeColorComponentValue > 1.0 {
//				layer.wantsExtendedDynamicRangeContent = true
//				layer.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
//				view.colorPixelFormat = .rgba16Float
//			} else {
//				print("EDR not supported — using AdobeRGB and 8-bit BGRA")
//				layer.wantsExtendedDynamicRangeContent = false
//				layer.colorspace = CGColorSpace(name: CGColorSpace.adobeRGB1998)
////				layer.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)
//				view.colorPixelFormat = .bgra8Unorm
//			}
//		}
		
		
		
		return view
	}
	
	func updateView(_ view: MTKView, context: Context) {
		configure(view: view, using: renderer)
	}
	
	private func configure(view: MTKView, using renderer: Renderer) {
		view.delegate = renderer
	}
}
