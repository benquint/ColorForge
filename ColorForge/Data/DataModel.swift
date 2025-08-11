//
//  DataModel.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import Foundation
import CoreImage
import CoreGraphics
import AppKit

class DataModel: ObservableObject {
    static let shared = DataModel(pipeline: FilterPipeline())
	
	@Published var items: [ImageItem] = []

	
	
	@Published var undoManager: UndoManager?
	
	
	@Published var thumbsFullyLoaded: Bool = false
	@Published var loading: Bool = false
	
	let pipeline: FilterPipeline
    
    let ciContexts: [CIContext]


	init(pipeline: FilterPipeline) {
		self.pipeline = pipeline
        

        let device = MTLCreateSystemDefaultDevice()!
        let options: [CIContextOption: Any] = [
            .workingColorSpace: NSNull(),
            .outputColorSpace: NSNull(),
            .name: "batchContext",
            .outputPremultiplied: false,
            .useSoftwareRenderer: false,
            .workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
            .allowLowPower: false,
            .highQualityDownsample: false,
            .priorityRequestLow: false,
            .cacheIntermediates: false,
            .memoryTarget: 4_294_967_296
        ]
        
        var count: Int32 = 0
        var size = MemoryLayout<Int32>.size
        
        let result = sysctlbyname("hw.perflevel0.logicalcpu", &count, &size, nil, 0)

        let maxCores: Int
        if result == 0 {
            maxCores = Int(count)
        } else {
            maxCores = 1 // fallback
        }
        
        let numContexts = max(1, maxCores - 1)

        self.ciContexts = (0..<numContexts).map { _ in CIContext(mtlDevice: device, options: options) }

        print("Initialized \(ciContexts.count) CIContexts.")
	}
    

	
	
