////
////  RawImage.swift
////  ColorForge
////
////  Created by Ben Quinton on 22/05/2025.
////
//
//
//import Foundation
//import SwiftUI
//
//
//// MARK: - Enum for Film Stocks
//public enum SelectedStock: String, CaseIterable {
//    case porta160 = "Portra 160 N/A"
//    case gold200 = "Gold 200"
//    case porta400 = "Portra 400"
//    case porta4001 = "Portra 400+1"
//    case porta4002 = "Portra 400+2"
//    case tMax = "Tmax"
//    case triX = "TriX N/A"
//}
//
//
//// MARK: - Main struct for image data
//struct RawImage: Identifiable {
//    
//    // MARK: - Identification
//    let id = UUID()
//    let imageUrl: URL // URL of file being processed, either raw or tiff etc
//    let name: String?
//    let dateCreated: Date?
//    let importFolderUrl: URL? // Location of import folder
//    
//    
//    // MARK: - Image objects
//    var displayImage: NSImage? = nil // Image displayed in view, may switch to MTKView to get rid of this and the processing
//    var pipelineImage: CIImage? = nil // Scaled CIImage for main pipeline processing
//    var pipelineImageHR: CIImage? = nil // Full resolution image for output processing
//    
//
//    // MARK: - Scale Attributes
//    var pipelineScale: Float? = 0.25
//    var rotation: Int = 0 // 0 for landscape 1 for 90 degrees, 2 for 180 degrees, 3 for 270
//    var pipelineExtent: CGRect = .zero
//    var pipelineExtentHR: CGRect = .zero // Full image size
//    
//    
//    // MARK: - Save attributes
//    
//    // Sizing
//    var exportRotation: Int = 0
//    var exportScale: Float = 1.0
//    var exportWidth: Int = 0
//    var exportHeight: Int = 0
//    var scaleByPercent: Bool = false
//    var scaleByLongEdge: Bool = false
//    var scaleByShortEdge: Bool = false
//    
//    // File attributes
//    var exportBitDepth: Int = 16
//    var exportColorSpace: String = "sRGB"
//    var exportFileType: String = "tiff"
//    var exportFileName: String = ""
//    var exportPrefix1: String = ""
//    var exportPrefix2: String = ""
//    var exportPrefix3: String = ""
//    var exportPrefix4: String = ""
//    var exportSuffix1: String = ""
//    var exportSuffix2: String = ""
//    var exportSuffix3: String = ""
//    var exportSuffix4: String = ""
//    var metaData: [String: Any] = [:] // Flexible storage for metadata
//    
//    
//    // MARK: - Raw Settings:
//    
//    // Temp / Tint
//    var rawTemp: Float = 5500.0
//    var lastRawTemp: Float = 5500.0
//    var rawTint: Float = 0.0
//    var lastRawTint: Float = 0.0
//    
//    var InitrawTemp: Float = 5500.0
//    var InitrawTint: Float = 0.0
//    
//    // Basic raw adjustments
//    var rawExposure: Float = 0.0
//    var lastRawExposure: Float = 0.0
//    
//    var rawContrast: Float = 0.0
//    var lastRawContrast: Float = 0.0
//    
//    var rawSaturation: Float = 0.0
//    var lastRawSaturation: Float = 0.0
//    
//    
//    // HDR
//    var hdrWhite: Float = 0.0
//    var lastHdrWhite: Float = 0.0
//
//    var hdrHighlight: Float = 0.0
//    var lastHdrHighlight: Float = 0.0
//
//    var hdrShadow: Float = 0.0
//    var lastHdrShadow: Float = 0.0
//
//    var hdrBlack: Float = 0.0
//    var lastHdrBlack: Float = 0.0
//
//    // HSD
//    var rHue: Float = 0.0
//    var lastRHue: Float = 0.0
//
//    var gHue: Float = 0.0
//    var lastGHue: Float = 0.0
//
//    var bHue: Float = 0.0
//    var lastBHue: Float = 0.0
//
//    var cHue: Float = 0.0
//    var lastCHue: Float = 0.0
//
//    var mHue: Float = 0.0
//    var lastMHue: Float = 0.0
//
//    var yHue: Float = 0.0
//    var lastYHue: Float = 0.0
//
//    var rSat: Float = 0.0
//    var lastRSat: Float = 0.0
//
//    var gSat: Float = 0.0
//    var lastGSat: Float = 0.0
//
//    var bSat: Float = 0.0
//    var lastBSat: Float = 0.0
//
//    var cSat: Float = 0.0
//    var lastCSat: Float = 0.0
//
//    var mSat: Float = 0.0
//    var lastMSat: Float = 0.0
//
//    var ySat: Float = 0.0
//    var lastYSat: Float = 0.0
//
//    var rLight: Float = 0.0
//    var lastRLight: Float = 0.0
//
//    var gLight: Float = 0.0
//    var lastGLight: Float = 0.0
//
//    var bLight: Float = 0.0
//    var lastBLight: Float = 0.0
//
//    var cLight: Float = 0.0
//    var lastCLight: Float = 0.0
//
//    var mLight: Float = 0.0
//    var lastMLight: Float = 0.0
//
//    var yLight: Float = 0.0
//    var lastYLight: Float = 0.0
//    
//    
//    
//    // MARK: - Convert to Neg
//    var isConvertToNeg: Bool = false
//    var lastIsConvertToNeg: Bool = false
//    
//    var selectedStock: SelectedStock = .porta400
//    var lastSelectedStock: SelectedStock = .porta400
//
//    
//    // MARK: - Texture Variables
//    var isAddGrainEnabled: Bool = false
//    var isAddRebateEnabled: Bool = false
//    
//    
//    
//    // Camera information
//    var isGFX100s: Bool = false
//    var isNikon: Bool = false
//    var isCanon: Bool = false
//    
//
//
//    
//    // Texture
//
//
//    
//    // Apply Filter variables
//    
//    var dMin: NSColor = NSColor(calibratedRed: 0.705, green: 0.494, blue: 0.364, alpha: 1.0)
//    var dMax: NSColor = NSColor(calibratedRed: 0.151, green: 0.090, blue: 0.062, alpha: 1.0)
//    var printFlash: NSColor = NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.95, alpha: 1.0)
//    var isConversionEnabled: Bool = false
//    var isNoritsuEnabled: Bool = false
//    var isSoftenEnabled: Bool = false
//    var isPrintEnabled: Bool = false
//    var isCineonScanEnabled: Bool = false
//    var isNoritsuScanEnabled: Bool = false
//    var isPFEk1Enabled: Bool = false
//    var isPFEk2Enabled: Bool = false
//    
//    var radiusMultiplier: CGFloat = 50.0 // Slider value (0-100)
//    var opacityMultiplier: Float = 50.0
//    var radiusExponent: CGFloat = 1.0
//
//    var cyan: Float = 0.0
//    var magenta: Float = 0.0
//    var yellow: Float = 0.0
//
//    // Scan and Exposure Adjustments
//    var scanContrast: Float = 0.0
//    var offsetRGB: Float = 0.0
//    var offsetRed: Float = 0.0
//    var offsetGreen: Float = 0.0
//    var offsetBlue: Float = 0.0
//    var exposure: Float = 0.0
//    
//    // Grain Settings
//    var grainSoftness: CGFloat = 50.0
//    var grainAlpha: CGFloat = 100.0
//    var grainSize: CGFloat = 1.0
//
//    
//    // Clipping Adjustments
//    var blackClip: Float = 0.0
//    var whiteClip: Float = 255.0
//    
//    var linearGradientMasks: [MaskingModel.LinearGradientMask] = []
//    var radialGradientMasks: [MaskingModel.RadialGradientMask] = []
//
//    // MetaData
//    var iso: String = "Null"
//    var fStop: String = "Null"
//    var shutterSpeed: String = "Null"
//    var cameraMake: String = "Null"
//    
//    
//
//
//    // MARK: init
//    
//    init(
//        rawUrl: URL,
//        name: String? = nil,
//        dateCreated: Date? = nil,
//        previewImage: NSImage? = nil,
//        embeddedPreviewImage: NSImage? = nil,
//        rawDataUi:CIImage? = nil,
//        rawMatchImage: CIImage? = nil,
//        fullScaleCGImage: CGImage? = nil,
//        rawScale: Float? = 0.25,
//        rawRotation: Int = 0,
//        rawExtentX: Int? = 0,
//        rawExtentY: Int? = 0,
//        hasBeenProcessed: Bool = false,
//
//        //Tiling
//        totalColumns512: Int = 0,
//        totalRows512: Int = 0,
//        
//        exportRotation: Int = 0, // 0 for landscape 1 for portrait
//        exportScale: Float = 1.0,
//        fullImageExtent: CGRect = .zero,
//        fullRotatedWidth: Int = 0,
//        fullRotatedHeight: Int = 0,
//        uiWidth: CGFloat = 0.0,
//        uiHeight: CGFloat = 0.0,
//        isPercentEnabled: Bool = false,
//        sizePercent: Int = 100,
//        isLongEdgeEnabled: Bool = false,
//        longEdgeSize: Int = 2000,
//        isShortEdgeEnabled: Bool = false,
//        shortEdgeSize: Int = 2000,
//        exportWidth: Int = 0,
//        exportHeight: Int = 0,
//        
//        rawDataFull:CIImage? = nil,
//        isNewImage: Bool? = true,
//        isRawFile: Bool = false,
//        uiImageCacheUrl: URL? = nil,
//        thumbnailCacheUrl: URL? = nil,
//        importFolderName: String? = nil,
//        metaData: [String: Any] = [:],
//        isCachedImage: Bool? = false,
//        isPreview: Bool? = false,
//        
//        //Settings
//        rawExposure: Float = 0.0,
//        rawContrast: Float = 0.0,
//        rawSaturation: Float = 0.0,
//        
//        // Temp / Tint
//        InitrawTemp: Float = 5500.0,
//        InitrawTint: Float = 0.0,
//        rawTemp: Float = 5500.0,
//        rawTint: Float = 0.0,
//        previousRawTemp: Float = 5500.0,
//        previousRawTint: Float = 0.0,
//        convertTo5500K: Bool = false,
//        
//        // Camera information
//        isGFX100s: Bool = false,
//        isNikon: Bool = false,
//        isCanon: Bool = false,
//        
//        // HDR
//        hdrWhite: Float = 0.0,
//        hdrHighlight: Float = 0.0,
//        hdrShadow: Float = 0.0,
//        hdrBlack: Float = 0.0,
//
//        // HSD
//        rHue: Float = 0.0,
//        gHue: Float = 0.0,
//        bHue: Float = 0.0,
//        cHue: Float = 0.0,
//        mHue: Float = 0.0,
//        yHue: Float = 0.0,
//
//        rSat: Float = 0.0,
//        gSat: Float = 0.0,
//        bSat: Float = 0.0,
//        cSat: Float = 0.0,
//        mSat: Float = 0.0,
//        ySat: Float = 0.0,
//
//        rLight: Float = 0.0,
//        gLight: Float = 0.0,
//        bLight: Float = 0.0,
//        cLight: Float = 0.0,
//        mLight: Float = 0.0,
//        yLight: Float = 0.0,
//        
//        // Convert to neg variables
//        isConvertToNeg: Bool = false,
//        selectedStock: ImageProcessingMain.SelectedStock = .porta400,
//
//        // Texture
//        isAddGrainEnabled: Bool = false,
//        isAddRebateEnabled: Bool = false,
//        
//        // Apply Filter variables
//        dMin: NSColor = NSColor(calibratedRed: 0.705, green: 0.494, blue: 0.364, alpha: 1.0),
//        dMax: NSColor = NSColor(calibratedRed: 0.151, green: 0.090, blue: 0.062, alpha: 1.0),
//        printFlash: NSColor = NSColor(calibratedRed: 0.95, green: 0.95, blue: 0.95, alpha: 1.0),
//        isConversionEnabled: Bool = false,
//        isNoritsuEnabled: Bool = false,
//        isSoftenEnabled: Bool = false,
//        isPrintEnabled: Bool = false,
//        isCineonScanEnabled: Bool = false,
//        isNoritsuScanEnabled: Bool = false,
//        isPFEk1Enabled: Bool = false,
//        isPFEk2Enabled: Bool = false,
//        
//        radiusMultiplier: CGFloat = 50.0,
//        opacityMultiplier: Float = 50.0,
//        radiusExponent: CGFloat = 1.0,
//
//        // Color Adjustments
//        cyan: Float = 0.0,
//        magenta: Float = 0.0,
//        yellow: Float = 0.0,
//        
//        // Scan and Exposure Adjustments
//        scanContrast: Float = 0.0,
//        offsetRGB: Float = 0.0,
//        offsetRed: Float = 0.0,
//        offsetGreen: Float = 0.0,
//        offsetBlue: Float = 0.0,
//        exposure: Float = 0.0,
//        
//        // Grain Settings
//        grainSoftness: CGFloat = 50.0,
//        grainAlpha: CGFloat = 100.0,
//        grainSize: CGFloat = 1.0,
//
//        
//        // Clipping Adjustments
//        blackClip: Float = 0.0,
//        whiteClip: Float = 255.0,
//        
//    // MetaData
//        iso: String = "Null",
//        fStop: String = "Null",
//        shutterSpeed: String = "Null",
//        cameraMake: String = "Null",
//
//
//        linearGradientMasks: [MaskingModel.LinearGradientMask] = [],
//        radialGradientMasks: [MaskingModel.RadialGradientMask] = []
//
//        
//    ) {
//        self.rawUrl = rawUrl
//        self.name = name
//        self.dateCreated = dateCreated
//        self.previewImage = previewImage
//        self.embeddedPreviewImage = embeddedPreviewImage
//        self.rawDataUi = rawDataUi
//        self.rawMatchImage = rawMatchImage
//        self.fullScaleCGImage = fullScaleCGImage
//        self.rawScale = rawScale
//        self.rawRotation = rawRotation
//        self.rawExtentX = rawExtentX
//        self.rawExtentY = rawExtentY
//        
//        self.totalRows512 = totalRows512
//        self.totalColumns512 = totalColumns512
//        
//        self.exportRotation = exportRotation
//        self.exportScale = exportScale
//        self.fullImageExtent = fullImageExtent
//        self.fullRotatedWidth = fullRotatedWidth
//        self.fullRotatedHeight = fullRotatedHeight
//        self.isPercentEnabled = isPercentEnabled
//        self.sizePercent = sizePercent
//        self.isLongEdgeEnabled = isLongEdgeEnabled
//        self.longEdgeSize = longEdgeSize
//        self.isShortEdgeEnabled = isShortEdgeEnabled
//        self.shortEdgeSize = shortEdgeSize
//        self.exportWidth = exportWidth
//        self.exportHeight = exportHeight
//        self.hasBeenProcessed = hasBeenProcessed
//        self.rawDataFull = rawDataFull
//        self.isNewImage = isNewImage
//        self.isRawFile = isRawFile
//        self.uiImageCacheUrl = uiImageCacheUrl
//        self.thumbnailCacheUrl = thumbnailCacheUrl
//        self.importFolderName = importFolderName
//        self.metaData = metaData
//        self.isCachedImage = isCachedImage
//        self.isPreview = isPreview
//        
//        // Settings
//        self.rawExposure = rawExposure
//        self.rawContrast = rawContrast
//        self.rawSaturation = rawSaturation
//        
//        // Tempt / Tint
//        self.InitrawTemp = InitrawTemp
//        self.InitrawTint = InitrawTint
//        self.rawTemp = rawTemp
//        self.rawTint = rawTint
//        self.previousRawTemp = previousRawTemp
//        self.previousRawTint = previousRawTint
//        self.convertTo5500K = convertTo5500K
//        
//        // Camera information
//        self.isGFX100s = isGFX100s
//        self.isNikon = isNikon
//        self.isCanon = isCanon
//        
//        
//        // HDR
//        self.hdrWhite = hdrWhite
//        self.hdrHighlight = hdrHighlight
//        self.hdrShadow = hdrShadow
//        self.hdrBlack = hdrBlack
//        
//        // HSD
//        self.rHue = rHue
//        self.gHue = gHue
//        self.bHue = bHue
//        self.cHue = cHue
//        self.mHue = mHue
//        self.yHue = yHue
//
//        self.rSat = rSat
//        self.gSat = gSat
//        self.bSat = bSat
//        self.cSat = cSat
//        self.mSat = mSat
//        self.ySat = ySat
//
//        self.rLight = rLight
//        self.gLight = gLight
//        self.bLight = bLight
//        self.cLight = cLight
//        self.mLight = mLight
//        self.yLight = yLight
//        
//        // Convert to neg variables
//        self.isConvertToNeg = isConvertToNeg
//        self.selectedStock = selectedStock
//
//        // Texture
//        self.isAddGrainEnabled = isAddGrainEnabled
//        self.isAddRebateEnabled = isAddRebateEnabled
//        
//        // Apply Filter Variables
//        self.dMin = dMin
//        self.dMax = dMax
//        self.printFlash = printFlash
//        self.isConversionEnabled = isConversionEnabled
//        self.isNoritsuEnabled = isNoritsuEnabled
//        self.isSoftenEnabled = isSoftenEnabled
//        self.isPrintEnabled = isPrintEnabled
//        self.isCineonScanEnabled = isCineonScanEnabled
//        self.isNoritsuScanEnabled = isNoritsuScanEnabled
//        self.isPFEk1Enabled = isPFEk1Enabled
//        self.isPFEk2Enabled = isPFEk2Enabled
//
//        self.radiusMultiplier = radiusMultiplier
//        self.opacityMultiplier = opacityMultiplier
//        self.radiusExponent = radiusExponent
//
//        self.cyan = cyan
//        self.magenta = magenta
//        self.yellow = yellow
//        
//        self.scanContrast = scanContrast
//        self.offsetRGB = offsetRGB
//        self.offsetRed = offsetRed
//        self.offsetGreen = offsetGreen
//        self.offsetBlue = offsetBlue
//        self.exposure = exposure
//        
//        self.grainSoftness = grainSoftness
//        self.grainAlpha = grainAlpha
//        self.grainSize = grainSize
//
//        
//        self.blackClip = blackClip
//        self.whiteClip = whiteClip
//        
//        self.linearGradientMasks = linearGradientMasks
//        self.radialGradientMasks = radialGradientMasks
//
//        // MetaData
//        self.iso = iso
//        self.fStop = fStop
//        self.shutterSpeed = shutterSpeed
//        self.cameraMake = cameraMake
//        
//    }
//}
//
//extension RawImage: Equatable {
//    static func ==(lhs: RawImage, rhs: RawImage) -> Bool {
//        return lhs.id == rhs.id && lhs.rawUrl == rhs.rawUrl
//    }
//}
//
//
