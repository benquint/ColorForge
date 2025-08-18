//
//  DataModel.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import Foundation
import CoreFoundation
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
                        
                        // Load cached JPEG preview (as NSImage) - This never seems to be used?
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
                
                // Step 3: Combine everything locally
                let allItems = restoredItems + newItems
                
                // Capture restoredItems as let for concurrency safety
                let capturedRestoredItems = restoredItems
                
                // Step 4: Append to model and update restored items to trigger UI
                await MainActor.run {
                    self.items.append(contentsOf: allItems)
                    
                    
                    // Force UI updates for restored items with cached images
                    for restoredItem in capturedRestoredItems {
                        if restoredItem.previewImage != nil || restoredItem.thumbnailImage != nil {
                            self.updateItem(id: restoredItem.id) { item in
                                // The item is already correct, this just triggers UI refresh
                                item.thumbnailImage = restoredItem.thumbnailImage
                                item.previewImage = restoredItem.previewImage
                            }
                        }
                    }
                }
                
                // Step 5: Extract metadata and get camera support info
                let cameraSupportInfo = await self.getMetaData(allItems)
                
                await MainActor.run {
                    self.thumbsFullyLoaded = true
                    self.loading = false
                    ImageViewModel.shared.processingComplete = true
                }
                
                // Custom Demosaic - only process supported cameras
                await self.getDataForImages(allItems, supportInfo: cameraSupportInfo, restoredItems: restoredItems)
                
                // Fetch debayered init etc
                await self.debayerInit(for: allItems)
                
                await MainActor.run {
                    ImageViewModel.shared.processingFullyComplete = true
                }
                
                await updateManifest(allItems)
                
            } catch {
                print("Failed to load images: \(error)")
            }
        }
    }
    
    
    // MARK: - CPP Demosaic
    
    
    
    
    // Swift function to extract raw image data from URL
    func extractRawImageData(from url: URL) throws -> RawImageData {
        // Call the C++ bridge function
        guard let cfDict = ExtractRawImageData(url as CFURL) else {
            throw RawImageError.extractionFailed("Failed to extract raw image data from URL")
        }
        
        // Convert CFDictionary to Swift Dictionary for easier handling
        let dict = cfDict as NSDictionary
        
        // Helper function to safely extract values from the dictionary
        func getValue<T>(_ key: String, as type: T.Type) throws -> T {
            guard let value = dict[key] as? T else {
                throw RawImageError.missingParameter("Missing or invalid parameter: \(key)")
            }
            return value
        }
        
        // Extract all parameters
        let width = try getValue("width", as: UInt32.self)
        let height = try getValue("height", as: UInt32.self)
        let pitch = try getValue("pitch", as: UInt32.self)
        let cfaPattern = try getValue("cfaPattern", as: UInt32.self)
        let orientation = try getValue("orientation", as: Int.self)
        let rawPixels = try getValue("rawPixels", as: Data.self)
        
        let blackLevelRed = try getValue("blackLevelRed", as: Float.self)
        let blackLevelGreen = try getValue("blackLevelGreen", as: Float.self)
        let blackLevelBlue = try getValue("blackLevelBlue", as: Float.self)
        let whiteLevel = try getValue("whiteLevel", as: Float.self)
        let rMul = try getValue("rMul", as: Float.self)
        let bMul = try getValue("bMul", as: Float.self)
        
        // Extract chromaticity coordinates
        let chromaticity_x = try getValue("chromaticity_x", as: Double.self)
        let chromaticity_y = try getValue("chromaticity_y", as: Double.self)
        
        // Extract the color matrix array
        guard let matrixArray = dict["camToAWG3"] as? [Float], matrixArray.count == 9 else {
            throw RawImageError.missingParameter("Missing or invalid color matrix")
        }
        
        return RawImageData(
            rawPixels: rawPixels,
            width: width,
            height: height,
            pitch: pitch,
            cfaPattern: cfaPattern,
            orientation: orientation,
            blackLevelRed: blackLevelRed,
            blackLevelGreen: blackLevelGreen,
            blackLevelBlue: blackLevelBlue,
            whiteLevel: whiteLevel,
            camToAWG3: matrixArray,
            rMul: rMul,
            bMul: bMul,
            chromaticity_x: chromaticity_x,
            chromaticity_y: chromaticity_y
        )
    }
    
    // Error types for better error handling
    enum RawImageError: Error, LocalizedError {
        case extractionFailed(String)
        case missingParameter(String)
        case invalidData(String)
        
        var errorDescription: String? {
            switch self {
            case .extractionFailed(let message):
                return "Raw image extraction failed: \(message)"
            case .missingParameter(let message):
                return "Missing parameter: \(message)"
            case .invalidData(let message):
                return "Invalid data: \(message)"
            }
        }
    }
    
    // Example usage function
    func getData(at url: URL) async -> RawImageData? {
        do {
            let rawData = try extractRawImageData(from: url)
            print("\n\n")
            print("Successfully extracted raw image data for \(url.lastPathComponent):\n")
            print("  Dimensions: \(rawData.width) x \(rawData.height)")
            print("  CFA Pattern: \(rawData.cfaPatternName) (\(rawData.cfaPattern))")
            print("  Black Levels - R: \(rawData.blackLevelRed), G: \(rawData.blackLevelGreen), B: \(rawData.blackLevelBlue)")
            print("  White Level: \(rawData.whiteLevel)")
            print("  Color Multipliers - R: \(rawData.rMul), B: \(rawData.bMul)")
            print("  Raw pixel data size: \(rawData.rawPixels.count) bytes")
            print("  Color Matrix:")
            let matrix = rawData.colorMatrix
            for row in matrix {
                print("    \(row.map { String(format: "%.4f", $0) }.joined(separator: ", "))")
            }
            print("\n\n")
            
            return rawData
            
        } catch {
            print("Error processing raw image: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    func demosaicGPU(_ rawData: RawImageData) async -> CVPixelBuffer? {
        
        do {
            // Process with Metal
            guard let metalProcessor = MetalDemosaicProcessor.shared else {
                print("Metal processor not available")
                return nil
            }
            
            let processedBuffer = try metalProcessor.processDemosaic(rawData: rawData, coreSize: 16)
            print("Successfully processed with Metal")
            
            //			metalProcessor.createDebugCIImage(from: rawData)
            //
            return processedBuffer
        } catch {
            print ("Metal processing failed: \(error)")
            return nil
        }
    }
    
    
    func getDataForImages(_ items: [ImageItem], supportInfo: [CameraSupportInfo], restoredItems: [ImageItem] = []) async {
        
        // Create a lookup dictionary for restored items
        let restoredItemsDict = Dictionary(uniqueKeysWithValues: restoredItems.map { ($0.id, $0) })
        
        // PHASE 1: Collect all raw data sequentially (LibRaw thread safety)
        var imageDataPairs: [(ImageItem, RawImageData)] = []
        
        for item in items {
            // Find the support info for this item
            guard let support = supportInfo.first(where: { $0.id == item.id }) else {
                print("No support info found for: \(item.url.lastPathComponent)")
                continue
            }
            
            // Check if camera is supported
            guard support.isSupported else {
                print("Camera isn't supported by LibRaw, skipping: \(item.url.lastPathComponent)")
                continue
            }
            
            try? await modifyRAWModel(item.url, "GFX100S")
            try? await Task.sleep(nanoseconds: 50_000_000)
            
            guard let data = await getData(at: item.url) else {
                print("Failed to extract data for \(item.url.lastPathComponent)")
                continue
            }
            
            guard data.cfaPattern == 0 else {
                print("CFA pattern for \(item.url.lastPathComponent) is not RGGB, skipping GPU Demosaic")
                continue
            }
            
            imageDataPairs.append((item, data))
        }
        
        // PHASE 2: Split into 3 groups and process concurrently
        let groupSize = max(1, imageDataPairs.count / 3)
        let groups = stride(from: 0, to: imageDataPairs.count, by: groupSize).map {
           Array(imageDataPairs[$0..<Swift.min($0 + groupSize, imageDataPairs.count)])
        }
        
        
        await withTaskGroup(of: Void.self) { taskGroup in
            var index = 1
            
            for (groupIndex, group) in groups.enumerated() {
                taskGroup.addTask {
                    await self.processImageGroup(group, groupIndex: groupIndex + 1, restoredItemsDict: restoredItemsDict)
                }
                print("""
                    Processing group \(index)
                    """)
                index += 1
            }
        }
    }

    private func processImageGroup(_ imageDataPairs: [(ImageItem, RawImageData)],
                                  groupIndex: Int,
                                  restoredItemsDict: [UUID: ImageItem]) async {
        
        for (item, data) in imageDataPairs {
            let chromX = Float(data.chromaticity_x)
            let chromY = Float(data.chromaticity_y)
            
            guard let fullBuffer = await demosaicGPU(data) else {
                print("Failed to Demosaic \(item.url.lastPathComponent)")
                continue
            }
            
            let fullRes = CIImage(cvPixelBuffer: fullBuffer)
            var scaled = fullRes.transformed(by: CGAffineTransform(scaleX: CGFloat(item.uiScale), y: CGFloat(item.uiScale)))
            
            let orientation = data.orientation
            switch orientation {
            case 0:
                scaled = scaled.oriented(.up)
            case 3:
                scaled = scaled.oriented(.down)
            case 5:
                scaled = scaled.oriented(.left)
            case 6:
                scaled = scaled.oriented(.right)
            default:
                scaled = scaled.oriented(.up)
            }
            
            scaled = scaled.LogC2Lin()
            
            guard let scaledBuffer = scaled.convertDebayeredToBufferSync() else {
                print("Scaled buffer creation failed for \(item.url.lastPathComponent)")
                continue
            }
            
            let smlBuffer = scaledBuffer
            
            let ciImage = CIImage(cvPixelBuffer: smlBuffer)
            
            // Only update if no temp / tint found aka defaults are found
            if item.temp == 5500.0 && item.tint == 0.0 {
                guard let (temp, tint) = ciImage.calculateTempAndTintFromXY(chromX, chromY) else {
                    print("Temp and Tint extraction failed for \(item.url.lastPathComponent)")
                    continue
                }
                
//                await MainActor.run {
                    self.updateItem(id: item.id) { item in
                        item.temp = temp
                        item.tint = tint
                        item.initTemp = temp
                        item.initTint = tint
                    }
//                }
            }
            
            // Cache by UUID only
            PixelBufferCache.shared.set(smlBuffer, for: item.id)
            
//            await MainActor.run {
                self.updateItem(id: item.id) { item in
                    item.debayeredInit = ciImage
                    item.baselineExposure = -4.0
                }
//            }
            
            guard let processedInit = pipeline.applyPipelineV2Sync(item.id, self, ciImage, true) else {
                print("Pipeline failed for \(item.url.lastPathComponent)")
                continue
            }
            
            let evAdjustment = await calculateBaselineEV(item, processedInit)
            
//            await MainActor.run {
                self.updateItem(id: item.id) { item in
                    item.baselineExposure += evAdjustment
//                }
                
//                if let processedBal = pipeline.applyPipelineV2Sync(item.id, self, ciImage, true) {
//                    
//                    // Check if we have cached images for this item
//                    if let restoredItem = restoredItemsDict[item.id],
//                       let cachedPreview = restoredItem.previewImage,
//                       let cachedThumbnail = restoredItem.thumbnailImage {
//                        
//                        // Use cached images
//                        self.updateItem(id: item.id) { item in
//                            item.thumbnailImage = cachedThumbnail
//                            item.previewImage = cachedPreview
//                        }
//                        
//                    } else {
//                        // Generate new preview/thumbnail
//                        let previewCGImage = processedBal.convertPreviewToCGImageSync()
//                        let thumbnailCGImage = processedBal.convertThumbToCGImageSync()
//                        
//                        self.updateItem(id: item.id) { item in
//                            item.thumbnailImage = thumbnailCGImage
//                            item.previewImage = previewCGImage
//                        }
//                    }
//                }
            }
  
            if let processedBal = pipeline.applyPipelineV2Sync(item.id, self, ciImage, true) {
                
                // Check if we have cached images for this item
                if let restoredItem = restoredItemsDict[item.id],
                   let cachedPreview = restoredItem.previewImage,
                   let cachedThumbnail = restoredItem.thumbnailImage {
                    
                    // Use cached images
//                    await MainActor.run {
                        self.updateItem(id: item.id) { item in
                            item.thumbnailImage = cachedThumbnail
                            item.previewImage = cachedPreview
                        }
//                    }
                    
                } else {
                    // Generate new preview/thumbnail
                    let previewCGImage = processedBal.convertPreviewToCGImageSync()
                    let thumbnailCGImage = processedBal.convertThumbToCGImageSync()
                    
//                    await MainActor.run {
                        self.updateItem(id: item.id) { item in
                            item.thumbnailImage = thumbnailCGImage
                            item.previewImage = previewCGImage
                        }
//                    }
                }
            }
            
            
            
            
            try? await modifyRAWModel(item.url, "GFX100S II")
            
            await MainActor.run {
                // Empty MainActor call to flush pending updates
            }
        }
    }


    // MARK: - Update manifest
    
    
    private func updateManifest(_ items: [ImageItem]) async {
        for item in items {
            item.toDisk()
        }
        
    }
    
    
    
   // MARK: - Modify Model
    
    func modifyRAWModel(_ fileURL: URL, _ newModel: String) async throws {
        guard let scriptPath = Bundle.main.path(forResource: "exiftool", ofType: nil),
              let resourcePath = Bundle.main.resourcePath else {
            throw NSError(domain: "ExifToolNotFound", code: -1)
        }
        
        let libPath = "\(resourcePath)/lib"
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/perl")
        process.arguments = ["-I\(libPath)", scriptPath, "-overwrite_original", "-Model=\(newModel)", fileURL.path]
        
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        let output = String(data: outputData, encoding: .utf8) ?? ""
        let error = String(data: errorData, encoding: .utf8) ?? ""
        
        print("🔧 Process exit code: \(process.terminationStatus)")
        if !output.isEmpty { print("🔧 Output: \(output)") }
        if !error.isEmpty { print("🔧 Error: \(error)") }
        
        if process.terminationStatus != 0 {
            throw NSError(domain: "ExifToolError", code: Int(process.terminationStatus))
        }
        
        print("✅ Model successfully changed to: \(newModel)")
    }
    
    
    // MARK: - Baseline EV
    
    private func calculateBaselineEV(_ item: ImageItem, _ debayered: CIImage) async -> Float {
        
        // ************ Get thumbnail ************ //
        
        
        let url = item.url
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 256,
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldCacheImmediately: false
        ]
        
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            print("❌ Failed to extract thumbnail for \(url)")
            return 0.0
        }
        
        let embedded = CIImage(cgImage: cgImage)
        
        
        // ************ Averages ************ //
        
        
        let (dR, dG, dB) = debayered.findAverage()
        let (eR, eG, eB) = embedded.findAverage()
        
        
        let debayeredAvg = (dR + dG + dB) / 3.0
        let embedAvg = (eR + eG + eB) / 3.0
        
        
        // Calculate EV adjustment needed to make debayered match embedded
        let evAdjustment = log2(embedAvg / debayeredAvg)
        
        print("Debayered avg: \(debayeredAvg)")
        print("Embedded avg: \(embedAvg)")
        print("EV adjustment needed: \(String(format: "%.2f", evAdjustment)) EV")
        
        if evAdjustment > 0 {
            print("Need to brighten debayered by \(String(format: "%.2f", evAdjustment)) EV")
        } else if evAdjustment < 0 {
            print("Need to darken debayered by \(String(format: "%.2f", abs(evAdjustment))) EV")
        } else {
            print("Debayered and embedded are the same brightness")
        }
        
        return Float(evAdjustment)
    }
    
    
    
    
    // MARK: - Extract thumbs
    
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
                
                self.updateItem(id: id) {item in
                    item.thumbnailImage = cgImage
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
    
    func loadPreviewImage(for imageURL: URL) -> CGImage? {
        let manifest = AppDataManager.shared.manifest
        
        guard let match = manifest.images.first(where: { $0.imageURL == imageURL }),
              let previewURL = match.previewURL else {
            print("""
                
                Failed to find cached jpeg for \(imageURL.lastPathComponent)
                
                """)
            return nil
        }
        
        guard let source = CGImageSourceCreateWithURL(previewURL as CFURL, nil) else {
            return nil
        }
        
        // If you just want the full stored image:
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
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
    
    
    struct CameraSupportInfo {
        let id: UUID
        let isSupported: Bool
        let make: String
        let model: String
    }
    
    
    
    private func getMetaData(_ items: [ImageItem]) async -> [CameraSupportInfo] {
        let libRawSupported = LibRawSupported()
        var supportInfo: [CameraSupportInfo] = []
        
        for item in items {
            let id = item.id
            let url = item.url
            
            print("🔍 Processing metadata for: \(url.lastPathComponent)")
            
            guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
                print("❌ Failed to create image source or get metadata for: \(url.lastPathComponent)")
                // Add unsupported entry for failed metadata
                supportInfo.append(CameraSupportInfo(id: id, isSupported: false, make: "Unknown", model: "Unknown"))
                continue
            }
            
            let width = metadata[kCGImagePropertyPixelWidth] as? Int ?? 0
            let height = metadata[kCGImagePropertyPixelHeight] as? Int ?? 0
            let orientation = metadata[kCGImagePropertyOrientation] as? Int ?? 1
            
            let exif = metadata[kCGImagePropertyExifDictionary] as? [CFString: Any]
            let gps = metadata[kCGImagePropertyGPSDictionary] as? [CFString: Any]
            let iptc = metadata[kCGImagePropertyIPTCDictionary] as? [CFString: Any]
            let tiff = metadata[kCGImagePropertyTIFFDictionary] as? [CFString: Any]
            
            // Extract camera information
            let cameraMake = tiff?[kCGImagePropertyTIFFMake] as? String ?? "Unknown"
            let cameraModel = tiff?[kCGImagePropertyTIFFModel] as? String ?? "Unknown"
            
            // Debug TIFF dictionary
            if let tiff = tiff {
                print("📷 Found TIFF data for \(url.lastPathComponent): Make=\(cameraMake), Model=\(cameraModel)")
            } else {
                print("❌ No TIFF dictionary found for: \(url.lastPathComponent)")
            }
            
            let scale = await calculateScale(width: width, height: height, rotation: orientation)
            print("🔍 Scale for \(url.lastPathComponent): \(scale) (w: \(width), h: \(height), rot: \(orientation))")
            
            // Check if camera is supported by LibRaw
            let isSupported = libRawSupported.isCameraSupported(make: cameraMake, model: cameraModel)
            
            if isSupported {
                print("✅ Camera \(cameraMake) \(cameraModel) is supported by LibRaw")
            } else {
                print("❌ Camera \(cameraMake) \(cameraModel) is NOT supported by LibRaw")
            }
            
            // Add support info
            supportInfo.append(CameraSupportInfo(id: id, isSupported: isSupported, make: cameraMake, model: cameraModel))
            
            // Update the main items array with metadata
            await MainActor.run {
                self.updateItem(id: id) { item in
                    item.exifDict = exif
                    item.gpsDict = gps
                    item.iptcDict = iptc
                    item.tiffDict = tiff
                    item.nativeWidth = width
                    item.nativeHeight = height
                    item.nativeRotation = orientation
                    item.uiScale = scale
                }
            }
            
            print("✅ Metadata updated for: \(url.lastPathComponent)")
        }
        
        return supportInfo
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
    
    
    // Somewhere central (DataModel/Singletons)
    let pbCache = PixelBufferCache.shared
    
    // Gets every images debayered init and temp / tint set so we can load even if processing isnt complete
    func debayerInit(for items: [ImageItem]) async {
        
        let numContexts = ciContexts.count
        
        let itemsToProcess = items.filter { item in
            return PixelBufferCache.shared.get(item.id) == nil && item.debayeredInit == nil
        }
        
        // If no items need processing, return early
        guard !itemsToProcess.isEmpty else {
            print("All items already have cached buffers or debayeredInit, skipping processing")
            return
        }
        
        print("Processing \(itemsToProcess.count) items (skipped \(items.count - itemsToProcess.count) cached/processed items)")
        
        // Split filtered items evenly
        let groupedItems = itemsToProcess.enumerated().reduce(into: Array(repeating: [ImageItem](), count: numContexts)) { result, pair in
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
                        
                        // Double-check cache before processing (in case another task cached it)
                        if PixelBufferCache.shared.get(id) != nil {
                            print("\nNo cached buffer found for \(item.url.lastPathComponent)\n")
                            continue
                        }
                        
                        let debayerNode = DebayerNode(rawFileURL: url, scale: item.uiScale)
                        let (debayered, xySIMD, baseline) = debayerNode.apply()
                        
                        guard let (temp, tint) = debayered.calculateTempAndTintFromXY(xySIMD.x, xySIMD.y) else {
                            continue
                        }
                        
                        let debayeredAWG = debayered.P3ToAWG()
                        
                        await MainActor.run {
                            self.updateItem(id: id) { item in
                                item.debayeredInit = debayeredAWG
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
    
    func cacheInitialBuffers(for items: [ImageItem]) async {
        // Only process the first 30 items
        let limitedItems = Array(items.prefix(30))
        
        let numContexts = ciContexts.count
        
        // Split limitedItems evenly
        let groupedItems = limitedItems.enumerated().reduce(into: Array(repeating: [ImageItem](), count: numContexts)) { result, pair in
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
                        
                        // Cache by UUID only
                        PixelBufferCache.shared.set(buffer, for: item.id)
                        
                        await MainActor.run {
                            self.updateItem(id: id) { item in
                                item.debayeredInit = debayered
                                item.xyChromaticity = CGPoint(x: CGFloat(xySIMD.x), y: CGFloat(xySIMD.y))
                                item.temp = temp
                                item.tint = tint
                                item.initTemp = temp
                                item.initTint = tint
                                item.baselineExposure = baseline
                            }
                        }
                        
                        print("\nBuffer complete for \(item.url.lastPathComponent)\n")
                        
                        await self.processRawsV3(item, buffer, context)
                        
                        await MainActor.run {
                            print("\nProcessing complete for \(item.url.lastPathComponent)\n")
                        }
                    }
                }
            }
        }
    }
    
    //    func debayerInit(for items: [ImageItem]) async {
    //        let numContexts = ciContexts.count
    //
    //        // Split items evenly
    //        let groupedItems = items.enumerated().reduce(into: Array(repeating: [ImageItem](), count: numContexts)) { result, pair in
    //            let (index, item) = pair
    //            result[index % numContexts].append(item)
    //        }
    //
    //        await withTaskGroup(of: Void.self) { group in
    //            for (index, groupItems) in groupedItems.enumerated() {
    //                let context = ciContexts[index]
    //
    //                group.addTask {
    //                    for item in groupItems {
    //                        let id = item.id
    //                        let url = item.url
    //
    //                        let debayerNode = DebayerNode(rawFileURL: url, scale: item.uiScale)
    //                        let (debayered, xySIMD, baseline) = debayerNode.apply()
    //
    //                        guard let (temp, tint) = debayered.calculateTempAndTintFromXY(xySIMD.x, xySIMD.y) else {
    //                            continue
    //                        }
    //
    //
    //                        print("Using context number \(index)")
    //
    //
    //						guard let buffer = await debayered.convertDebayeredToBuffer(context) else {
    //							continue
    //						}
    //
    //						// cache key: id + role
    //						let key = "\(id.uuidString)#preview"
    //						PixelBufferCache.shared.set(buffer, for: item.id)
    //
    //
    //
    //                        await MainActor.run {
    //                            self.updateItem(id: id) { item in
    ////                                item.debayeredBuffer = buffer
    //                                item.debayeredInit = debayered
    //                                item.xyChromaticity = CGPoint(x: CGFloat(xySIMD.x), y: CGFloat(xySIMD.y))
    //                                item.temp = temp
    //                                item.tint = tint
    //                                item.initTemp = temp
    //                                item.initTint = tint
    //                                item.baselineExposure = baseline
    //                            }
    //                        }
    //
    //
    //
    //
    //
    //                        print("""
    //
    //                            Buffer complete for \(item.url.lastPathComponent)
    //
    //                            """)
    //
    //                        await self.processRawsV3(item, buffer, context)
    //
    //                        await MainActor.run {
    //                            print("""
    //
    //                                Processing complete for \(item.url.lastPathComponent)
    //                                """)
    //                        }
    //                    }
    //                }
    //            }
    //        }
    //    }
    
    func processRawsV3(_ item: ImageItem, _ buffer: CVPixelBuffer, _ context: CIContext) async {
        
        let id = item.id
        let ciImage = CIImage(cvPixelBuffer: buffer)
        
        guard let finalImage = FilterPipeline.shared.applyPipelineV2Sync(id, self, ciImage, true) else {return}
        
        
        
        guard let thumb = await finalImage.convertThumbToCGImageBatch(context) else {
            return
        }
        
        await MainActor.run {
            
            self.updateItem(id: id) { item in
                item.processImage = finalImage
                item.thumbnailImage = thumb
            }
        }
        
        item.toDisk(finalImage)
        
    }
    
    
    func processRawsV3CiImage(_ item: ImageItem, _ image: CIImage, _ context: CIContext) async {
        
        let id = item.id
        let ciImage = image
        
        guard let finalImage = FilterPipeline.shared.applyPipelineV2Sync(id, self, ciImage, true) else {return}
        
        
        
        guard let thumb = await finalImage.convertThumbToCGImageBatch(context) else {
            return
        }
        
        await MainActor.run {
            
            self.updateItem(id: id) { item in
                item.processImage = finalImage
                item.thumbnailImage = thumb
            }
        }
        
        item.toDisk(finalImage)
        
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
    
    
    
    
    
}
