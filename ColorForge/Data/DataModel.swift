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
	static let shared = DataModel(pipeline: .shared)
	
	
	@Published var currentId: UUID?
    @Published var currentThumb: NSImage?
    @Published var currentPreview: NSImage?
	
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
    

	
	var selectedUrl: URL? {
		pipeline.currentURL
	}
	
	// Bindings
	var itemIndexMap: [UUID: Int] {
		Dictionary(uniqueKeysWithValues: items.enumerated().map { ($1.id, $0) })
	}
	
	public var bindingCache: [String: Any] = [:]
	public var cachedBindingId: UUID?
	
	@Published var processingComplete: Bool = false
    
    // MARK: - Load Images
    func loadImagesV2(from urls: [URL]) async {
        Task(priority: .userInitiated) {
            
            
            do {
                // Step 1: Create structs
                let newItems = try await createStructs(from: urls)
                
                // Step 2: Append to model
                await MainActor.run {
                    self.items.append(contentsOf: newItems)
                }
                
                await self.getMetaData(newItems) // scaling etc
                
                // Step 3: Launch thumbnails and raw processing in parallel
                await withTaskGroup(of: Void.self) { group in
                    
                    group.addTask(priority: .userInitiated) {  // HIGH PRIORITY
                        
//                        await self.extractThumbs(for: newItems)
                        await MainActor.run {
                            self.thumbsFullyLoaded = true
                            self.loading = false
                            ImageViewModel.shared.processingComplete = true
                        }
                        
                    }
                    
                    group.addTask(priority: .userInitiated) {
                        await self.debayerInit(for: newItems)
                    }
                }
                
                await MainActor.run {
                    ImageViewModel.shared.batchProcessComplete = true
                }
                
                await debayerHRBatchInit(for: newItems)
                
            } catch {
                print("Failed to load images: \(error)")
            }
        }
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


	
	// MARK: - Extract thumbnails
	func extractThumbs(for items: [ImageItem]) async {
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

			let previewImage = NSImage(cgImage: cgImage, size: .zero)

			await MainActor.run {
				self.updateItem(id: id) { item in
					item.thumbnailImage = previewImage
//					item.thumbLoaded = true
				}
			}
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
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        let viewWidth = screenSize.width
        let viewHeight = screenSize.height
        
        var scale: Float = 1.0
        
        if rotation == 6 || rotation == 8 {
            scale = Float(viewHeight) / Float(width)
        } else {
            scale = Float(viewHeight) / Float(height)
        }
        
        return scale * 0.7
    }
    
    
    func updateThumbAndCache(for items: [ImageItem]) async {
        let context = RenderingManager.shared.thumbnailContext
        let thumbScale: CGFloat = 0.3

        for item in items {
            let id = item.id
            let url = item.url
            guard let processed = item.processImage else { continue }
			
			print("\n\nUpdateThumbAndCache:\nProcessImage Extent: \(processed.extent)\n\n")

            // Full-size preview rendering
            guard let previewCgImage = context.createCGImage(processed, from: processed.extent) else {
                continue
            }

            let fullSize = processed.extent.size
            let previewImage = NSImage(cgImage: previewCgImage, size: fullSize)

            // Downscale the already-rendered previewImage to make the thumbnail
            let thumbSize = NSSize(width: fullSize.width * thumbScale, height: fullSize.height * thumbScale)
            let processedThumb = NSImage(size: thumbSize)
            processedThumb.lockFocus()
            previewImage.draw(in: NSRect(origin: .zero, size: thumbSize),
                              from: NSRect(origin: .zero, size: fullSize),
                              operation: .copy,
                              fraction: 1.0)
            processedThumb.unlockFocus()

            // Cache CIImage version
            let cachedResult = processed.insertingIntermediate(cache: true)

            await MainActor.run {
                self.updateItem(id: id) { item in
                    item.thumbnailImage = processedThumb
                    item.previewImage = previewImage
//                    item.processImage = cachedResult
                }
            }
        }
		
		await MainActor.run {
			ImageViewModel.shared.processingComplete = true
			print("processingComplete marked true")
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
    
    private lazy var rawProcessingQueue = RawProcessingQueue(dataModel: self)
    
    func throttledProcessRawsV2(for item: ImageItem) async -> CGImage? {
        await rawProcessingQueue.enqueue(item)
    }
	
    actor RawProcessingQueue {
        private var queue: [(item: ImageItem, continuation: CheckedContinuation<CGImage?, Never>)] = []
        private var isProcessing = false
        private unowned let dataModel: DataModel
        
        init(dataModel: DataModel) {
            self.dataModel = dataModel
        }
        
        func enqueue(_ item: ImageItem) async -> CGImage? {
            return await withCheckedContinuation { continuation in
                queue.append((item, continuation))
                processNextIfNeeded()
            }
        }
        
        private func processNextIfNeeded() {
            guard !isProcessing, !queue.isEmpty else { return }
            isProcessing = true
            
            let (item, continuation) = queue.removeFirst()
            
            Task {
                let start = Date()
                let result = await dataModel.processRawsV2(for: item)
                let duration = Date().timeIntervalSince(start)

                print("⏱️ processRawsV2 took \(String(format: "%.3f", duration)) seconds for \(item.url.lastPathComponent)")
                
                continuation.resume(returning: result)
                
                try? await Task.sleep(nanoseconds: 150_000_000)
                
                self.finishAndContinue()
            }
        }
        
        private func finishAndContinue() {
            isProcessing = false
            processNextIfNeeded()
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
                        
                        await self.processRawsV3(item, buffer, context)

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
    
//    func debayerInit(for items: [ImageItem]) async {
//        // Split items evenly into 4 groups
//        let groupedItems = items.enumerated().reduce(into: Array(repeating: [ImageItem](), count: 7)) { result, pair in
//            let (index, item) = pair
//            result[index % 7].append(item)
//        }
//        
//        let maxCores = ProcessInfo.processInfo.processorCount
//        let numContexts = max(1, min(maxCores - 1, items.count))  // Never go above processorCount - 1
//        
//        // Now create the contexts
//        
//        // Main display context
//        let options: [CIContextOption: Any] = [
//            .workingColorSpace: NSNull(),
//            .outputColorSpace: NSNull(),
//            .name: "cacheContext",
//            .outputPremultiplied: false,
//            .useSoftwareRenderer: false,
//            .workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
//            .allowLowPower: false, // Use high-performance mode
//            .highQualityDownsample: false, // Enable high-quality downsampling
//            .priorityRequestLow: false, // Push to background
//            .cacheIntermediates: false, // Cache intermediate results for performance
//            .memoryTarget: 4_294_967_296 // 4gb
//        ]
//        
//        
//        
//        print("Number of contexts to use: \(numContexts)")
//
//        await withTaskGroup(of: Void.self) { group in
//            for (index, groupItems) in groupedItems.enumerated() {
//                group.addTask {
//                    let context: CIContext
//                    switch index {
//                    case 0: context = BatchRenderer.shared.context1
//                    case 1: context = BatchRenderer.shared.context2
//                    case 2: context = BatchRenderer.shared.context3
//                    case 3: context = BatchRenderer.shared.context4
//                    case 4: context = BatchRenderer.shared.context5
//                    case 5: context = BatchRenderer.shared.context6
//                    case 6: context = BatchRenderer.shared.context7
////                    case 7: context = BatchRenderer.shared.context8
//                    default: return
//                    }
//
//                    for item in groupItems {
//                        let id = item.id
//                        let url = item.url
//
//                        // 1. Debayer
//                        let debayerNode = DebayerNode(rawFileURL: url, scale: item.uiScale)
//                        let (debayered, xySIMD, baseline) = debayerNode.apply()
//
//                        // 2. Temp/tint from xy
//                        guard let (temp, tint) = debayered.calculateTempAndTintFromXY(xySIMD.x, xySIMD.y) else {
//                            continue
//                        }
//                        
//                        print("Using context \(index) for item \(item.url.lastPathComponent)")
//
//                        // 3. Convert to buffer using assigned context
//                        guard let buffer = await debayered.convertDebayeredToBuffer(context) else {
//                            continue
//                        }
//
//                        // 4. Apply to model
//                        await MainActor.run {
//                            self.updateItem(id: id) { item in
//                                item.debayeredBuffer = buffer
//                                item.debayeredInit = debayered
//                                item.xyChromaticity = CGPoint(x: CGFloat(xySIMD.x), y: CGFloat(xySIMD.y))
//                                item.temp = temp
//                                item.tint = tint
//                                item.initTemp = temp
//                                item.initTint = tint
//                                item.baselineExposure = baseline
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//    
	
    func processRawsV2(for item: ImageItem) async -> CGImage? {
        let id = item.id

//        guard let debayered = item.debayeredInit else {return nil}
        guard let buffer = item.debayeredBuffer else {return nil}
        
//        guard let buffer = await debayered.convertDebayeredToBuffer() else {return nil}
        
        var result = CIImage(cvPixelBuffer: buffer)
            .P3ToAWG()
            .Lin2LogC()
        
        result = ApplyAdobeCameraRawCurveNode(
            convertToNeg: item.convertToNeg
        ).apply(to: result)
        
        let finalImage = result

        guard let thumb = await finalImage.convertThumbToCGImage() else {
            return nil
        }

        await MainActor.run {
            self.updateItem(id: id) { item in
                item.processImage = finalImage
                item.thumbLoaded = true
//                item.debayeredBuffer = buffer
            }
        }
        
        return thumb
    }
    
    
    func processRawsV3(_ item: ImageItem, _ buffer: CVPixelBuffer, _ context: CIContext) async {
        
        let id = item.id
        
        var result = CIImage(cvPixelBuffer: buffer)
            .P3ToAWG()
            .Lin2LogC()
        
        result = ApplyAdobeCameraRawCurveNode(
            convertToNeg: item.convertToNeg
        ).apply(to: result)
        
        let finalImage = result

        
        guard let thumb = await finalImage.convertThumbToCGImageBatch(context) else {
            return
        }
        
        await MainActor.run {
            
            let size = NSSize(width: thumb.width, height: thumb.height)
            let nsImage = NSImage(cgImage: thumb, size: size)
            
            self.updateItem(id: id) { item in
                item.processImage = finalImage
                item.thumbLoaded = true
                item.thumbnailImage = nsImage
            }
        }
        
    }
    

    
                
                
//        
//        let id = item.id
//
//        guard let buffer = item.debayeredBuffer else {return nil}
//        
//        
//        var result = CIImage(cvPixelBuffer: buffer)
//            .P3ToAWG()
//            .Lin2LogC()
//        
//        result = ApplyAdobeCameraRawCurveNode(
//            convertToNeg: item.convertToNeg
//        ).apply(to: result)
//        
//        let finalImage = result
//
//        guard let thumb = await finalImage.convertThumbToCGImage() else {
//            return nil
//        }
//
//        await MainActor.run {
//            self.updateItem(id: id) { item in
//                item.processImage = finalImage
//                item.thumbLoaded = true
//            }
//        }
//        
//        return thumb
    
    
    


	
	
	// Unwrap async
	private func unwrapAndReturnImages( _ item: ImageItem) async -> CIImage? {
		guard let displayImage = item.debayeredInit else { return nil }
		guard let highRes = item.debayeredFull else { return nil }
		
		let viewModel = ImageViewModel.shared
		let isZoomed = viewModel.isZoomed
		let rect = viewModel.zoomRect
		
		if isZoomed, rect.width > 0, rect.height > 0, highRes.extent.contains(rect) {
			let zoomed = highRes.cropped(to: rect)
			let translated = zoomed.transformed(by: .init(
				translationX: -rect.origin.x,
				y: -rect.origin.y
			))
			return translated
		} else {
			return displayImage
		}
	}


	
}
