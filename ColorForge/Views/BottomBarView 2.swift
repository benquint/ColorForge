//
//  BottomBarView.swift
//  ColorForge Enlarger
//
//  Created by admin on 23/01/2025.
//

import Foundation
import SwiftUI

struct BottomBarView: View {
	@EnvironmentObject var imageProcessingModel: ImageProcessingModel
	@EnvironmentObject var dataModel: DataModel
	@EnvironmentObject var loadingModel: LoadingModel
    
	@State private var isColorPickerExpanded: Bool = false
	@State private var selectedColor: String = "BG_Dark"
    @State private var sortByName: Bool = false
	@State private var lastNavigationTime: DispatchTime = .now()
	
	@State private var iso: String = ""
	@State private var fStop: String = ""
	@State private var shutterSpeed: String = ""
	@State private var cameraModel: String = ""
	
	var body: some View {
		
		ZStack {
			
			if imageProcessingModel.isThumbnail{
				Text(imageProcessingModel.currentFileName)
					.font(.caption)
					.foregroundColor(Color("SideBarText"))
			} else {
				HStack {
					Text(imageProcessingModel.currentFileName)
						.font(.caption)
						.foregroundColor(Color("SideBarText"))
					
					Text(shutterSpeed)
						.font(.caption)
						.foregroundColor(Color("SideBarText"))
					
					Text(fStop)
						.font(.caption)
						.foregroundColor(Color("SideBarText"))
					
					Text("ISO \(iso)")
						.font(.caption)
						.foregroundColor(Color("SideBarText"))
					
					Text(cameraModel)
						.font(.caption)
						.foregroundColor(Color("SideBarText"))
				}
			}
			
			HStack (alignment: .center, spacing: 0) {
				
				// Padding Size
				Image(systemName: "photo")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.foregroundColor(Color("SideBarText"))
					.padding(5)
					.frame(width: 25, height: 25)
				
				if imageProcessingModel.isThumbnail {
					Slider(value: Binding(
						get: { Double(imageProcessingModel.thumbnailPaddingAmount) },
						set: { imageProcessingModel.thumbnailPaddingAmount = Int($0.rounded()) }
					), in: 5...40)
					.frame(width: 100)
					.controlSize(.mini)
					.tint(Color("MenuAccent"))
					.font(.system(.caption, weight: .light))
				}
				if imageProcessingModel.imageViewActive {
					Slider(value: Binding(
						get: { Double(imageProcessingModel.imagePaddingAmount) },
						set: { imageProcessingModel.imagePaddingAmount = Int($0.rounded()) }
					), in: 0...80)
					.frame(width: 100)
					.controlSize(.mini)
					.tint(Color("MenuAccent"))
					.font(.system(.caption, weight: .light))
				}
				
				if imageProcessingModel.isFullScreenView {
					Slider(value: Binding(
						get: { Double(imageProcessingModel.fullScreenPadding) },
						set: { imageProcessingModel.fullScreenPadding = Int($0.rounded()) }
					), in: 0...80)
					.frame(width: 100)
					.controlSize(.mini)
					.tint(Color("MenuAccent"))
					.font(.system(.caption, weight: .light))
				}
				
				
				Image("MorePaddingIconV2")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.foregroundColor(Color("SideBarText"))
					.padding(5)
					.frame(width: 25, height: 25)
				
				
				Spacer()
					.frame(width: 100)
				
				// MARK: - Background Color Icons
				
				// Background Colour Picker
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
				
				
				// Hidden buttons
				
				// Previous / next image
				Button(action: {
                    DispatchQueue.main.async {
                        imageProcessingModel.isNavigating = true
                    }

                    imageProcessingModel.previousUIImage()

                    DispatchQueue.main.async {
                        imageProcessingModel.isNavigating = false
                    }

				}) {
					Image(systemName: "arrow.left.circle")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.foregroundColor(Color("SideBarText"))
						.padding(5)
						.frame(width: 25, height: 25)
						.opacity(0)
				}
				.buttonStyle(PlainButtonStyle())
				.keyboardShortcut(.leftArrow, modifiers: [])
				.disabled(!imageProcessingModel.rawsLoaded)
				
				
				Button(action: {
                    DispatchQueue.main.async {
                        imageProcessingModel.isNavigating = true
                    }

                    imageProcessingModel.nextUIImage()

                    DispatchQueue.main.async {
                        imageProcessingModel.isNavigating = false
                    }

				}) {
					Image(systemName: "arrow.right.circle")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.foregroundColor(Color("SideBarText"))
						.padding(5)
						.frame(width: 25, height: 25)
						.opacity(0)
				}
				.buttonStyle(PlainButtonStyle())
				.keyboardShortcut(.rightArrow, modifiers: [])
				.disabled(!imageProcessingModel.rawsLoaded)
				
				
				
				Spacer()
				
				if imageProcessingModel.isThumbnail {
					
					// Sort by date
					Button(action: {
                        sortByName = false
                        dataModel.sortByDateCreated()
					}) {
						Image(systemName: "clock")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundColor(!sortByName ? Color("IconActive") : Color("SideBarText"))
							.padding(5)
							.frame(width: 25, height: 25)
							.help("Sort by date.")
					}
					.buttonStyle(PlainButtonStyle())
					
					// Sort by name
					Button(action: {
                        sortByName = true
                        dataModel.sortByName()
					}) {
						Image(systemName: "abc")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundColor(sortByName ? Color("IconActive") : Color("SideBarText"))
							.padding(5)
							.frame(width: 35, height: 35)
							.help("Sort by name.")
					}
					.buttonStyle(PlainButtonStyle())
					
					Spacer()
						.frame(width: 50)
					
					// MARK: - Thumbnail Size
					
					Image(systemName: "square.grid.2x2")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.foregroundColor(Color("SideBarText"))
						.padding(5)
						.frame(width: 25, height: 25)
					
					Slider(value: Binding(
						get: { Double(imageProcessingModel.numColumns) },
						set: { imageProcessingModel.numColumns = Int($0.rounded()) }
					), in: 2...10)
					.frame(width: 100)
					.controlSize(.mini)
					.tint(Color("MenuAccent"))
					.font(.system(.caption, weight: .light))
					
					Image(systemName: "square.grid.3x3")
						.resizable()
						.aspectRatio(contentMode: .fit)
						.foregroundColor(Color("SideBarText"))
						.padding(5)
						.frame(width: 25, height: 25)
				} // End of HStack
				
			} // End of ZStack
			
			
		}// End of bottom bar
		.padding(.horizontal, 10) // Left and right padding of 20
		.frame(height: 35)
		.background(Color("MenuBackground"))
		.frame(maxWidth: .infinity)
		.onChange(of: navigationRequest) { _ in
			handleNavigationRequest()
		}
		.onAppear{
			fetchCurrentMetaData()
		}
		.onChange(of: imageProcessingModel.selectedImageURL) { _ in
			fetchCurrentMetaData()
		}
	
	}// End of body
	
	
	// Helper function to apply background colour
	private func applyBackgroundColor(_ color: String) {
		switch color {
		case "BG_Black":
			if imageProcessingModel.isThumbnail {
				imageProcessingModel.thumbnailBackgroundColor = "Cell_Black"
				imageProcessingModel.thumbnailCellColor = "BG_Black"
			} else if imageProcessingModel.isFullScreenView{
				imageProcessingModel.fullScreenBackground = "BG_Black"
			} else {
				imageProcessingModel.imageBackgroundColor = "BG_Black"
			}
		case "BG_Dark":
			if imageProcessingModel.isThumbnail {
				imageProcessingModel.thumbnailBackgroundColor = "Cell_Dark"
				imageProcessingModel.thumbnailCellColor = "BG_Dark"
			} else if imageProcessingModel.isFullScreenView{
				imageProcessingModel.fullScreenBackground = "BG_Dark"
			} else {
				imageProcessingModel.imageBackgroundColor = "BG_Dark"
			}
		case "BG_Mid":
			if imageProcessingModel.isThumbnail {
				imageProcessingModel.thumbnailBackgroundColor = "Cell_Mid"
				imageProcessingModel.thumbnailCellColor = "BG_Mid"
			} else if imageProcessingModel.isFullScreenView{
				imageProcessingModel.fullScreenBackground = "BG_Mid"
			} else {
				imageProcessingModel.imageBackgroundColor = "BG_Mid"
			}
		case "BG_Light":
			if imageProcessingModel.isThumbnail {
				imageProcessingModel.thumbnailBackgroundColor = "Cell_Light"
				imageProcessingModel.thumbnailCellColor = "BG_Light"
			}  else if imageProcessingModel.isFullScreenView{
				imageProcessingModel.fullScreenBackground = "BG_Light"
			} else {
				imageProcessingModel.imageBackgroundColor = "BG_Light"
			}
		case "BG_White":
			if imageProcessingModel.isThumbnail {
				imageProcessingModel.thumbnailBackgroundColor = "Cell_White"
				imageProcessingModel.thumbnailCellColor = "BG_White"
			} else if imageProcessingModel.isFullScreenView{
				imageProcessingModel.fullScreenBackground = "BG_White"
			}  else {
				imageProcessingModel.imageBackgroundColor = "BG_White"
			}
		default:
			break
		}
	}
	
