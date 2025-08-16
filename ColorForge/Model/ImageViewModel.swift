//
//  ImageViewModel.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import Foundation
import SwiftUI
import AppKit

class ImageViewModel: ObservableObject {
    static let shared = ImageViewModel()

    var currentImgID: UUID?
    @Published var processingFullyComplete: Bool = false
	
    // Temp
    @Published var downAndUpScale: CGFloat = 1.0 {
        didSet {
            if let id = currentImgID {
                let pipeline = FilterPipeline.shared
                let dataModel = DataModel.shared
                
                pipeline.applyPipelineV2Sync(id, dataModel)
            }
        }
    }

	// MARK: - RadialGradient View Properties
	@Published var radialUiStart: CGPoint = .zero
	@Published var radialUiEnd: CGPoint = .zero
	@Published var radialUiWidth: CGFloat = 0
	@Published var radialUiHeight: CGFloat = 0
    @Published var radialUiFeather: CGFloat = 50.0
    
    // Boolean to toggle if the renderer has finally initialised in the ui.
    @Published var rendererInitialisedInUI: Bool = false
    
    


    @Published var saveToggled: Bool = false
    

	
	@Published var processingComplete: Bool = false


    // MARK: - Published Variables
	@Published var drawingNewMask: Bool = false
    @Published var initialMaskDrawn: Bool = false
    
    // Rendering management - triggers true when rendered so we can swap from the preview to the metal view.
    @Published var renderingComplete: Bool = false
    
    @Published var backgroundColor: String = "BG_White" {
        didSet{
            if let renderer = RenderingManager.shared.renderer {
                if let result = FilterPipeline.shared.currentResult {
                    renderer.updateImage(result)
                }
            }
        }
    }
    @Published var padding: CGFloat = 10 {
        didSet{
            if let renderer = RenderingManager.shared.renderer {
                if let result = FilterPipeline.shared.currentResult {
                    renderer.updateImage(result)
                }
            }
        }
    }

	
    @Published var uiStartPoint: CGPoint = CGPoint(x: 1, y: 1)
	@Published var uiEndPoint: CGPoint = CGPoint(x: 1, y: 1)
	
    @Published var imageViewActive: Bool = false
    

    

    @Published var drawingLinearMask: Bool = false {
        didSet {
            print("Linear Gradient Toggled")
        }
    }
    
    
    @Published var drawingRadialMask: Bool = false
    @Published var isZoomed: Bool = false {
        didSet {
            if !isZoomed {
                zoomScale = 1.0
            }
        }
    }
	

    // View Size / masking variables
    public var viewSize: CGSize = .zero
    public var imageSize: CGSize = .zero

    
    
    // MARK: - Masking
    
    @Published var maskingActive: Bool = false
    @Published var selectedMask: UUID? // Find the masks ID for the given image
    @Published var showMask: Bool = true
    @Published var showMaskPoints: Bool = true

	
    
    // MARK: - Coordinate Conversion
    
    public var currentImage: CIImage?
	public var currentPreview: NSImage?
    

    
    @Published var metalSize: CGSize = .zero
    
    @Published var thumbViewSize: CGSize = .zero

    
    
    // MARK: - Zoom Functions
    
    // Required Variables
    @Published var nativeWidth: Int = 0
    @Published var nativeHeight: Int = 0
    
    public var currentExtent: CGRect = .zero
    @Published var zoomRect: CGRect = .zero

    @Published var zoomScale: CGFloat = 1.0
    
    @Published var metalImageWidth: CGFloat = 0
    @Published var metalImageHeight: CGFloat = 0
    
	
	// Expects point to be in CoreImage coords, relative to image not view
	func calculateZoomRect(_ point: CGPoint, _ imageSizeUI: CGSize, _ viewSize: CGSize) -> CGRect {
		guard let img = currentImage else {return .zero}
		
		// Width and height set to current view si
		let zoomWidth = viewSize.width
		let zoomHeight = viewSize.height
		
		let scalar = max(CGFloat(nativeWidth), CGFloat(nativeHeight)) / max(img.extent.width, img.extent.height)
		
		zoomScale = scalar
		
		let scaledZoomPoint = point * scalar
		let zoomOriginX = scaledZoomPoint.x - (zoomWidth / 2)
		let zoomOriginY = scaledZoomPoint.y - (zoomHeight / 2)
		
		let zoomRect = CGRect(
			x: zoomOriginX,
			y: zoomOriginY,
			width: zoomWidth,
			height: zoomHeight
		)
		
		self.zoomRect = zoomRect
		
        return zoomRect
    }
    
    func translateRect(_ delta: CGSize) {
        let deltaX = delta.width / 2 // To reduce sensitivity
        let deltaY = delta.height / 2 // To reduce sensitivity
        
        let zoomScale = max(CGFloat(nativeWidth), CGFloat(nativeHeight)) / max(imageSize.width, imageSize.height)

        var originX = zoomRect.origin.x - (deltaX / zoomScale)
        var originY = zoomRect.origin.y - (deltaY  / zoomScale)

        // Clamp X within bounds
        originX = max(0, min(originX, CGFloat(nativeWidth) - zoomRect.width))

        // Clamp Y within bounds
        originY = max(0, min(originY, CGFloat(nativeHeight) - zoomRect.height))

        zoomRect = CGRect(
            x: originX,
            y: originY,
            width: zoomRect.width,
            height: zoomRect.height
        )
    }
	
	
	
	// MARK: - UI Image Size

	private var currentWindowContentSize: CGSize? {
		NSApplication.shared.mainWindow?.contentLayoutRect.size
	}
	
	@Published var sideBarWidth: CGFloat = 300.0
	@Published var topBarHeight: CGFloat = 53.0
	@Published var bottomBarHeight: CGFloat = 35.0
	
	
	private var imageViewSize: CGSize {
		guard let window = currentWindowContentSize else {return .zero}
		
		let width = window.width - sideBarWidth
		let height = window.height - (topBarHeight + bottomBarHeight)
		
		return CGSize(width: width, height: height)
	}
    
	@Published var computedSizeForUI: CGSize = .zero
	
	public func calculateUIImageSize() {
		guard let img = currentImage else {return}
		
		let imgWidth = img.extent.width
		let imgHeight = img.extent.height
		
		let paddedWidth = imageViewSize.width - (padding * 2)
		let paddedHeight = imageViewSize.height - (padding * 2)
		
		let aspect = paddedWidth / paddedHeight
		
		var scale: CGFloat = 1.0
		var width: CGFloat = 0.0
		var height: CGFloat = 0.0
		
		if aspect >= 1.0 {
			scale = paddedHeight / imgHeight
			width = imgWidth * scale
			height = imgHeight * scale
		} else {
			scale = paddedWidth / imgWidth
			width = imgWidth * scale
			height = imgHeight * scale
		}
		
		computedSizeForUI = CGSize(width: width, height: height)
	}
	
	
	// Update images:
	
	@Published var renderSumbitted: Bool = false
	@Published var imageToRender: CIImage?
	

	
	
	// MARK: - SAM
	
	@Published var sam2MaskMode: Bool = false
	
}



