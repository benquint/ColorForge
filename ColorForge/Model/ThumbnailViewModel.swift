//
//  ThumbnailViewModel.swift
//  ColorForge
//
//  Created by admin on 17/07/2025.
//

import Foundation
import SwiftUI
import AppKit


class ThumbnailViewModel: ObservableObject {
	static let shared = ThumbnailViewModel()
	
	
	
	// MARK: - View Properties
    
    @Published var thumbsLoaded: Bool = false
	
	// Padding for thumbnails
	@Published var padding = 20.0
	
	// Background color for thumbnail view
	@Published var backgroundColor: CIColor = CIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1.0)
	
	// Collumn count
	@Published var colCount: Int = 5
	
	@Published var lastScrolledToID: UUID?
    @Published var lastClickedIndex: Int? = nil
	
	// Boolean to let view know rendering is complete
	@Published var renderingComplete: Bool = false {
		didSet {
			if renderingComplete {
				if initialRenderingComplete {
					
					
					// Half Second delay if renderer exists
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
						self.hideThumbs = self.renderingComplete
					}
				} else {
					DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
						self.hideThumbs = self.renderingComplete
						self.initialRenderingComplete = true
					}
				}
			} else {
				hideThumbs = renderingComplete
			}
			
			print("\n\nDidSet Bools:\nrenderingComplete = \(renderingComplete)\ninitialRenderingComplete = \(initialRenderingComplete)\nhideThumbs = \(hideThumbs)\n\n")
		}
	}
	
	@Published var initialRenderingComplete: Bool = false
	
	@Published var hideThumbs: Bool = false {
		didSet {
			print("Hide Thumbs = \(hideThumbs)")
		}
	}
	
	@Published var isInitialLoad: Bool = false
	
	@Published var canvasSize: CGSize = .zero
	@Published var tileOriginsByUUID: [UUID: CGPoint] = [:]
	@Published var tileSize: CGFloat = 0.0 // Also track tileSize so overlays can use it
	
	
	public var viewHeight: CGFloat = 0.0
	
	// Multi-selection array
	@Published var selectedIDs: [UUID] = []
    @Published var saveIDs: [UUID] = []
    
    
    // Tracks which tile is being drawn during progressive thumbnail loading.
    // Starts at 0 and increments each frame until all images are placed.
    var currentTileIndex: Int = 0
	
	@Published var previewsLoaded: Bool = false
    
    

}