	@State private var isNavigatingLocal: Bool = false
	@State private var navigationRequest: NavigationAction? = nil
	@State private var pressCount: Int = 0 // Track number of presses

	enum NavigationAction {
		case previous, next
	}

	// Handles navigation, but cancels if too many presses occur in a short time
	private func handleNavigationRequest() {
		guard imageProcessingModel.rawsLoaded else { return }
		guard let action = navigationRequest, !isNavigatingLocal else { return }
		
		let now = DispatchTime.now()
		let debounceInterval: DispatchTimeInterval = .milliseconds(50) // 0.1 seconds

		// Increment press count
		pressCount += 1

		// Cancel navigation if pressed more than 3 times within 1 second
		if pressCount > 3 {
			print("❌ Navigation canceled due to excessive presses.")
			navigationRequest = nil
			pressCount = 0
			return
		}

		// Ensure at least 0.2s has passed before allowing navigation
		guard now > lastNavigationTime + debounceInterval else { return }

		lastNavigationTime = now
		isNavigatingLocal = true

		// Perform the requested action
		switch action {
		case .previous:
			imageProcessingModel.isNavigating = true
			imageProcessingModel.previousUIImage()
			
		case .next:
			imageProcessingModel.isNavigating = true
			imageProcessingModel.nextUIImage()
			
		}

//		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			isNavigatingLocal = false
			imageProcessingModel.isNavigating = false
			navigationRequest = nil // Reset request
//		}

		// Reset press count after 1 second to avoid cumulative presses
		DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
			pressCount = 0
		}
	}

	private func fetchCurrentMetaData () {
		
		DispatchQueue.main.async {
			guard let selectedURL = self.imageProcessingModel.selectedImageURL,
				  let currentImageIndex = self.dataModel.rawImages.firstIndex(where: { $0.rawUrl == selectedURL }) else {
				print("Error: No selected image found in data model")
				return
			}
			
			let currentImage = dataModel.rawImages[currentImageIndex]
			
			iso = currentImage.iso
			fStop = currentImage.fStop
			shutterSpeed = currentImage.shutterSpeed
			cameraModel = currentImage.cameraMake
		}
	}

	

	
	
}// End of Struct
