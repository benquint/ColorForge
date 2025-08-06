//
//  Renderer.swift
//  ColorForge
//
//  Created by admin on 03/06/2025.
//

import Metal
import MetalKit
import CoreImage

let maxBuffersInFlight = 3

final class Renderer: NSObject, MTKViewDelegate, ObservableObject {
	public let device: MTLDevice
	let commandQueue: MTLCommandQueue
	let cicontext: CIContext
	
	let viewModel = ImageViewModel.shared


    var image: CIImage?

	let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

	let padding: CGFloat = 0.0

	weak var view: MTKView?

	var lastRect: CGRect = .zero
	var borders: CIImage?



	// MARK: - Designated initializer
	 override init() {
		 print("Renderer init: setting up Metal and CIContext")

		 // create things locally first
		 let dev       = RenderingManager.shared.device
		 let cmdQueue  = dev.makeCommandQueue()!
		 let ciContext = RenderingManager.shared.mainImageContext

		 // assign all stored properties
		 self.device       = dev
		 self.commandQueue = cmdQueue
		 self.cicontext    = ciContext

		 // now call super
		 super.init()

		 print("Renderer init: completed")
	 }

	func draw(in view: MTKView) {
		

		_ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)

		guard let commandBuffer = commandQueue.makeCommandBuffer() else {
			print("Renderer: Failed to create commandBuffer")
			return
		}
		commandBuffer.addCompletedHandler { _ in self.inFlightSemaphore.signal() }

		guard let drawable = view.currentDrawable else {
			print("Renderer: No drawable available")
			return
		}
		let dSize = view.drawableSize
		viewModel.viewSize = dSize
        viewModel.metalSize = dSize
		let contentScaleFactor = view.convertToBacking(CGSize(width: 1.0, height: 1.0)).width
		let headroom = view.window?.screen?.maximumExtendedDynamicRangeColorComponentValue ?? 1.0


		let destination = CIRenderDestination(
			width: Int(dSize.width),
			height: Int(dSize.height),
			pixelFormat: view.colorPixelFormat,
			commandBuffer: commandBuffer,
			mtlTextureProvider: { drawable.texture })

		
		guard var image = self.image else {
			print("Renderer: No image set")
			return
		}
		
		image = image.crop(image.extent)
		
		// Attempt to load NSColor from the asset catalog
		let nsColor = NSColor(named: ImageViewModel.shared.backgroundColor) ?? .black

		// Convert NSColor to CIColor
		let ciColor = CIColor(color: nsColor) ?? .black

		// Use it to create the background CIImage
		let opaqueBackground = CIImage(color: ciColor)


		let padding = ImageViewModel.shared.padding
		image = image.scaleToViewAndPad(dSize, padding)
		viewModel.imageSize = image.extent.size
        viewModel.metalImageWidth = image.extent.size.width
        viewModel.metalImageHeight = image.extent.size.height
		let paddedExtent = image.extent
		
		


		let backBounds = CGRect(x: 0, y: 0, width: dSize.width, height: dSize.height)
		let shiftX = round((backBounds.width + paddedExtent.origin.x - paddedExtent.width) * 0.5)
		let shiftY = round((backBounds.height + paddedExtent.origin.y - paddedExtent.height) * 0.5)
		image = image.transformed(by: CGAffineTransform(translationX: shiftX, y: shiftY))
		
		let finalOriginX = paddedExtent.origin.x + shiftX
		let finalOriginY = paddedExtent.origin.y + shiftY
		let finalRect = CGRect(x: finalOriginX,
							   y: finalOriginY,
							   width: paddedExtent.width,
							   height: paddedExtent.height)
		
		if image.extent != lastRect {
			
			let mask = opaqueBackground.addBorders(Float(finalRect.origin.x),
												   Float(finalRect.origin.y),
												   Float(finalRect.width),
												   Float(finalRect.height))
			self.borders = mask
			image = image.composited(over: opaqueBackground)
			image = mask.composited(over: image)
		} else {
			guard let mask = self.borders else { return }
			image = image.composited(over: opaqueBackground)
			image = mask.composited(over: image)
		}
		



		do {
			try cicontext.startTask(toRender: image, from: backBounds, to: destination, at: .zero)
		} catch {
			print("Renderer: failed to start render task: \(error)")
		}

		// Trigger view models notifier when rendering is complete
		commandBuffer.addCompletedHandler { _ in
			self.inFlightSemaphore.signal()
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				self.viewModel.renderingComplete = true
			}
		}
		
		commandBuffer.present(drawable)
		commandBuffer.commit()
	}

	func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
	}
	
	func updateImage(_ newImage: CIImage) {
		self.image = newImage
		DispatchQueue.main.async {
			self.view?.setNeedsDisplay(self.view!.bounds)
		}
	}
	

	func requestRedraw() {
		DispatchQueue.main.async {
			self.view?.setNeedsDisplay(self.view!.bounds)
		}
	}
}