	// Bindings
    public var bindingCache: [String: Any] = [:]
    public var cachedBindingId: UUID?
	var itemIndexMap: [UUID: Int] {
		Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.id, $0) })
	}
	
    func saveAllImageItemsToDisk() {
        for item in self.items {
            item.toDisk()
        }
        print("Saved all ImageItems to disk before termination.")
    }
	
    
    // MARK: - Load Images
    func loadImagesV2(from urls: [URL]) async {
        Task(priority: .userInitiated) {
            do {
                var restoredItems: [ImageItem] = []
                var newURLs: [URL] = []

                // Step 1: Attempt to load saved items from manifest
                for url in urls {
                    if let saveItem = self.loadSaveItem(for: url) {
                        var restoredItem = saveItem.toImageItem()

                        // Load cached JPEG preview (as NSImage)
                        if let cachedImage = self.loadPreviewImage(for: url) {
                            restoredItem.thumbnailImage = cachedImage
                            restoredItem.previewImage = cachedImage
                        }

                        restoredItems.append(restoredItem)
                    } else {
                        newURLs.append(url)
                    }
                }

                // Step 2: Create new ImageItems for the rest
                let newItems = try await createStructs(from: newURLs)
                
//                await extractThumbs(newItems)

                // Step 3: Combine everything locally
                let allItems = restoredItems + newItems

                // Step 4: Append to model
                await MainActor.run {
                    self.items.append(contentsOf: allItems)
                }

                // Step 5: Continue with processing
                await self.getMetaData(allItems)
				
				await MainActor.run {
					self.thumbsFullyLoaded = true
					self.loading = false
					ImageViewModel.shared.processingComplete = true
				}

                await withTaskGroup(of: Void.self) { group in
//                    group.addTask(priority: .userInitiated) {
//                        await MainActor.run {
//                            self.thumbsFullyLoaded = true
//                            self.loading = false
//                            ImageViewModel.shared.processingComplete = true
//                        }
//                    }

                    group.addTask(priority: .userInitiated) {
                        await self.debayerInit(for: allItems)
                    }
                }
                
                await MainActor.run {
                    ImageViewModel.shared.processingFullyComplete = true
                }

//                await debayerHRBatchInit(for: allItems)

            } catch {
                print("Failed to load images: \(error)")
            }
        }
    }
    
    
    // MARK: -
    
    private func extractThumbs(_ items: [ImageItem]) async {
        for item in items {
            
            let id = item.id
            let url = item.url
            
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 500,
                kCGImageSourceShouldCache: false,
                kCGImageSourceShouldCacheImmediately: false
            ]
            
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                print("❌ Failed to extract thumbnail for \(url)")
                continue
            }

                
            await MainActor.run{
                let previewImage = NSImage(cgImage: cgImage, size: .zero)
                
                self.updateItem(id: id) {item in
                    item.thumbnailImage = previewImage
                }
            }
        }
    }
    
    
    // MARK: - Load previous
    
    func loadSaveItem(for imageURL: URL) -> SaveItem? {
        let manifest = AppDataManager.shared.manifest

        // Step 1: Try to find the corresponding ImageManifest
        guard let match = manifest.images.first(where: { $0.imageURL == imageURL }) else {
            print("No matching entry in manifest for \(imageURL.lastPathComponent)")
            return nil
        }

        // Step 2: Try to load and decode the JSON file
        do {
            let data = try Data(contentsOf: match.settingsURL)
            let decoder = JSONDecoder()
            let saveItem = try decoder.decode(SaveItem.self, from: data)
            print("Loaded settings from: \(match.settingsURL.lastPathComponent)")
            return saveItem
        } catch {
            print("Failed to load or decode settings for \(imageURL.lastPathComponent): \(error)")
            return nil
        }
    }
    
    func loadPreviewImage(for imageURL: URL) -> NSImage? {
        let manifest = AppDataManager.shared.manifest

        guard let match = manifest.images.first(where: { $0.imageURL == imageURL }),
              let previewURL = match.previewURL else {
            return nil
        }

        return NSImage(contentsOf: previewURL)
    }
		
	// MARK: - Create items
	func createStructs(from urls: [URL]) async throws -> [ImageItem] {
		var newItems: [ImageItem] = []


		for url in urls {
			let id = UUID()
			let now = Date()

			let item = ImageItem(
				id: id,
				url: url,
				importDate: now,
				captureDate: now // TODO: replace with EXIF extraction if available
			)

			newItems.append(item)
			
			// Register image in background (assumed thread-safe)
			ImageRegistry.shared.register(
				url: url,
				captureDate: now,
				id: id
			)
		}

		return newItems
	}


    // MARK: - Save Items
    
    private func saveItems(_ items: [ImageItem]) async {
        for item in items {
            guard let processImage = item.processImage else { continue }
            
            item.toDisk(processImage)
        }
    }
    
	

	// MARK: - ProcessRaws
    
    

    
    private func getMetaData(_ items: [ImageItem]) async {
        for item in items {
            let id = item.id
            let url = item.url
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
                continue
            }
            
            let width = metadata[kCGImagePropertyPixelWidth] as? Int ?? 0
            let height = metadata[kCGImagePropertyPixelHeight] as? Int ?? 0
            let orientation = metadata[kCGImagePropertyOrientation] as? Int ?? 1

            let exif = metadata[kCGImagePropertyExifDictionary] as? [CFString: Any]
            let gps = metadata[kCGImagePropertyGPSDictionary] as? [CFString: Any]
            let iptc = metadata[kCGImagePropertyIPTCDictionary] as? [CFString: Any]
            
            let scale = await calculateScale(width: width, height: height, rotation: orientation)
            print("🔍 Scale for \(url.lastPathComponent): \(scale) (w: \(width), h: \(height), rot: \(orientation))")
                  
            await MainActor.run {
                self.updateItem(id: id) { item in
                    item.exifDict = exif
                    item.gpsDict = gps
                    item.iptcDict = iptc
                    item.nativeWidth = width
                    item.nativeHeight = height
                    item.nativeRotation = orientation
                    item.uiScale = scale
                }
            }
        }
    }
    
    
    func calculateScale(width: Int, height: Int, rotation: Int) async -> Float {
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 2048, height: 2048)
        let screenShortEdge = min(screenSize.width, screenSize.height)
        
        let targetSize: CGFloat
        var scale: Float = 1.0
        
        if screenShortEdge > 2048.0 {
            targetSize = screenShortEdge
            
            if rotation == 6 || rotation == 8 {
                scale = Float(targetSize) / Float(width)
            } else {
                scale = Float(targetSize) / Float(height)
            }
            
            return scale * 0.7
            
        } else {
            targetSize = 2048.0
            
            if rotation == 6 || rotation == 8 {
                scale = Float(targetSize) / Float(width)
            } else {
                scale = Float(targetSize) / Float(height)
            }
            
            return scale
        }
    }
    
    
	
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
//				item.processImage = cachedResult
			}
		}
	}

    
    func generateHald() -> CIImage? {
        let lutModel = LutModel.shared
        let haldRect = CGRect(x: 0, y: 0, width: 4096.0, height: 64.0)
        var hald = CIImage(color: .red).cropped(to: haldRect)
        if let haldImage = lutModel.generateFloatCubeImage(size: 64) {
            hald = haldImage
            return hald
        } else {
            return nil
        }
    }
	
    
    func initialiseHaldImages(for items: [ImageItem], hald: CIImage) async {

        for item in items {
            let id = item.id

            await MainActor.run {
                self.updateItem(id: id) { item in
                    item.hald1 = hald
                    item.hald2 = hald
                    item.hald3 = hald
                    item.hald4 = hald
					item.c1Hald = hald
                }
            }
        }
    }
    
    
    // Debayer Full
    
    func debayerFullRes(for item: ImageItem) async {
        print("Starting high res debayering")
        
        let id = item.id
        let url = item.url
        
    
        let node = DebayerFullNode(rawFileURL: url, scale: 1.0)
        let debayered = node.apply()
        print("Debayered extent = \(debayered.extent)")

        
        print("""
            High Res Process Debug:
            
            cached size = \(debayered.extent)
            """)
        
        await MainActor.run {
            self.updateItem(id: id) { item in
                item.debayeredFull = debayered
                print("Succesfully debayered and cached full res image")
            }
        }
    }
    

    
    
    func debayerInit(for items: [ImageItem]) async {
        let numContexts = ciContexts.count
        let viewModel = ThumbnailViewModel.shared

        // Split items evenly
        let groupedItems = items.enumerated().reduce(into: Array(repeating: [ImageItem](), count: numContexts)) { result, pair in
            let (index, item) = pair
            result[index % numContexts].append(item)
        }

        await withTaskGroup(of: Void.self) { group in
            for (index, groupItems) in groupedItems.enumerated() {
                let context = ciContexts[index]

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
                        
                        await MainActor.run {
                            self.updateItem(id: id) { item in
                                item.debayeredBuffer = buffer
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
    
    private func debayerHRBatchInit(for items: [ImageItem]) async {
        let numContexts = ciContexts.count
        let viewModel = ThumbnailViewModel.shared

        // Split items evenly
        let groupedItems = items.enumerated().reduce(into: Array(repeating: [ImageItem](), count: numContexts)) { result, pair in
            let (index, item) = pair
            result[index % numContexts].append(item)
        }

        await withTaskGroup(of: Void.self) { group in
            for (index, groupItems) in groupedItems.enumerated() {
                let context = ciContexts[index]
                
                group.addTask {
                    for item in groupItems {
                        let id = item.id
                        let url = item.url
                        
                        guard item.debayeredFullBuffer == nil else { continue }
                        
                        let node = DebayerFullNode(rawFileURL: url, scale: 1.0)
                        let debayered = node.apply()
                        
                        let buffer = await debayered.convertDebayeredToBuffer(context)
                        
                        await MainActor.run {
                            self.updateItem(id: id) { item in
                                item.debayeredFullBuffer = buffer
                            }
                            print("Succesfully assigned full res buffer")
                        }
                    }
                }
            }
        }
    }

    
    func processRawsV3(_ item: ImageItem, _ buffer: CVPixelBuffer, _ context: CIContext) async {
        
        let id = item.id
        let ciImage = CIImage(cvPixelBuffer: buffer)
        
        guard let finalImage = FilterPipeline.shared.applyPipelineV2Sync(id, self, ciImage, true) else {return}
        
        
        
        guard let thumb = await finalImage.convertThumbToCGImageBatch(context) else {
            return
        }
        
        await MainActor.run {
            
            let size = NSSize(width: thumb.width, height: thumb.height)
            let nsImage = NSImage(cgImage: thumb, size: size)
            
            self.updateItem(id: id) { item in
                item.processImage = finalImage
                item.thumbnailImage = nsImage
            }
        }
        
        item.toDisk(finalImage)
        
    }
    

	
}
