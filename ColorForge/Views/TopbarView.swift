// TopbarView.swift
// ColorForge Enlarger
//
// Created by admin on 13/08/2024.

import Foundation
import SwiftUI
import AppKit
import UniformTypeIdentifiers






struct TopbarView: View {
	@EnvironmentObject var viewModel: ImageViewModel
	@EnvironmentObject var dataModel: DataModel
	@EnvironmentObject var pipeline: FilterPipeline
	@EnvironmentObject var thumbModel: ThumbnailViewModel
    @EnvironmentObject var shortcut: ShortcutViewModel
    
	@Binding var imageViewActive: Bool
	@Binding var maskingViewActive: Bool
    
    @State private var copiedSettings: CopiedImageSettings? = nil
    @Binding var profile: CopyProfile
    @Binding var showCopySettings: Bool
    
    @State private var copyClicked: Bool = false
    @State private var copyDoubleClickInProgress = false
    @State private var showCopy: Bool = true
    
    @State private var pasteClicked: Bool = false
    @State private var showPaste: Bool = true
    
    
    let haptic = HapticModel.shared
	
	var body: some View {
		VStack(spacing: 0) {
			ZStack {
                HStack {
                    Spacer().frame(width: 75)
                    
                    // MARK: - Toggle Sidebar
                    
                    Image(systemName: "sidebar.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("SideBarText"))
                        .frame(height: 15)
                        .padding(5)
                        .opacity(0.75)
                        .help("Toggle Sidebar")
                    
                    Spacer()
                        .frame(width: 50)
                    
                    // MARK: - Logo
                    
                    Image("enlargerIconTopBar")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 42)
                        .padding(0)
                        .opacity(0.8)
                        .shadow(color: Color("MenuAccent"), radius: 2, x: 0, y: 2)
                    
                    
                    Spacer().frame(width: 50)
                    
                    
                    // MARK: - Copy / Paste Settings
                    
                    ZStack {
                        Image(systemName:
                            showCopySettings ? "arrow.down" :
                            copyClicked ? "arrow.up.right" : "arrow.up.right")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(copyClicked || showCopySettings ? Color("IconActive") : Color("SideBarText"))
                            .frame(height: 23)
                            .scaleEffect(copyClicked ? 1.5 : copyDoubleClickInProgress ? 1.0 : 1.0)
                            .offset(y: copyClicked ? -10 : 0)
                            .opacity(copyClicked ? 0 : copyDoubleClickInProgress ? 1.0 : 1)
                            .padding(5)
                            .help("Copy settings. Double click to set.")
                    }
                    .frame(width: 40, height: 40)
                    .contentShape(Rectangle()) // makes whole 40x40 clickable
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                copyDoubleClickInProgress = true
                                haptic.short()
                                withAnimation {
                                    showCopySettings.toggle()
                                }

                                // Reset flag after double-tap gesture has fully fired
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    copyDoubleClickInProgress = false
                                }
                            }
                    )
                    .simultaneousGesture(
                        TapGesture(count: 1)
                            .onEnded {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                                    if !copyDoubleClickInProgress {
                                        haptic.short()
                                        shortcut.show(.copySettings) // this fire
                                        copySettings()
                                        withAnimation {
                                            copyClicked = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            showCopy = false
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            withAnimation {
                                                showCopy = true
                                            }
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                            copyClicked = false
                                        }
                                    }
                                }
                            }
                    )
                    
