//
//  ThumbnailView.swift
//  ColorForge
//
//  Created by admin on 17/07/2025.
//

import SwiftUI

// Items in view
private struct ItemFrameKey: PreferenceKey {
	static var defaultValue: [UUID: CGRect] = [:]
	static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
		value.merge(nextValue(), uniquingKeysWith: { _, new in new })
	}
}

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
	
	// Items in view
	@State private var itemsInViewPlusBuffer: [UUID] = []

	
	
    var body: some View {
        
        GeometryReader { geo in
            
            
            let totalPadding = (CGFloat(viewModel.colCount) * viewModel.padding) + viewModel.padding
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
											
											// Items in view
											.background( // << add this
												GeometryReader { cellGeo in
													Color.clear
														.preference(
															key: ItemFrameKey.self,
															value: [item.id: cellGeo.frame(in: .global)]
														)
												}
											)
											
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
                    .padding(viewModel.padding)
					
					// Items in view
					.onPreferenceChange(ItemFrameKey.self) { frames in
						// Throttle to ~10 fps using your existing fields
						let now = Date()
						if now.timeIntervalSince(lastResizeTime) < throttleInterval { return }
						lastResizeTime = now

						let viewport = geo.frame(in: .global) // the visible window of this view
//						updateItemsInView(frames: frames, viewport: viewport)
					}
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
                


            }
			.onAppear{
				loadGrain()
			}
            
        } // End of geometry reader
        .background(Color("MenuAccentDark"))
    } // End of view
    
	private func loadGrain() {
		let grainModel = GrainModel.shared
		grainModel.loadGrainIntoCache()
	}
	


	@State private var lastProcessedIndex: Int = -1

	private func updateItemsInView(frames: [UUID: CGRect], viewport: CGRect) {
		let visibleIDs = frames.compactMap { (id, rect) in
			rect.intersects(viewport) ? id : nil
		}

		let indexByID = Dictionary(uniqueKeysWithValues:
			dataModel.items.enumerated().map { ($0.element.id, $0.offset) }
		)

		let visibleIndices = visibleIDs.compactMap { indexByID[$0] }.sorted()

		guard let minIdx = visibleIndices.first, let maxIdx = visibleIndices.last else {
			itemsInViewPlusBuffer = []
			return
		}

		let lower = max(0, minIdx)
		let upper = min(dataModel.items.count - 1, maxIdx)
		itemsInViewPlusBuffer = (lower...upper).map { dataModel.items[$0].id }

		// Batch config
		let batchSize = 20
		let lead = 10                // start 10 past the threshold
		let initialEnd = 29          // we preprocessed 0...29 (first 30)

		// Start batching once we pass 20, 40, 60, ...
		if maxIdx >= 20 {
			// 20 → 30–49, 40 → 50–69, etc.
			let threshold = (maxIdx / batchSize) * batchSize        // 20,40,60,...
			var startIndex = threshold + lead                        // 30,50,70,...
			startIndex = max(startIndex, initialEnd + 1)            // never before 30

			guard startIndex < dataModel.items.count else { return }
			guard startIndex > lastProcessedIndex else { return }   // don’t re-run same batch

			let endIndex = min(startIndex + batchSize - 1, dataModel.items.count - 1)
			let range = startIndex...endIndex

			// Only process items not already cached
			let uncachedItems = dataModel.items[range].filter {
				PixelBufferCache.shared.get($0.id) == nil
			}
			guard !uncachedItems.isEmpty else {
				lastProcessedIndex = startIndex   // avoid re-trigger spam
				return
			}

			lastProcessedIndex = startIndex       // mark as started

			Task(priority: .userInitiated) {
				print("Processing next batch \(startIndex)-\(endIndex) (\(uncachedItems.count) items)")
				await processNextBuffers(uncachedItems)
			}
		}
	}
	
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

        if let buffer = item.debayeredBuffer {
            imgViewModel.currentImage = CIImage(cvPixelBuffer: buffer)
        }
		
        
//        let preview: NSImage
//        
//        if item.previewImage == nil {
//            guard let nsImage = updatePreview(id) else {return}
//            preview = nsImage
//        } else {
//            guard let nsImage = item.previewImage else {return}
//            preview = nsImage
//        }
		
//		imgViewModel.currentPreview = preview
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
        
        if let buffer = item.debayeredBuffer {
            imgViewModel.currentImage = CIImage(cvPixelBuffer: buffer)
        }

//        let preview: NSImage
//        
//        if item.previewImage == nil {
//            guard let nsImage = updatePreview(id) else {return}
//            preview = nsImage
//        } else {
//            guard let nsImage = item.previewImage else {return}
//            preview = nsImage
//        }
//        
//        imgViewModel.currentPreview = preview
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
	
	
	private func processNextBuffers(_ items: [ImageItem]) async {
		let contexts = dataModel.ciContexts
		
		let numContexts = contexts.count

		// Split limitedItems evenly
		let groupedItems = items.enumerated().reduce(into: Array(repeating: [ImageItem](), count: numContexts)) { result, pair in
			let (index, item) = pair
			result[index % numContexts].append(item)
		}
		
		await withTaskGroup(of: Void.self) { group in
			for (index, groupItems) in groupedItems.enumerated() {
				let context = contexts[index]

				group.addTask {
					for item in groupItems {
						let id = item.id
						let url = item.url

						let debayerNode = DebayerNode(rawFileURL: url, scale: item.uiScale)
						let (debayered, xySIMD, baseline) = debayerNode.apply()

						guard let (temp, tint) = debayered.calculateTempAndTintFromXY(xySIMD.x, xySIMD.y) else {
							continue
						}


						print("Using context number \(index)")


						guard let buffer = await debayered.convertDebayeredToBuffer(context) else {
							continue
						}

						// cache key: id + role
						let key = "\(id.uuidString)#preview"
						await PixelBufferCache.shared.set(buffer, for: item.id)



						await MainActor.run {
							dataModel.updateItem(id: id) { item in
//                                item.debayeredBuffer = buffer
								item.debayeredInit = debayered
								item.xyChromaticity = CGPoint(x: CGFloat(xySIMD.x), y: CGFloat(xySIMD.y))
								item.temp = temp
								item.tint = tint
								item.initTemp = temp
								item.initTint = tint
								item.baselineExposure = baseline
							}
						}





						print("""

							Buffer complete for \(item.url.lastPathComponent)

							""")

						await self.processRawsV3(item, buffer, context)

						await MainActor.run {
							print("""

								Processing complete for \(item.url.lastPathComponent)
								""")
						}
					}
				}
			}
		}
		
	}

	
	func processRawsV3(_ item: ImageItem, _ buffer: CVPixelBuffer, _ context: CIContext) async {
		
		let id = item.id
		let ciImage = CIImage(cvPixelBuffer: buffer)
		
		guard let finalImage = FilterPipeline.shared.applyPipelineV2Sync(id, dataModel, ciImage, true) else {return}
		
		
		
		guard let thumb = await finalImage.convertThumbToCGImageBatch(context) else {
			return
		}
		
		await MainActor.run {
			
			dataModel.updateItem(id: id) { item in
				item.processImage = finalImage
				item.thumbnailImage = thumb
			}
		}
		
		item.toDisk(finalImage)
		
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
