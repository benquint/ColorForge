//
//  ThumbnailView.swift
//  ColorForge
//
//  Created by admin on 17/07/2025.
//

import SwiftUI



struct ThumbnailView: View {
	@EnvironmentObject var pipeline: FilterPipeline
	@EnvironmentObject var dataModel: DataModel
	@EnvironmentObject var viewModel: ThumbnailViewModel
	@EnvironmentObject var imgViewModel: ImageViewModel
	

	@State private var selectedID: UUID?
    @StateObject private var modifierTracker = ModifierTracker()
	
	@Binding var imageViewActive: Bool
	
	@State private var lastResizeTime: Date = .distantPast
	private let throttleInterval: TimeInterval = 0.1 // 10 FPS cap
	
	@State private var imgCount: CGFloat = 0.0
	private static let initialColumns = 5 // Same as viewModels default
	@State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
	@State private var itemPositions: [UUID: CGPoint] = [:] // Persist overlay positions
	

	
	
    var body: some View {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let backingScaleFactor = screen.backingScaleFactor
        
        GeometryReader { geo in
            
            let paddingPoints = viewModel.padding / CGFloat(backingScaleFactor)
            let totalPadding = (CGFloat(viewModel.colCount) * paddingPoints) + paddingPoints
            let cellSize = (geo.size.width - totalPadding) / CGFloat(viewModel.colCount)
            
            
            ScrollViewReader { proxy in
                ScrollView {
                    Grid(horizontalSpacing: viewModel.padding, verticalSpacing: viewModel.padding) {
                        ForEach(dataModel.items.indices, id: \.self) { index in
                            if index % viewModel.colCount == 0 {
                                GridRow {
                                    ForEach(0..<viewModel.colCount, id: \.self) { col in
                                        let itemIndex = index + col
                                        if itemIndex < dataModel.items.count {
                                            let item = dataModel.items[itemIndex]
                                            
                                            ItemClear(
                                                size: cellSize,
                                                item: item,
                                                isSelected: viewModel.saveIDs.contains(item.id) || imgViewModel.currentImgID == item.id
                                            ) {
                                                onDoubleTapID(item.id)
                                            }
                                            .cornerRadius(8.0)
                                            .aspectRatio(1, contentMode: .fit)
                                            .id(item.id)
                                            .onTapGesture {
                                                let clickedID = item.id

                                                if modifierTracker.isCommandPressed {
                                                    // Toggle selection
                                                    if let idx = viewModel.saveIDs.firstIndex(of: clickedID) {
                                                        viewModel.saveIDs.remove(at: idx)
                                                    } else {
                                                        viewModel.saveIDs.append(clickedID)
                                                    }
                                                    viewModel.lastClickedIndex = itemIndex

                                                } else if modifierTracker.isShiftPressed, let anchorIndex = viewModel.lastClickedIndex {
                                                    // Shift-click selection
                                                    let lower = min(anchorIndex, itemIndex)
                                                    let upper = max(anchorIndex, itemIndex)

                                                    let rangeIDs = dataModel.items[lower...upper].map { $0.id }

                                                    viewModel.saveIDs = rangeIDs
                                                    // Don't update lastClickedIndex here

                                                } else {
                                                    // Normal click: clear selection
                                                    viewModel.saveIDs = []
                                                    imgViewModel.currentImgID = clickedID
                                                    viewModel.lastClickedIndex = itemIndex
                                                    onSingleClick(clickedID)
                                                }
                                            }
                                        } else {
                                            Color.clear.frame(width: cellSize, height: cellSize)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(paddingPoints)
                }
                
                .onAppear {
                    if let savedID = viewModel.lastScrolledToID {
                        proxy.scrollTo(savedID, anchor: .center)
                        
                    }
                }
                .onDisappear {
                    if let id = imgViewModel.currentImgID {
                        viewModel.lastScrolledToID = id
                    }
                }
                .onChange(of: imgViewModel.currentImgID) {
                    updateHistogram()
                }
                
                // Select All
                Button(action: {
                    selectAll()
                }) {
                    Image(systemName: "arrow.up.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(0.01)
                        .frame(width: 1, height: 1)
                        .keyboardShortcut("c", modifiers: [.shift, .command])
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(0)
                .keyboardShortcut("a", modifiers: [.command])
                
                // Deselect all
                Button(action: {
                    deselect()
                }) {
                    Image(systemName: "arrow.up.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .opacity(0.01)
                        .frame(width: 1, height: 1)
                        .keyboardShortcut("c", modifiers: [.shift, .command])
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(0)
                .keyboardShortcut("d", modifiers: [.command])
                
                
//                // Move up
//                Button(action: {
//                    moveUpOneRow()
//                }) {
//                    Image(systemName: "arrow.up.right")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .opacity(0.01)
//                        .frame(width: 1, height: 1)
//                        .keyboardShortcut("c", modifiers: [.shift, .command])
//                }
//                .buttonStyle(PlainButtonStyle())
//                .opacity(0)
//                .keyboardShortcut(.upArrow, modifiers: [])
//                
//                
//                // Move Down
//                Button(action: {
//                    moveDownOneRow()
//                }) {
//                    Image(systemName: "arrow.up.right")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .opacity(0.01)
//                        .frame(width: 1, height: 1)
//                        .keyboardShortcut("c", modifiers: [.shift, .command])
//                }
//                .buttonStyle(PlainButtonStyle())
//                .opacity(0)
//                .keyboardShortcut(.downArrow, modifiers: [])
                

            }
            
        } // End of geometry reader
        .background(Color("MenuAccentDark"))
    } // End of view
    
    private func selectAll() {
        let items = dataModel.items
        viewModel.saveIDs = items.map { $0.id }
    }
    
    private func deselect() {
        viewModel.saveIDs = []
        imgViewModel.currentImgID = nil
    }
    
    private func moveUpOneRow() {
        guard let currentId = imgViewModel.currentImgID else { return }

        let items = dataModel.items
        guard !items.isEmpty else { return }

        guard let currentIndex = items.firstIndex(where: { $0.id == currentId }) else { return }

        let newIndex = currentIndex - viewModel.colCount
        guard newIndex >= 0 else { return }

        let newItem = items[newIndex]
        imgViewModel.currentImgID = newItem.id
    }
    
    private func moveDownOneRow() {
        guard let currentId = imgViewModel.currentImgID else { return }

        let items = dataModel.items
        guard !items.isEmpty else { return }

        guard let currentIndex = items.firstIndex(where: { $0.id == currentId }) else { return }

        let newIndex = currentIndex + viewModel.colCount
        guard newIndex < items.count else { return }

        let newItem = items[newIndex]
        imgViewModel.currentImgID = newItem.id
    }
    

    
    private func updateHistogram() {
        guard let id = imgViewModel.currentImgID else { return }
        guard let item = dataModel.items.first(where: { $0.id == id }) else { return }
        
        if let processed = item.processImage {
            HistogramModel.shared.generateData(processed)
        }
    }
	
	func onSingleClick(_ id: UUID) {
		guard let item = dataModel.items.first(where: { $0.id == id }) else {
			print("❌ onSingleClick: No item found for ID: \(id)")
			return
		}
		
//        if item.debayeredInit == nil {
//            getDebayered(id)
//        }
        
		imgViewModel.currentImage = item.processImage
        
        let preview: NSImage
        
        if item.previewImage == nil {
            guard let nsImage = updatePreview(id) else {return}
            preview = nsImage
        } else {
            guard let nsImage = item.previewImage else {return}
            preview = nsImage
        }
		
		imgViewModel.currentPreview = preview
		imgViewModel.calculateUIImageSize()
		imgViewModel.currentImgID = id

		pipeline.currentURL = item.url
		
		imgViewModel.nativeWidth = item.nativeWidth
		imgViewModel.nativeHeight = item.nativeHeight

		imgViewModel.renderingComplete = false
		
		print("SingleClick: Item has preview image: \(item.previewImage != nil)")
		// Set the selected ID
		selectedID = item.id
	}
	
	func onDoubleTapID(_ id: UUID) {
		guard let item = dataModel.items.first(where: { $0.id == id }) else { return }
        
//        if item.debayeredInit == nil {
//            getDebayered(id)
//        }
        
		imgViewModel.currentImage = item.processImage
        let preview: NSImage
        
        if item.previewImage == nil {
            guard let nsImage = updatePreview(id) else {return}
            preview = nsImage
        } else {
            guard let nsImage = item.previewImage else {return}
            preview = nsImage
        }
        
        imgViewModel.currentPreview = preview
		imgViewModel.imageViewActive = true
		imgViewModel.calculateUIImageSize()
		imgViewModel.currentImgID = id


		dataModel.updateItem(id: id) { item in
			item.isExport = false
		}
		
		imgViewModel.nativeWidth = item.nativeWidth
		imgViewModel.nativeHeight = item.nativeHeight

		
		imgViewModel.renderingComplete = false
		
		print("DoubleClick: Item has preview image: \(item.previewImage != nil)")
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			imageViewActive = true
		}
	}

	
	private func calculateImageWidth() -> CGFloat {
		let width = imgViewModel.thumbViewSize.width
		let height = imgViewModel.thumbViewSize.height
		
		guard let img = imgViewModel.currentImage else {return 0.0}
		
		let imgWidth = img.extent.width
		let imgHeight = img.extent.height
		
		
		let aspectRatio = imgWidth / imgHeight
		let viewAspect = height / height
		
		var scaledWidth: CGFloat = 0
		
		if viewAspect >= 1.0 {
			scaledWidth = ((imgHeight / height) - (2 * imgViewModel.padding)) * aspectRatio
		} else {
			scaledWidth = (imgWidth / width) - (2 * imgViewModel.padding)
		}

		return scaledWidth
	}
    

	
	
	private func calculateImageHeight() -> CGFloat {
		let width = imgViewModel.thumbViewSize.width
		let height = imgViewModel.thumbViewSize.height
		
		guard let img = imgViewModel.currentImage else {return 0.0}
		
		let imgWidth = img.extent.width
		let imgHeight = img.extent.height
		
		
		let aspectRatio = imgWidth / imgHeight
		let viewAspect = height / height
		
		var scaledHeight: CGFloat = 0
		
		if viewAspect >= 1.0 {
			scaledHeight = (imgHeight / height) - (2 * imgViewModel.padding)
		} else {
			scaledHeight = ((imgHeight / width) - (2 * imgViewModel.padding)) / aspectRatio
		}
		
		return scaledHeight
	}
	
	
	
    private func updatePreview(_ id: UUID) -> NSImage? {
        guard let item = dataModel.items.first(where: { $0.id == id }) else {return nil}
        
        
        guard let processed = item.processImage else {
                print("No Processed Image")
            return nil
        }
        
        let context = RenderingManager.shared.mainImageContext
        
        // Create a CGImage from the CIImage
        guard let cgImage = context.createCGImage(processed, from: processed.extent) else {
            return nil
        }
        
        // Wrap it in an NSImage
        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let nsImage = NSImage(cgImage: cgImage, size: size)
        
        DispatchQueue.main.async {
            dataModel.updateItem(id: id) { item in
                item.previewImage = nsImage
            }
        }
        
        return nsImage
    }
}

class ModifierTracker: ObservableObject {
    @Published var isCommandPressed: Bool = false
    @Published var isShiftPressed: Bool = false

    init() {
        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            DispatchQueue.main.async {
                self.isCommandPressed = event.modifierFlags.contains(.command)
                self.isShiftPressed = event.modifierFlags.contains(.shift)
            }
            return event
        }
    }
}