                    // Copy Settings Hidden Button
                    Button(action: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                            if !copyDoubleClickInProgress {
                                haptic.short()
                                copySettings()
                                shortcut.show(.copySettings)
                                withAnimation {
                                    copyClicked = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    showCopy = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    withAnimation {
                                        showCopy = true
                                    }
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    copyClicked = false
                                }
                            }
                        }
                    }) {
                        Image(systemName: "arrow.up.right")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(0.01)
                            .frame(width: 1, height: 1)
                            .keyboardShortcut("c", modifiers: [.shift, .command])
                    }
                    .buttonStyle(PlainButtonStyle())
                    .opacity(showPaste ? 1.0 : 0.0)
                    .keyboardShortcut("c", modifiers: [.shift, .command])

						   
					
					// Paste Settings
					Button(action: {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.0) {
                            
                                haptic.short()
                                handlePasteClick()
                                shortcut.show(.pasteSettings)
                                withAnimation {
                                    pasteClicked = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                    showCopy = false
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                                    withAnimation {
                                        showPaste = true
                                    }
                                }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                pasteClicked = false
                            }
                        }
					}) {
						Image(systemName: "arrow.down.left")
							.resizable()
							.aspectRatio(contentMode: .fit)
                            .foregroundColor(pasteClicked ? Color("IconActive") : Color("SideBarText"))
							.frame(height: 23)
                            .scaleEffect(pasteClicked ? 1.5 : 1.0)
                            .offset(y: pasteClicked ? 10 : 0)
                            .opacity(pasteClicked ? 0 : 1)
							.padding(5)
							.help("Paste settings")
					}
                    .contentShape(Rectangle())
					.buttonStyle(PlainButtonStyle())
                    .opacity(showPaste ? 1.0 : 0.0)
					.keyboardShortcut("v", modifiers: [.shift, .command])
					
					
					Spacer().frame(width: 50)
					
					// MARK: - Preset / Version Icons
					
					// Add Preset
					Button(action: {
//						isPresetViewVisible.toggle()
					}) {
						Image("PresetAdd")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(height: 28)
							.padding(.bottom, 5)
							.help("Presets")
					}
					.buttonStyle(PlainButtonStyle())
					
					
					Button(action: {
						
					}) {
						Image("VersionAdd")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(height: 27)
							.padding(5)
							.help("Add Version")
					}
					.buttonStyle(PlainButtonStyle())
					
					
					// MARK: Hidden buttons
					
					
					Button(action: {
//						toggleFullScreenWindow()
					}) {
						Image("VersionAdd")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(height: 1)
							.padding(0)
							.help("")
							.opacity(0)
					}
					.buttonStyle(PlainButtonStyle())
					.keyboardShortcut("f", modifiers: [])
					
					
					Spacer()
				
					
					
					// MARK: - Toggle Crop View
					Button(action: {
//												isCropViewVisible.toggle() // Toggle the thumbnail view
						//						maskingModel.drawingCrop.toggle()
					}) {
						Image(systemName: "crop")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundColor(Color("SideBarText")) // Dynamically set the color
							.frame(height: 31)
							.padding(5)
							.help("Toggle Mask View")
					}
					.buttonStyle(PlainButtonStyle())
					
					//					Spacer().frame(width: 20)
					
					
					// MARK: - Toggle Mask View
					Button(action: {
						maskingViewActive.toggle()
					}) {
						Image(systemName: "circle.righthalf.filled")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundColor(maskingViewActive ? Color("IconActive") : Color("SideBarText"))
							.frame(height: 25)
							.padding(5)
							.help("Toggle Mask View")
					}
					.buttonStyle(PlainButtonStyle())
					.keyboardShortcut("m", modifiers: [])
					
					Spacer().frame(width: 50)
					
					
					// MARK: - Exposure Warning Button
					Button(action: {
					}) {
						Image(systemName: "exclamationmark.triangle")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundColor(Color("SideBarText"))
							.frame(height: 25)
							.padding(5)
							.help("Double click to set warnings")
							.gesture(
								TapGesture(count: 2)
//									.onEnded { isExposurePopoverVisible.toggle() }
							)
					}
					.buttonStyle(PlainButtonStyle())
