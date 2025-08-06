//
//  ThumbnailMetalView.swift
//  ColorForge
//
//  Created by admin on 17/07/2025.
//

import SwiftUI
import MetalKit
import AppKit

struct ThumbnailMetalView: ViewRepresentable {
	@StateObject var renderer: ThumbnailRenderer
	
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
		
		
		return view
	}
	
	func updateView(_ view: MTKView, context: Context) {
		configure(view: view, using: renderer)
	}
	
	private func configure(view: MTKView, using renderer: ThumbnailRenderer) {
		view.delegate = renderer
	}
}
