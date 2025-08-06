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
			
			HStack(spacing: 10) {
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
		.background(Color("MenuBackground"))
		.frame(maxWidth: .infinity)
		
		
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

        if let currentIndex = items.firstIndex(where: { $0.id == currentId }) {
            let nextIndex = (currentIndex + 1) % items.count
            imageViewModel.currentImgID = items[nextIndex].id
            thumbModel.lastScrolledToID = items[nextIndex].id
            if imageViewModel.imageViewActive {
                pipeline.applyPipelineV2Sync(items[nextIndex].id, dataModel)
            }
        }
    }
    
    private func previousImage() {
        guard let currentId = imageViewModel.currentImgID else { return }

        let items = dataModel.items
        guard !items.isEmpty else { return }

        if let currentIndex = items.firstIndex(where: { $0.id == currentId }) {
            let previousIndex = (currentIndex - 1 + items.count) % items.count
            imageViewModel.currentImgID = items[previousIndex].id
            thumbModel.lastScrolledToID = items[previousIndex].id
            if imageViewModel.imageViewActive {
                pipeline.applyPipelineV2Sync(items[previousIndex].id, dataModel)
            }
        }
    }
	
}