//					.popover(isPresented: $isExposurePopoverVisible) {
//						VStack(spacing: 10) {
//							// Highlight Warning Input
//							HStack {
//								Text("Highlight:")
//									.frame(width: 70, alignment: .leading)
//									.foregroundStyle(Color("SideBarText"))
//								TextField("", value: $newHighlightWarning, formatter: NumberFormatter())
//									.textFieldStyle(PlainTextFieldStyle())
//									.frame(width: 50)
//									.background(Color("MenuAccent"))
//									.foregroundColor(Color("SideBarText"))
//									.multilineTextAlignment(.center)
//									.font(.system(.caption, weight: .light))
//									.border(Color.black)
//									.padding(3)
//							}
//							
//							// Shadow Warning Input
//							HStack {
//								Text("Shadow:")
//									.frame(width: 70, alignment: .leading)
//									.foregroundStyle(Color("SideBarText"))
//								TextField("", value: $newShadowWarning, formatter: NumberFormatter())
//									.textFieldStyle(PlainTextFieldStyle())
//									.frame(width: 50)
//									.background(Color("MenuAccent"))
//									.foregroundColor(Color("SideBarText"))
//									.multilineTextAlignment(.center)
//									.font(.system(.caption, weight: .light))
//									.border(Color.black)
//									.padding(3)
//							}
//							
//							// Save Button
//							Button("Save") {
//								imageProcessingModel.highlightWarning = newHighlightWarning
//								imageProcessingModel.shadowWarning = newShadowWarning
//								isExposurePopoverVisible = false
//							}
//							.padding(.top, 10)
//						}
//						.padding()
//						.frame(width: 200, height: 100)
//						.onAppear {
//							newHighlightWarning = imageProcessingModel.highlightWarning
//							newShadowWarning = imageProcessingModel.shadowWarning
//						}
//					}
					
					Spacer().frame(width: 50)
					
					// MARK: - Thmbnail View
					Button(action: {
                        
                        shortcut.show(.toggleImageView)
                        
						imageViewActive.toggle()
						if viewModel.imageViewActive == false {
							viewModel.imageViewActive = true
						} else {
							viewModel.imageViewActive = false
						}


//						if imageViewActive {
//							renderPreviewAndThumb()
//							
//							DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//								imageViewActive = false
//							}
//
//						} else {
//							imageViewActive = true
//						}
						
						//
						
					}) {
						Image(systemName: "square.grid.2x2")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundColor(imageViewActive ? Color("SideBarText") : Color("IconActive")) // Dynamically set the color
							.frame(height: 25)
							.padding(5)
							.help("Toggle Thumbnail View")
					}
					.buttonStyle(PlainButtonStyle())
					.keyboardShortcut("g", modifiers: [.command])

					
					
					
					// MARK: - Open Directory Button
					Button(action: {
                        shortcut.show(.openFiles)
						openImages()
					}
					) {
						Image(systemName: "folder.badge.plus")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundColor(Color("SideBarText"))
							.frame(height: 25)
							.padding(5)
							.help("Open Directory")
					}
					.buttonStyle(PlainButtonStyle())
                    .keyboardShortcut("o", modifiers: [.command])
					
					Spacer().frame(width: 50)
					
//					// Reset All
//					Button(action: {
////						showResetAlert = true
//					}) {
//						Image(systemName: "arrow.circlepath")
//							.resizable()
//							.aspectRatio(contentMode: .fit)
//							.foregroundColor(Color("SideBarText"))
//							.frame(height: 25)
//							.padding(5)
//							.help("Open Directory")
//					}
//					.buttonStyle(PlainButtonStyle())
//					.alert(isPresented: $showResetAlert) {
//						Alert(
//							title: Text("Reset All"),
//							message: Text("Are you sure you want to reset all settings?"),
//							primaryButton: .destructive(Text("Reset")) {
//								resetAll()
//							},
//							secondaryButton: .cancel()
//						)
//					}
//					.keyboardShortcut("r", modifiers: [.command])
					
					
					// Settings View
                    Button(action: {
                        /*isSettingsViewPresented.toggle()*/
                        loadSettings()
                    }) {
						Image(systemName: "gearshape")
							.resizable()
							.aspectRatio(contentMode: .fit)
							.foregroundColor(Color("SideBarText"))
							.frame(height: 25)
							.padding(5)
					}
					.buttonStyle(PlainButtonStyle())
