//
//  BottomBarView.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import Foundation
import SwiftUI

struct BottomBarView: View {
	@EnvironmentObject var pipeline: FilterPipeline
	@EnvironmentObject var dataModel: DataModel
	@EnvironmentObject var imageViewModel: ImageViewModel
    @EnvironmentObject var thumbModel: ThumbnailViewModel
	
	@State private var isColorPickerExpanded: Bool = false
	@State private var selectedColor: String = "BG_Dark"
	
	var body: some View {
		
		
		HStack (alignment: .center, spacing: 0) {
			
            Spacer()
                .frame(width: 330)
            
			// MARK: - Padding
			Image(systemName: "photo")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.foregroundColor(Color("SideBarText"))
				.padding(5)
				.frame(width: 25, height: 25)
			
			Slider(value: Binding(
				get: { Double(imageViewModel.padding) },
                set: {
                    imageViewModel.padding = CGFloat($0.rounded())
                    updatePipeline()
                }
			), in: 0...80)
			.frame(width: 100)
			.controlSize(.mini)
			.tint(Color("MenuAccent"))
			.font(.system(.caption, weight: .light))
			
			Image("MorePaddingIconV2")
				.resizable()
				.aspectRatio(contentMode: .fit)
				.foregroundColor(Color("SideBarText"))
				.padding(5)
				.frame(width: 25, height: 25)
			
			Spacer()
				.frame(width: 100)
			
			
			// MARK: - Background Color Icons
			
			HStack(spacing: 0) {
				if isColorPickerExpanded {
					// Show all buttons when expanded
					ForEach(["BG_Black", "BG_Dark", "BG_Mid", "BG_Light", "BG_White"], id: \.self) { color in
						Button(action: {
							applyBackgroundColor(color)
							selectedColor = color // Update the selected colour
							withAnimation {
								isColorPickerExpanded.toggle()
							}
						}) {
							ZStack {
								// Background icon (filled square)
								Image(systemName: "square.fill")
									.resizable()
									.aspectRatio(contentMode: .fit)
									.padding(5)
									.frame(width: 25, height: 25)
									.foregroundColor(Color(color))
								
								// Foreground icon (outline square)
								Image(systemName: "square")
									.resizable()
									.aspectRatio(contentMode: .fit)
									.padding(5)
									.frame(width: 25, height: 25)
									.foregroundColor(Color("SideBarText"))
							}
						}
						.buttonStyle(PlainButtonStyle())
					}
				} else {
					// Show only the selected colour button when collapsed
					Button(action: {
						withAnimation {
							isColorPickerExpanded.toggle()
						}
					}) {
						ZStack {
							// Selected background colour (filled square)
							Image(systemName: "square.fill")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.padding(5)
								.frame(width: 25, height: 25)
								.foregroundColor(Color(selectedColor))
							
							// Foreground icon (outline square)
							Image(systemName: "square")
								.resizable()
								.aspectRatio(contentMode: .fit)
								.padding(5)
								.frame(width: 25, height: 25)
								.foregroundColor(Color("SideBarText"))
						}
					}
					.buttonStyle(PlainButtonStyle())
				}
			}
			.transition(.slide) // Animated transition
			
			Spacer()
			
			if imageViewModel.imageViewActive {
				if let url = pipeline.currentURL {
					Text(url.lastPathComponent)
						.font(.caption)
						.foregroundColor(Color("SideBarText"))
				}
			}
			
			Spacer()
			
            
            // MARK: - Previous / Next
            Button(action: {
                previousImage()
            }) {
                    Image(systemName: "square.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 1, height: 1)

            }
            .buttonStyle(PlainButtonStyle())
            .opacity(0)
            .keyboardShortcut(.leftArrow, modifiers: [])
            
            
            Button(action: {
                nextImage()
            }) {
                    Image(systemName: "square.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 1, height: 1)

            }
            .buttonStyle(PlainButtonStyle())
            .opacity(0)
            .keyboardShortcut(.rightArrow, modifiers: [])
			
			
		}
		.padding(.horizontal, 10) // Left and right padding of 20
        .padding(.vertical, 0)
		.background(Color("MenuBackground"))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
		
	}
	
	
	private func applyBackgroundColor(_ color: String) {
		switch color {
		case "BG_Black":
			imageViewModel.backgroundColor = "BG_Black"
            updatePipeline()
		case "BG_Dark":
			
			imageViewModel.backgroundColor = "BG_Dark"
            updatePipeline()
			
		case "BG_Mid":
			imageViewModel.backgroundColor = "BG_Mid"
            updatePipeline()
			
		case "BG_Light":
			
			imageViewModel.backgroundColor = "BG_Light"
            updatePipeline()
			
		case "BG_White":
			imageViewModel.backgroundColor = "BG_White"
            updatePipeline()
		default:
			break
		}
	}
    
    func updatePipeline() {
        guard let renderer = RenderingManager.shared.renderer else {
            print("UpdatePipeline - No renderer available")
            return }
        guard let result = pipeline.currentResult else {
            print("UpdatePipeline - No current result")
            return }
        renderer.updateImage(result)
        
    }
	
    
    private func nextImage() {
        guard let currentId = imageViewModel.currentImgID else { return }

        let items = dataModel.items
        guard !items.isEmpty else { return }
        
        guard let item = items.first(where: { $0.id == currentId }) else {
            print("No item found for ID: \(currentId)")
            return
        }
        
        item.toDisk()
        

        if let currentIndex = items.firstIndex(where: { $0.id == currentId }) {
            let nextIndex = (currentIndex + 1) % items.count
            let nextIndexPlus2 = (currentIndex + 2) % items.count
            let newItem = items[nextIndex]
            let nextItem = items[nextIndexPlus2]
            
            imageViewModel.currentImgID = newItem.id
            thumbModel.lastScrolledToID = newItem.id
            imageViewModel.nativeWidth = newItem.nativeWidth
            imageViewModel.nativeHeight = newItem.nativeHeight
            
            if imageViewModel.imageViewActive {
                pipeline.applyPipelineV2Sync(items[nextIndex].id, dataModel)
            }
            
            if let pixelBuffer = PixelBufferCache.shared.get(newItem.id) {
                imageViewModel.currentImage = CIImage(cvPixelBuffer: pixelBuffer)
               // use ciImage
            } else {
                print("No buffer available")
            }

            
            // Fetch next + 2 display image if not cached, and hr image if not cached.
            Task (priority: .userInitiated) {
                
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                if !PixelBufferCache.shared.contains(nextItem.id) {
                    await dataModel.getDisplay(nextItem)
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
                if !PixelBufferHRCache.shared.contains(newItem.id) {
                    await dataModel.getHR(newItem)
                }
            }
        }
    }
    
    private func previousImage() {
        guard let currentId = imageViewModel.currentImgID else { return }

        let items = dataModel.items
        guard !items.isEmpty else { return }
        
        guard let item = items.first(where: { $0.id == currentId }) else {
            print("No item found for ID: \(currentId)")
            return
        }
        
        item.toDisk()

        // Navigate first
        if let currentIndex = items.firstIndex(where: { $0.id == currentId }) {
            let previousIndex = (currentIndex - 1 + items.count) % items.count
            let previousIndexPlus2 = (currentIndex - 2 + items.count) % items.count
            let newItem = items[previousIndex]
            let nextItem = items[previousIndexPlus2]
            
            imageViewModel.currentImgID = newItem.id
            thumbModel.lastScrolledToID = newItem.id
            imageViewModel.nativeWidth = newItem.nativeWidth
            imageViewModel.nativeHeight = newItem.nativeHeight
            
            if imageViewModel.imageViewActive {
                pipeline.applyPipelineV2Sync(newItem.id, dataModel)
            }
            
            if let pixelBuffer = PixelBufferCache.shared.get(newItem.id) {
                imageViewModel.currentImage = CIImage(cvPixelBuffer: pixelBuffer)
               // use ciImage
            } else {
                print("No buffer available")
            }

            
            // Then start HR processing with debounce
            Task (priority: .userInitiated) {
                
                try? await Task.sleep(nanoseconds: 500_000_000)
                
                if !PixelBufferCache.shared.contains(nextItem.id) {
                    await dataModel.getDisplay(nextItem)
                }
                
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
                if !PixelBufferHRCache.shared.contains(newItem.id) {
                    await dataModel.getHR(newItem)
                }

            }
        }
    }
	
}