//					.sheet(isPresented: $isSettingsViewPresented) {
//						SettingsView()
//							.environmentObject(imageProcessingModel)
//					}
					
					Spacer().frame(width: 20)
				}
				.frame(height: 53)
				.frame(maxWidth: .infinity)
			}
			.background(Color("MenuBackground"))
//			.onChange(of: loadingModel.isFullyLoaded) { newValue in
//				if newValue {
//					withAnimation {
//						displayProgressView = false // Show success message
//					}
//				}
//			}
			//			Divider().overlay(Color("MenuAccent"))
		}// End of VStack
		.padding(.bottom, 2)
		.background(Color("MenuAccent"))
//		.onReceive(NotificationCenter.default.publisher(for: .openDirectory)) { notification in
//			if let folderURL = notification.userInfo?["url"] as? URL {
//				print("TopbarView received folder URL: \(folderURL)")
//				openDirectory(at: folderURL)
//			}
//		}
	}
	
	// MARK: - View controller functions
	
	
    
    
    private func copySettings() {
        guard let id = viewModel.currentImgID else { return }
        guard let item = dataModel.items.first(where: { $0.id == id }) else { return }

        copiedSettings = CopiedImageSettings(from: item, using: profile)
    }
    
    private func handlePasteClick() {
        guard let copied = copiedSettings else { return }

        var ids = thumbModel.saveIDs
        if let currentID = viewModel.currentImgID, !ids.contains(currentID) {
            ids.append(currentID)
        }

        if ids.isEmpty, let currentID = viewModel.currentImgID {
            ids = [currentID]
        }

        let batchSize = 12
        let batches = stride(from: 0, to: ids.count, by: batchSize).map {
            Array(ids[$0..<min($0 + batchSize, ids.count)])
        }

        Task(priority: .userInitiated) {
            for batch in batches {
                await withTaskGroup(of: Void.self) { group in
                    for id in batch {
                        group.addTask {
                            // Apply copied settings on main thread
                            await MainActor.run {
                                dataModel.updateItem(id: id) { item in
                                    copied.apply(to: &item)
                                }
                            }
                            
                            // Pause for 0.05 seconds
                            try? await Task.sleep(nanoseconds: 50_000_000)

                            // Process image
                            guard let processed = await pipeline.applyPipelineV2Sync(id, dataModel) else {
                                return
                            }

                            // Update thumbnail
                            await updateThumbForPaste(id, processed)
                        }
                    }
                }

                // Wait 0.15s between batches
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    
    private func updateThumbForPaste(_ id: UUID, _ processed: CIImage) async {
        let context = RenderingManager.shared.thumbnailContext

        // Step 1: Generate and assign thumbnail immediately (high priority)
        let maxThumbDimension: CGFloat = 500.0
        let thumbScale = maxThumbDimension / max(processed.extent.width, processed.extent.height)
        let scaleTransform = CGAffineTransform(scaleX: thumbScale, y: thumbScale)
        let scaledCIImage = processed.transformed(by: scaleTransform)

        guard let thumbnailCGImage = context.createCGImage(scaledCIImage, from: scaledCIImage.extent) else {
            return
        }
        guard let previewCGImage = context.createCGImage(processed, from: processed.extent) else {
            return
        }

        await MainActor.run {
            
            dataModel.updateItem(id: id) { item in
                item.thumbnailImage = thumbnailCGImage
                item.previewImage = previewCGImage
            }
        }
    }
    

	/*
	 
	 func updateThumbAndCacheForItem(for item: ImageItem) async {
		 let context = RenderingManager.shared.thumbnailContext
		 let thumbScale: CGFloat = 0.3
		 
		 let id = item.id
		 let url = item.url
		 
		 guard let processed = item.processImage else {
			 print("Skipping \(url.lastPathComponent): processImage is nil")
			 return
		 }
		 
		 print("Generating preview for: \(url.lastPathComponent), extent: \(processed.extent)")

		 // Create full-size preview
		 guard let previewCgImage = context.createCGImage(processed, from: processed.extent) else {
			 print("Failed to create CGImage for: \(url.lastPathComponent)")
			 return
		 }
		 
		 let fullSize = processed.extent.size
		 let previewImage = NSImage(cgImage: previewCgImage, size: fullSize)
		 
		 // Downscale for thumbnail
		 let thumbSize = NSSize(width: fullSize.width * thumbScale, height: fullSize.height * thumbScale)
		 let processedThumb = NSImage(size: thumbSize)
		 processedThumb.lockFocus()
		 previewImage.draw(in: NSRect(origin: .zero, size: thumbSize),
						   from: NSRect(origin: .zero, size: fullSize),
						   operation: .copy,
						   fraction: 1.0)
		 processedThumb.unlockFocus()
		 
		 // Insert intermediate cached CIImage if needed
		 let cachedResult = processed.insertingIntermediate(cache: true)
		 
		 await MainActor.run {
			 self.updateItem(id: id) { item in
				 item.thumbnailImage = processedThumb
				 item.previewImage = previewImage
				 item.processImage = cachedResult
			 }
		 }
	 }
	 
	 
	 
	 */
    
    // Should open sandboxed ApplicationSupport/ColorForge
    private func loadSettings() {
        do {
            // Get the app's sandboxed Application Support directory
            let appSupportURL = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            
            // Append ColorForge folder name
            let colorForgeURL = appSupportURL.appendingPathComponent("ColorForge")
            
//            // Create the directory if it doesn't exist
//            try FileManager.default.createDirectory(
//                at: colorForgeURL,
//                withIntermediateDirectories: true,
//                attributes: nil
//            )
            
            // Open the folder in Finder
            NSWorkspace.shared.open(colorForgeURL)
            
        } catch {
            print("Failed to open ColorForge settings folder: \(error)")
            
            // Optional: Show an alert to the user
            let alert = NSAlert()
            alert.messageText = "Unable to Open Settings Folder"
            alert.informativeText = "Could not access the ColorForge settings folder: \(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
	
    private func openImages() {
        dataModel.loading = true
        dataModel.thumbsFullyLoaded = false
		thumbModel.isInitialLoad = true

        let panel = NSOpenPanel()
		
		var types: [UTType] = [
			UTType(filenameExtension: "dng"),
			UTType(filenameExtension: "arw"),
			UTType(filenameExtension: "raf"),
			UTType(filenameExtension: "cr2"),
			UTType(filenameExtension: "cr3"),
			UTType.tiff,                              // .tiff
			UTType(filenameExtension: "tif"),          // .tif
			UTType(filenameExtension: "nef")          // .tif
		].compactMap { $0 }

		// Add dynamic types for Hasselblad
		if let hasselbladFFF = UTType(tag: "fff", tagClass: .filenameExtension, conformingTo: .image) {
			types.append(hasselbladFFF)
		}
		if let hasselblad3FR = UTType(tag: "3fr", tagClass: .filenameExtension, conformingTo: .image) {
			types.append(hasselblad3FR)
		}

		panel.allowedContentTypes = types
        
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            let selectedURLs = panel.urls
            if !selectedURLs.isEmpty {
                Task {
                    await dataModel.loadImagesV2(from: selectedURLs)
                }
            } else {
                // User clicked OK but selected nothing
                dataModel.loading = false
                dataModel.thumbsFullyLoaded = true
            }
        } else {
            // User cancelled the dialog
            dataModel.loading = false
            dataModel.thumbsFullyLoaded = true
        }
    }
	
	
}

