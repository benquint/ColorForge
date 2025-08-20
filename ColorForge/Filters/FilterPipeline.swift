//
//  FilterPipeline.swift
//  ColorForge
//
//  Created by admin on 01/06/2025.
//

import Foundation
import CoreImage
import Combine
import CoreImage.CIFilterBuiltins
import CoreGraphics
import SwiftUI


// MARK: - Protocol

protocol FilterNode {
    func apply(to input: CIImage) -> CIImage
}

protocol EnlargerNode {
    func apply(to input: CIImage) -> (CIImage)
}

protocol FilterNodeMaskable: FilterNode {
    //    var isMask: Bool { get }
    var isMask: Bool { get set }
    var maskData: Any? { get set }
    
}

protocol InitialFilterNode {
    func apply() -> (CIImage, SIMD2<Float>, Float)
}

protocol HRNode {
    func apply() -> (CIImage)
}

enum AnyGradientMask {
    case linear(LinearGradientMask)
    case radial(RadialGradientMask)
    case ai(AiMask)
    
    var id: UUID {
        switch self {
        case .linear(let mask): return mask.id
        case .radial(let mask): return mask.id
        case .ai(let mask): return mask.id
        }
    }
    
    var name: String {
        switch self {
        case .linear(let mask): return mask.name
        case .radial(let mask): return mask.name
        case .ai(let mask): return mask.name
        }
    }
}

// MARK: - Extensions

extension CGPoint {
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

extension FilterPipeline {
    
    
    func applyNodeWithMasks<NodeType: FilterNode>(
        baseImage: CIImage,
        item: ImageItem,
        nodeType: String,
        globalNode: NodeType,
        maskBuilder: (MaskParameterSet) -> NodeType
    ) -> CIImage {
        

        
        var result = globalNode.apply(to: baseImage)
        
        let linear = item.maskSettings.linearGradients.map { AnyGradientMask.linear($0) }
        let radial = item.maskSettings.radialGradients.map { AnyGradientMask.radial($0) }
        let ai = item.maskSettings.aiMasks.map { AnyGradientMask.ai($0) }
        let relevantMasks = linear + radial + ai
        
        for mask in relevantMasks {
            let maskId: UUID
            let start: CGPoint
            let end: CGPoint
            let name: String
            let width: CGFloat
            let height: CGFloat
            let feather: Float
            let invert: Bool
            let opacity: Float
            let maskImage: CIImage
            
            switch mask {
            case .linear(let linear):
                maskId = linear.id
                name = linear.name
                start = linear.startPoint
                end = linear.endPoint
                width = 0
                height = 0
                feather = 0
                invert = false
                opacity = 100
                maskImage = CIImage.empty()
                
            case .radial(let radial):
                maskId = radial.id
                name = radial.name
                start = radial.startPoint
                end =  radial.endPoint
                width = radial.width
                height = radial.height
                feather = radial.feather
                invert = radial.invert
                opacity = radial.opacity
                maskImage = CIImage.empty()
                
                
            case .ai(let ai):
                maskId = ai.id
                name = ai.name
                start = .zero
                end =  .zero
                width = 0
                height = 0
                feather = 0.0 /*ai.feather*/
                invert = ai.invert
                opacity = ai.opacity
                maskImage = ai.maskImage ?? CIImage.empty()
            }
 
            guard let settings = item.maskSettings.settingsByMaskID[maskId] else {
                continue
            }
            
            let maskNode = maskBuilder(settings)
            
            // Linear blending only for now
            switch mask {
            case .linear:
                if start == end {
                    
                    result = maskNode.apply(to: result)
                } else {
                
                    let maskedOutput = maskNode.apply(to: baseImage)
                    result = maskedOutput.applyLinearGradientAndBlend(start, end, result)
                }
                
            case .radial:
                
                if start == end {
                    result = maskNode.apply(to: result)
                } else {

                    let maskedOutput = maskNode.apply(to: baseImage)
                    result = maskedOutput.applyRadialMask(
                        result,
                        start,
                        width,
                        height,
                        feather,
                        invert,
                        opacity
                    )
                }
                
            case .ai:
 

                let maskedOutput = maskNode.apply(to: baseImage)
//                    debugSave(maskImage, "PiplineMaskImage")
//                result = result.applyAiMask(maskImage, maskedOutput, feather, invert)
                result = result.blendWithMask(maskImage, maskedOutput)
                
            }
        }
        
        let cachedResult = result.insertingIntermediate(cache: true)
        
        result = cachedResult
        
        return result
    }
    
    
    func applyEnlargerV2MaskNodeWithMasks(
        baseImage: CIImage,
        item: ImageItem
    ) -> CIImage {
        var result = baseImage
        

        
        let linear = item.maskSettings.linearGradients.map { AnyGradientMask.linear($0) }
        let radial = item.maskSettings.radialGradients.map { AnyGradientMask.radial($0) }
        let ai = item.maskSettings.aiMasks.map { AnyGradientMask.ai($0) }
        let relevantMasks = linear + radial + ai
        
        for mask in relevantMasks {
            // Extract shared values
            let maskId: UUID
            let start: CGPoint
            let end: CGPoint
            let width: CGFloat
            let height: CGFloat
            let feather: Float
            let invert: Bool
            let opacity: Float
            let maskImage: CIImage
            
            switch mask {
            case .linear(let linear):
                maskId = linear.id
                start = linear.startPoint
                end = linear.endPoint
                width = 0
                height = 0
                feather = 0
                invert = false
                opacity = 100
                maskImage = CIImage.empty()
                
                
            case .radial(let radial):
                maskId = radial.id
                start = radial.startPoint
                end =  radial.endPoint
                width = radial.width
                height = radial.height
                feather = radial.feather
                invert = radial.invert
                opacity = radial.opacity
                maskImage = CIImage.empty()
                
                
            case .ai(let ai):
                maskId = ai.id
                start = .zero
                end =  .zero
                width = 0
                height = 0
                feather = ai.feather
                invert = ai.invert
                opacity = ai.opacity
                maskImage = ai.maskImage ?? CIImage.empty()
                
            }
            
            guard let params = item.maskSettings.settingsByMaskID[maskId] else {
                continue
            }
            
            let node = EnlargerV2MaskNode(
                applyPrintMode: item.applyPrintMode,
                convertToNeg: item.convertToNeg,
                evSeconds: params.enlargerExp,
                fstop: params.enlargerFStop,
                bwMode: item.bwMode,
                cyan: params.cyan,
                magenta: params.magenta,
                yellow: params.yellow
            )
            
            switch mask {
            case .linear:
                if start == end {
                    result = node.apply(to: result)
                } else {
                    let masked = node.apply(to: baseImage)
                    result = masked.applyLinearGradientAndBlend(start, end, result).insertingIntermediate(cache: true)
                }
                
            case .radial:
                
                if width == 0 || height == 0 {
                    result = node.apply(to: result)
                } else {
                    let masked = node.apply(to: baseImage)
                    result = masked.applyRadialMask(
                        result,
                        start,
                        width,
                        height,
                        feather,
                        invert,
                        opacity
                    ).insertingIntermediate(cache: true)
                }
                
            case .ai:
                if start == end {
                    result = node.apply(to: result)
                } else {
                    let maskedOutput = node.apply(to: baseImage)
                    result = result.blendWithMask(maskImage, maskedOutput)
                }
            }
        }
        
        return result
    }
    
    
    //    func applyEnlargerV2MaskNodeWithMasks(
    //        baseImage: CIImage,
    //        item: ImageItem
    //    ) -> CIImage {
    //        var result = baseImage
    //        let settings = item.maskSettings
    //
    //        guard let uiImage = item.debayeredInit else {
    //            return baseImage
    //        }
    //
    //        var scalar = 1.0
    //
    //        if item.isExport {
    //            scalar = baseImage.extent.width / uiImage.extent.width
    //        }
    //
    //        let linear = settings.linearGradients.map { AnyGradientMask.linear($0) }
    //        let radial = settings.radialGradients.map { AnyGradientMask.radial($0) }
    //        let relevantMasks = linear + radial
    //
    //
    //        for mask in relevantMasks {
    //            var previousResult = result
    //
    //            switch mask {
    //            case .linear(let linear):
    //
    //                let start = linear.startPoint
    //                let end = linear.endPoint
    //
    //
    //
    //                if let params = item.maskSettings.settingsByMaskID[linear.id] {
    //
    //                    let node = EnlargerV2MaskNode(
    //                        applyPrintMode: item.applyPrintMode,
    //                        convertToNeg: item.convertToNeg,
    //                        evSeconds: params.enlargerExp,
    //                        fstop: params.enlargerFStop,
    //                        bwMode: item.bwMode,
    //                        cyan: params.cyan,
    //                        magenta: params.magenta,
    //                        yellow: params.yellow
    //                    )
    //
    //                    previousResult = result
    //                    let masked = node.apply(to: previousResult)
    //                    result = masked.applyLinearGradientAndBlend(start * scalar, end * scalar, previousResult)
    //
    //
    //                } else {
    //                    print("No params for linear mask with id \(linear.id)")
    //                }
    //
    //            case .radial(let radial):
    //                let start = radial.startPoint * scalar
    //                let width = radial.width * scalar
    //                let height = radial.height * scalar
    //                let feather = radial.feather
    //                let opacity = radial.opacity
    //                let invert = radial.invert
    //
    //                guard let data = LutModel.shared.enlargerInverseData else {return baseImage}
    //
    //                if let params = item.maskSettings.settingsByMaskID[radial.id] {
    //
    //                    let node = EnlargerV2MaskNode(
    //                        applyPrintMode: item.applyPrintMode,
    //                        convertToNeg: item.convertToNeg,
    //                        evSeconds: params.enlargerExp,
    //                        fstop: params.enlargerFStop,
    //                        bwMode: item.bwMode,
    //                        cyan: params.cyan,
    //                        magenta: params.magenta,
    //                        yellow: params.yellow
    //                    )
    //
    //
    //                    let masked = node.apply(to: previousResult)
    //                    result = masked.applyRadialMask(
    //                        previousResult,
    //                        start,
    //                        width,
    //                        height,
    //                        feather,
    //                        invert,
    //                        opacity,
    //                        data
    //                    )
    //                } else {
    //                    print("No params for radial mask with id \(radial.id)")
    //                }
    //
    //            }
    //        }
    //
    //        let cachedResult = result.insertingIntermediate(cache: true)
    //
    //        result = cachedResult
    //
    //        return result
    //    }
    
    
}


// MARK: - Class

class FilterPipeline: ObservableObject {
    static let shared = FilterPipeline()
    
    init() {
        // Load "Hand" image from asset catalog
        if let nsImage = NSImage(named: "Hand"),
           let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            self.handImage = CIImage(cgImage: cgImage)
        } else {
            print("Warning: Hand image not found in asset catalog.")
            self.handImage = CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        
        // Load "GrainRamp.tiff" from app bundle
        if let url = Bundle.main.url(forResource: "GrainRamp", withExtension: "tiff"),
           let ciImage = CIImage(contentsOf: url) {
            self.grainRamp = ciImage
        } else {
            print("Warning: GrainRamp.tiff not found in bundle.")
            self.grainRamp = CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }
    
    public var grainRamp: CIImage
    
    var pipelineOrder: [String] = [
        "TempAndTintNode",
        "RawExposureNode",
        "RawContrastNode",
        "GlobalSaturationNode",
        "HDRNode",
        "PreviewHueRangeNode",
        "HueSaturationDensityNode", // HSD
        "MTFCurveNode",
        "GrainNode",
        "OffsetNode",
        "ScanContrastNode",
        "PrintHalationNode",
        "Kodak2383Node",
        "Portra400Node",
        "FilmStockNode",
        "DecodeNegativeNode",
        "PaperSoftenNode",
        "PrintCurveNode",
        "BlackAndWhiteEnlargerNode",
        "LegacyEnlargerNode",
        "LegacyPrintCurveAndGamutNode",
        "EnlargerV2Node",
        "EnlargerV2MaskNode",
        "ApplyAdobeCameraRawCurveNode",
        "RealisticFilmGrainNode"
        
    ]
    
    
    // Published variables
    @Published var isReady: Bool = false
    @Published var sourceUrl: URL?
    
    public var imageViewWidth: CGFloat = 1920.0
    public var imageViewHeight: CGFloat = 1200.0
    public var imageViewPadding: CGFloat = 40.0
    
    
    @Published var previewFlash: Bool = false
    
    // Will need to be in imageiten
    @Published var bwMode: Bool = false {
        didSet{
            print("\n\nBlack and white mode active\n\n")
        }
    }
    
    // MARK: - Cache
    private var cachedEnlargerExp: Float = 0.0
    private var cachedCyan: Float = 0.0
    private var cachedMagenta: Float = 0.0
    private var cachedYellow: Float = 0.0
    
    @Published var flashColor: CIColor = .white
    
    
    public var handImage: CIImage
    
    
    
    
    public var xyChromaticity: CGPoint = CGPoint(x: 0.3, y: 0.3)
    
    var isMask: Bool = false
    var backingImage: CIImage = CIImage(color: .white)
    
    var baseNodes: [FilterNode] = []
    var maskableNodes: [FilterNodeMaskable] = []
    
    private var baselineExposure: Float = 0.0
    
    @Published var processedImage: CIImage?
    
    public var debayeredImage: CIImage?
    
    @Published var previewImage: NSImage?
    
    // MARK: - Loading
    
    
    
    
    public var currentUrl: URL?
    public var fullResImage: CIImage?
    
    


    
    public var exportMode: Bool = false
    public var isLut: Bool = false
    
    
    // MARK: - Masking
    
    let MaskableNodeTypes: Set<String> = [
        "TempAndTintNode",
        "RawExposureNode",
        "RawContrastNode",
        "GlobalSaturationNode",
        "HDRNode",
        "HueSaturationDensityNode"
    ]
    
    private func getSelectedMask(from item: ImageItem) -> LinearGradientMask? {
        print("Available mask IDs: \(item.maskSettings.linearGradients.map(\.id))")
        guard let selectedID = ImageViewModel.shared.selectedMask else {
            print("No selected mask ID in ImageViewModel")
            return nil
        }
        
        if let mask = item.maskSettings.linearGradients.first(where: { $0.id == selectedID }) {
            return mask
        } else {
            print("Selected mask ID \(selectedID) not found in item \(item.id)'s mask list")
            print("Available mask IDs: \(item.maskSettings.linearGradients.map(\.id))")
            return nil
        }
    }
    
    
    private func duplicateNodeWithMask(_ node: FilterNode, mask: LinearGradientMask) -> FilterNode? {
        guard var maskable = node as? FilterNodeMaskable else { return nil }
        maskable.isMask = true
        maskable.maskData = mask // or use a strong-typed var like `maskable.linearGradientMask = mask`
        return maskable
    }
    
    
    
    
    
    // MARK: - Apply Pipelines
    
    

    @Published var currentID: UUID? = nil {
        didSet{
            //			print("FilterPipeline, currentID set to: \(currentID)")
        }
    }
    
    
    @Published var currentURL: URL?
    
    private var debounceWorkItems: [UUID: DispatchWorkItem] = [:]
    private let debounceQueue = DispatchQueue(label: "com.colorforge.pipelineDebounce", qos: .userInitiated)
    
    public var currentResult: CIImage?
    
    
    // Zoom
    @Published var zoomIn: Bool = false {
        didSet{
            print("Zoom In toggled in pipeline")
        }
    }
    @Published var zoomRect: CGRect = .zero
    
    private var computedTranslationX: CGFloat {
        return -zoomRect.origin.x
    }
    
    private var computedTranslationY: CGFloat {
        return -zoomRect.origin.y
    }
    
    private var currentDebayered: CIImage?
    public var currentHR: CIImage?
    
    public var imageToProcess: CIImage? {
        let isZoomed = ImageViewModel.shared.isZoomed
        let rect = ImageViewModel.shared.zoomRect
        
        guard let displayImage = currentDebayered else { return nil }
        guard let highRes = currentHR else { return nil }
        
        print("ImageToProcess: currentDebayered = \(currentDebayered != nil), currentHR = \(currentHR != nil)")
        print("Zooming with zoomRect = \(rect)")
        print("HighRes extent = \(highRes.extent)")
        
        if isZoomed, rect.width > 0, rect.height > 0, highRes.extent.contains(rect) {
            let zoomed = highRes.cropped(to: rect)
            print("After crop extent = \(zoomed.extent)")
            let translated = zoomed.transformed(by: .init(
                translationX: -rect.origin.x,
                y: -rect.origin.y
            ))
            print("Translated extent: \(translated.extent)")
            return translated
        } else {
            return displayImage
        }
    }
    
    
    
    
    @Published var logMode: Bool = false
    @Published var tiffScanMode: Bool = false
    
    //
    
    
    
    // MARK: - Apply Pipeline V2
    
    var isExport: Bool = false
    
    private var enlargerRamp: CIImage? = nil
    
    
    private func populateRamp() {
        guard let eRamp = LutModel.shared.enlargerRamp else {
            return
        }
        enlargerRamp = eRamp
    }
    
    @discardableResult
    func applyPipelineV2Sync(_ id: UUID, _ dataModel: DataModel, _ inputImage: CIImage? = nil, _ isFirstLoad: Bool? = false) -> CIImage? {
        let viewModel = ImageViewModel.shared
        
        
        
        guard let item = dataModel.items.first(where: { $0.id == id }) else {
            print("No item found for ID: \(id)")
            return nil
        }
        
        var result: CIImage
        
		if logMode {
			result = item.url.asCIImage()
//			result = result.slogToLin()
			result = result.LogC2Lin()
		} else {
		
//        if tiffScanMode {
//            result = item.url.asCIImage()
//        } else {
        
			if inputImage == nil {
				guard let base = self.unwrapAndReturnImagesSync(item, dataModel) else {
					print("Failed to unwrap image")
					return nil }
				result = base
			} else {
				guard let input = inputImage else { return nil}
				result = input
			}
			
		}
        
        
        
	
        if !tiffScanMode {
            
            // TempAndTintNode
            result = applyNodeWithMasks(
                baseImage: result,
                item: item,
                nodeType: "TempAndTintNode",
                globalNode: TempAndTintNode(
                    targetTemp: item.initTemp,
                    targetTint: item.initTint,
                    sourceTemp: item.temp,
                    sourceTint: item.tint,
                    convertToNeg: item.convertToNeg
                ),
                maskBuilder: { mask in
                    TempAndTintNode(
                        targetTemp: mask.initTemp,
                        targetTint: mask.initTint,
                        sourceTemp: mask.temp,
                        sourceTint: mask.tint,
                        convertToNeg: item.convertToNeg
                    )
                }
            )
            
            //		result = result.replaceResultWithHald()
            
            if logMode {
                // Convert to AWG
                			result = result.sGamutCineToAWG3()
            } else {
                //			result = result.P3ToAWG()
            }
            
            
            
            // RawExposureNode
            result = applyNodeWithMasks(
                baseImage: result,
                item: item,
                nodeType: "RawExposureNode",
                globalNode: RawExposureNode(
                    exposure: item.exposure,
                    baselineEV: item.baselineExposure,
                    convertToNeg: item.convertToNeg,
                    applyScanMode: item.applyScanMode,
                    bwMode: item.bwMode,
                    isLut: false,
                    logMode: logMode
                ),
                maskBuilder: { settings in
                    RawExposureNode(
                        exposure: settings.exposure,
                        baselineEV: item.baselineExposure,
                        convertToNeg: item.convertToNeg,
                        applyScanMode: item.applyScanMode,
                        bwMode: item.bwMode,
                        isLut: false,
                        logMode: logMode
                    )
                }
            )
            
            // Convert to logC
            result = result.Lin2LogC()
            
            
            // Debug
//            debugSave(result, "LogC_\(item.url.lastPathComponent)")
            
            // RawContrastNode
            result = applyNodeWithMasks(
                baseImage: result,
                item: item,
                nodeType: "RawContrastNode",
                globalNode: RawContrastNode(contrast: item.contrast),
                maskBuilder: { mask in
                    RawContrastNode(contrast: mask.contrast)
                }
            )
            
            //		var index = 0
            //		let passes = 3
            //
            //		for pass in 0..<passes {
            //			index += 1
            //			let noise = result.createNoiseAndCrop()
            //			let perlin = result.smallPerlin()
            //			debugSave(perlin, "Small Perlin\(index)")
            //			debugSave(noise, "NoiseDefault\(index)")
            //		}
            
            
            // Convert to spherical
            result = result.RGBtoSpherical()
            
            
            // GlobalSaturationNode
            result = applyNodeWithMasks(
                baseImage: result,
                item: item,
                nodeType: "GlobalSaturationNode",
                globalNode: GlobalSaturationNode(saturation: item.saturation),
                maskBuilder: { mask in
                    GlobalSaturationNode(saturation: mask.saturation)
                }
            )
            
            
            // Convert to RGB
            result = result.SphericaltoRGB()
            
            //        debugSave(result, "not scaled")
            //        let scaledDebug = result.downAndUp(0.71)
            //        debugSave(scaledDebug, "scaled")
            //
            
            // HDRNode
            result = applyNodeWithMasks(
                baseImage: result,
                item: item,
                nodeType: "HDRNode",
                globalNode: HDRNode(
                    hdrWhite: item.hdrWhite,
                    hdrHighlight: item.hdrHighlight,
                    hdrShadow: item.hdrShadow,
                    hdrBlack: item.hdrBlack
                ),
                maskBuilder: { mask in
                    HDRNode(
                        hdrWhite: mask.hdrWhite,
                        hdrHighlight: mask.hdrHighlight,
                        hdrShadow: mask.hdrShadow,
                        hdrBlack: mask.hdrBlack
                    )
                }
            )
            
            
            // Convert to spherical
            result = result.RGBtoSpherical()
            
            
            
            // HueSaturationDensityNode
            result = applyNodeWithMasks(
                baseImage: result,
                item: item,
                nodeType: "HueSaturationDensityNode",
                globalNode: HueSaturationDensityNode(
                    redHue: item.redHue, redSat: item.redSat, redDen: item.redDen,
                    greenHue: item.greenHue, greenSat: item.greenSat, greenDen: item.greenDen,
                    blueHue: item.blueHue, blueSat: item.blueSat, blueDen: item.blueDen,
                    cyanHue: item.cyanHue, cyanSat: item.cyanSat, cyanDen: item.cyanDen,
                    magentaHue: item.magentaHue, magentaSat: item.magentaSat, magentaDen: item.magentaDen,
                    yellowHue: item.yellowHue, yellowSat: item.yellowSat, yellowDen: item.yellowDen
                ),
                maskBuilder: { mask in
                    HueSaturationDensityNode(
                        redHue: mask.redHue, redSat: mask.redSat, redDen: mask.redDen,
                        greenHue: mask.greenHue, greenSat: mask.greenSat, greenDen: mask.greenDen,
                        blueHue: mask.blueHue, blueSat: mask.blueSat, blueDen: mask.blueDen,
                        cyanHue: mask.cyanHue, cyanSat: mask.cyanSat, cyanDen: mask.cyanDen,
                        magentaHue: mask.magentaHue, magentaSat: mask.magentaSat, magentaDen: mask.magentaDen,
                        yellowHue: mask.yellowHue, yellowSat: mask.yellowSat, yellowDen: mask.yellowDen
                    )
                }
            )
            
            // Convert to RGB
            result = result.SphericaltoRGB()
            
            
            
            // THOG NODE
            var thogResult = result
            //        thogResult = THOGNode(applyTHOG: item.applyTHOG, isExport: item.isExport, blend: item.blend, variance: item.variance, scale: item.scale).apply(to: result)
            
            
            
            
            
            // Convert to neg gamma 2.2
            result = result.cineonToNeg()
            result = result.encodeGamma22()
            
            // MTFCurveNode
            let nativeLongEdge = max(item.nativeWidth, item.nativeHeight)
            result = MTFCurveNode(
                applyMTF: item.applyMTF,
                mtfAmount: item.mtfBlend,
                format: item.selectedGateWidth,
                applyGrain: item.applyGrain,
                exportMode: item.isExport,
                nativeLongEdge: nativeLongEdge,
                isExport: item.isExport,
                uiScale: item.uiScale
            ).apply(to: result)
            
            // Convert back
            result = result.decodeGamma22()
            result = result.negToCineon()
            
            
            result = NoiseGrainNode(
                isExport: item.isExport, applyGrain: item.applyGrain
            ).apply(to: result)
            
            //		result = NoiseGrainNodeV2(
            //			isExport: item.isExport,
            //            uiScale: item.uiScale,
            //            id: item.id
            //		).apply(to: result)
            
            
            
            //        result = RealisticFilmGrainNode(
            //            applyGrain: item.applyGrain,
            //            isExport: item.isExport,
            //            grain54_low: item.grain54_low,
            //            grain54_high: item.grain54_high,
            //            grain60mm_low: item.grain60mm_low,
            //            grain60mm_high: item.grain60mm_high,
            //            grain53mm_low: item.grain53mm_low,
            //            grain53mm_high: item.grain53mm_high,
            //            grain36mm_low: item.grain36mm_low,
            //            grain36mm_high: item.grain36mm_high,
            //            grain25mm_low: item.grain25mm_low,
            //            grain25mm_high: item.grain25mm_high,
            //            grain21mm_low: item.grain21mm_low,
            //            grain21mm_high: item.grain21mm_high,
            //            grain18mm_low: item.grain18mm_low,
            //            grain18mm_high: item.grain18mm_high,
            //            grain10mm_low: item.grain10mm_low,
            //            grain10mm_high: item.grain10mm_high,
            //            grain5mm_low: item.grain5mm_low,
            //            grain5mm_high: item.grain5mm_high,
            //            grain6mm_low: item.grain6mm_low,
            //            grain6mm_high: item.grain6mm_high,
            //            gateWidth: item.selectedGateWidth,
            //            amount: item.grainAmount
            //        ).apply(to: result)
            
            // FilmStockNode
            result = FilmStockNode(
                stockChoice: item.stockChoice,
                convertToNeg: item.convertToNeg
            ).apply(to: result)
            
        
        
        // DecodeNegativeNode
        result = DecodeNegativeNode(
            convertToNeg: item.convertToNeg,
            applyScanMode: item.applyScanMode,
            stockChoice: item.stockChoice
        ).apply(to: result)
        
        } // end of tiff scan mode
        
        
        if tiffScanMode {
            result = result.decodeGamma22()
        }
        
//        if item.applyTHOG {
//            result = thogResult
//        }
        result = PaperNode(
            convertToNeg: item.convertToNeg,
            showPaperMask: item.showPaperMask,
            imageScale: item.borderImgScale,
            maskScale: item.borderScale,
            maskXshift: item.borderXshift,
            maskYshift: item.borderYshift
        ).apply(to: result)
        
//        if item.applyTHOG {
//            thogResult = result
//        }
        

            
            // OffsetNode (can be made maskable later if needed)
            let offsetNode = OffsetNode(
                neg: item.convertToNeg,
                applyScanMode: item.applyScanMode,
                offsetRGB: item.offsetRGB,
                offsetRed: item.offsetRed,
                offsetGreen: item.offsetGreen,
                offsetBlue: item.offsetBlue
            )
            result = offsetNode.apply(to: result)
            
            // Kodak2383Node   ScanLutNode
        
        result = ScanLutNode(
            neg: item.convertToNeg,
            blend: item.lutBlend,
            applyScanMode: item.applyScanMode,
            applyPFE: item.applyPFE,
            apply2383: item.apply2383,
            apply3513: item.apply3513
        ).apply(to: result)

            
            // ScanContrastNode
            let scanContrastNode = ScanContrastNode(
                neg: item.convertToNeg,
                applyScanMode: item.applyScanMode,
                scanContrast: item.scanContrast
            )
            result = scanContrastNode.apply(to: result)
            
            
        
//                // PaperSoftenNode
//                result = PaperSoftenNode(
//                    applyPrintMode: item.applyPrintMode,
//                    convertToNeg: item.convertToNeg
//                ).apply(to: result)
//        
        
        
        
        
        // EnlargerV2Node
        let enlargerNode = EnlargerV2Node(
            tiffScanMode: tiffScanMode,
            applyPrintMode: item.applyPrintMode,
            convertToNeg: item.convertToNeg,
            evSeconds: item.enlargerExp,
            fstop: item.enlargerFStop,
            cyan: item.cyan,
            magenta: item.magenta,
            yellow: item.yellow,
            bwMode: item.bwMode,
            useLegacy: false
        )
        
        result = enlargerNode.apply(to: result)
        
        if tiffScanMode {
            result = result.encodeGamma22()
        }
        
        // EnlargerV2Node (maskable)
        result = applyEnlargerV2MaskNodeWithMasks(
            baseImage: result,
            item: item
        )
        
        
        let nativeLongEdge = max(item.nativeWidth, item.nativeHeight)
        // PrintHalationNode (maskable)
        result = applyNodeWithMasks(
            baseImage: result,
            item: item,
            nodeType: "PrintHalationNode",
            globalNode: PrintHalationV2Node(
                nativeWidth: nativeLongEdge,
                printHalation_size: item.printHalation_size,
                printHalation_amount: item.printHalation_amount,
                printHalation_darkenMode: item.printHalation_darkenMode,
                printHalation_apply: item.printHalation_apply,
                isExport: item.isExport
            ),
            maskBuilder: { mask in
                PrintHalationV2Node(
                    nativeWidth: nativeLongEdge,
                    printHalation_size: mask.printHalation_size,
                    printHalation_amount: mask.printHalation_amount,
                    printHalation_darkenMode: mask.printHalation_darkenMode,
                    printHalation_apply: item.printHalation_apply,
                    isExport: item.isExport
                )
            }
        )
        
        
        //            // LegacyEnlargerNode (maskable)
        //            result = applyNodeWithMasks(
        //                baseImage: result,
        //                item: item,
        //                nodeType: "LegacyEnlargerNode",
        //                globalNode: LegacyEnlargerNode(
        //                    applyPrintMode: item.applyPrintMode,
        //                    convertToNeg: item.convertToNeg,
        //                    evSeconds: item.legacyExposure,
        //                    cyan: item.legacyCyan,
        //                    magenta: item.legacyMagenta,
        //                    yellow: item.legacyYellow,
        //                    bwMode: item.bwMode,
        //                    stockChoice: item.stockChoice,
        //                    useLegacy: item.useLegacy
        //                ),
        //                maskBuilder: { mask in
        //                    LegacyEnlargerNode(
        //                        applyPrintMode: item.applyPrintMode,
        //                        convertToNeg: item.convertToNeg,
        //                        evSeconds: mask.legacyExposure,
        //                        cyan: mask.legacyCyan,
        //                        magenta: mask.legacyMagenta,
        //                        yellow: mask.legacyYellow,
        //                        bwMode: item.bwMode,
        //                        stockChoice: item.stockChoice,
        //                        useLegacy: item.useLegacy
        //                    )
        //                }
        //            )
        //
        //            // LegacyPrintCurveAndGamutNode
        //            result = LegacyPrintCurveAndGamutNode(
        //                bwMode: item.bwMode,
        //                convertToNeg: item.convertToNeg,
        //                applyPrintMode: item.applyPrintMode,
        //                stockChoice: item.stockChoice,
        //                useLegacy: item.useLegacy
        //            ).apply(to: result)
        
        
        
        var flash = result
        var flashPreview = result
        
        if item.previewFlash {
            flashPreview = FlashNode(
                applyPrintMode: item.applyPrintMode,
                previewFlash: item.previewFlash,
                applyFlash: item.applyFlash,
                flashEV: item.flashEV,
                flashFStop: item.flashFStop,
                flashCyan: item.flashCyan,
                flashMagenta: item.flashMagenta,
                flashYellow: item.flashYellow,
                hand: handImage).apply(to: result)
            
        } else {
            flash = FlashNode(
                applyPrintMode: item.applyPrintMode,
                previewFlash: item.previewFlash,
                applyFlash: item.applyFlash,
                flashEV: item.flashEV,
                flashFStop: item.flashFStop,
                flashCyan: item.flashCyan,
                flashMagenta: item.flashMagenta,
                flashYellow: item.flashYellow,
                hand: handImage).apply(to: result)
        }
        
        
        // PrintGamutNode
        let printGamutNode = PrintGamutNode(
            tiffScanMode: tiffScanMode,
            convertToNeg: item.convertToNeg,
            applyPrintMode: item.applyPrintMode,
            bwMode: item.bwMode,
            useLegacy: item.useLegacy,
            applyFlash: item.applyFlash,
            flash: flash
        )
        
        result = printGamutNode.apply(to: result)
        
        // BlackAndWhiteEnlargerNode (maskable)
        result = applyNodeWithMasks(
            baseImage: result,
            item: item,
            nodeType: "BlackAndWhiteEnlargerNode",
            globalNode: BlackAndWhiteEnlargerNode(
                applyPrintMode: item.applyPrintMode,
                convertToNeg: item.convertToNeg,
                evSeconds: item.enlargerExp,
                fstop: item.enlargerFStop,
                magenta: item.magenta,
                bwMode: item.bwMode,
                useLegacy: item.useLegacy
            ),
            maskBuilder: { mask in
                BlackAndWhiteEnlargerNode(
                    applyPrintMode: item.applyPrintMode,
                    convertToNeg: item.convertToNeg,
                    evSeconds: mask.enlargerExp,
                    fstop: mask.enlargerFStop,
                    magenta: mask.magenta,
                    bwMode: item.bwMode,
                    useLegacy: item.useLegacy
                )
            }
        )
        
        
        if !tiffScanMode {
            // ApplyAdobeCameraRawCurveNode
            result = ApplyAdobeCameraRawCurveNode(
                convertToNeg: item.convertToNeg
            ).apply(to: result)
            
             result = AddPaperBlackNode().apply(to: result)
        }

        
        //        result = TomJamiesonFilter(applyTom: item.applyTom).apply(to: result)
        

//        debugSave(result, "\(item.url.lastPathComponent)")
        
        
		// ****************************************************************** //

//		guard var debugResult = item.debayeredInit else {return nil}
//		
//		// TempAndTintNode
//		debugResult = TempAndTintNode(
//				targetTemp: item.initTemp,
//				targetTint: item.initTint,
//				sourceTemp: item.temp,
//				sourceTint: item.tint,
//				convertToNeg: item.convertToNeg
//		).apply(to: debugResult)
//		
//		
//		debugResult = debugResult.P3ToAWG()
//		
//		debugResult = EncodeFromSensorNode(baselineExposure: 0.0).apply(to: debugResult)
//		
//		
//		debugResult = debugResult.LogC2Lin()
//		
//		// RawExposureNode
//		debugResult = RawExposureNode(
//				exposure: item.exposure,
//				convertToNeg: item.convertToNeg,
//				applyScanMode: item.applyScanMode,
//				bwMode: item.bwMode,
//				isLut: false
//		).apply(to: debugResult)
//		
//		debugResult = debugResult.Lin2LogC()
//		
//		debugSave(debugResult, "Arri_")
//		
//		result = debugResult
		
		// ****************************************************************** //
		
		
		
		
		
		
        
//        if item.applyTHOG {
//            
//            result = thogResult
//            
//        }

        
        let finalFlash = flashPreview
        
        let finalImage = result
        
        if !item.isExport {
            
            if item.previewFlash {
                
                
                DispatchQueue.main.async {
                    ImageViewModel.shared.imageToRender = finalFlash
                    
                    if let renderer = RenderingManager.shared.renderer {
                        renderer.updateImage(finalFlash)
                    } else {
                        print("No renderer to send result to")
                    }
                }
                
            } else {
    
                
                DispatchQueue.main.async {
                    self.processedImage = finalImage
                    self.currentResult = finalImage
                    
                    if let initBool = isFirstLoad {
                        if !initBool {
                            
                            
                            ImageViewModel.shared.renderSumbitted.toggle()
                            ImageViewModel.shared.imageToRender = finalImage
                            
                            if viewModel.imageViewActive {
                                
                                if let renderer = RenderingManager.shared.renderer {
                                    renderer.updateImage(finalImage)
                                } else {
                                    print("No renderer to send result to")
                                }
                                
                                // Update item
                                dataModel.updateItem(id: id) { item in
                                    item.processImage = finalImage
                                }
        
                            } else {
                                
                                
                                    self.processThumb(finalImage, id, dataModel, RenderingManager.shared.mainImageContext)

                               

                            }
							
							HistogramModel.shared.generateDataDebounced(finalImage)
							
                        } else {
                            self.processThumb(finalImage, id, dataModel, RenderingManager.shared.mainImageContext)
                            
                            dataModel.updateItem(id: id) { item in
                                item.processImage = finalImage
                            }
                            
                        }
                    }
                    
 
                    
                    
                }
            }
        } else {
            return finalImage
        }
        
        return finalImage
    }
    
    
    private var lastThumbnailRenderTime: Date = .distantPast
    private let thumbnailThrottleInterval: TimeInterval = 0.1
    
    func processThumb(_ image: CIImage, _ id: UUID, _ dataModel: DataModel, _ context: CIContext) {
        let now = Date()
        guard now.timeIntervalSince(lastThumbnailRenderTime) >= thumbnailThrottleInterval else {
            return
        }
        lastThumbnailRenderTime = now

        DispatchQueue.global(qos: .userInitiated).async {

            let cgImage = image.convertThumbToCGImageSync()

            DispatchQueue.main.async {
                dataModel.updateItem(id: id) { item in
                    item.thumbnailImage = cgImage
                }
            }
        }
    }
    
   
    
 

    
    public var destinationUrl: URL?
    
    

    
    func unwrapAndReturnImagesSync( _ item: ImageItem, _ dataModel: DataModel) -> CIImage? {
        
        /*
         */
        
        
        let viewModel = ImageViewModel.shared
        let isZoomed = viewModel.isZoomed
        let rect = viewModel.zoomRect
        
        if isZoomed, rect.width > 0, rect.height > 0 {
            guard let smlBuffer = PixelBufferCache.shared.get(item.id) else { return nil }

            var highRes = CIImage(cvPixelBuffer: smlBuffer)
            let scaleUp = viewModel.zoomScale
            highRes = highRes.transformed(by: CGAffineTransform(scaleX: scaleUp, y: scaleUp))

            if let buffer = PixelBufferHRCache.shared.get(item.id) {
                // Use HR buffer if available
                highRes = CIImage(cvPixelBuffer: buffer)
            }
            // If no HR buffer, highRes is already the scaled-up small buffer

            let clamped = clampedRect(rect, in: highRes.extent)
            let zoomed = highRes.cropped(to: clamped)
            let translated = zoomed.transformed(by: .init(
                translationX: -rect.origin.x,
                y: -rect.origin.y
            ))
            return translated
        } else if item.isExport {
            if let pixelBuffer = PixelBufferHRCache.shared.get(item.id) {
                
                let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
                return ciImage
                
            } else {
                print("Getting full res debayered")
                
                var hr = CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
                Task {
                    guard let img = await DataModel.shared.getHR(item) else {
                        
                        print("Unwrap image failed to get CIImage from pixelbuffer")
                        
                        return
                    }
                    
                    hr = img
                }
                
                if hr.extent.width > 2.0 {
                    return hr
                }
            }
            
        } else if ImageViewModel.shared.imageViewActive == false {

            if item.thumbBuffer == nil {
                if let medBuffer = item.debayeredBuffer {
                    let ciImage = CIImage(cvPixelBuffer: medBuffer)
                    let scale = 500.0 / max(ciImage.extent.width, ciImage.extent.height)
                    let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                    guard let smlBuffer = scaled.convertDebayeredToBufferSync() else {return nil}
                    
                    DispatchQueue.main.async {
                        dataModel.updateItem(id: item.id) {item in
                            item.thumbBuffer = smlBuffer
                        }
                    }
                    return CIImage(cvPixelBuffer: smlBuffer)
                }
                
                
            } else {
                if let buffer = item.thumbBuffer {
                    return CIImage(cvPixelBuffer: buffer)
                }

            }
        } else {
			if let debayeredBuffer = PixelBufferCache.shared.get(item.id) {
                
                
                let displayImage = CIImage(cvPixelBuffer: debayeredBuffer)
                
                return displayImage
                
            } else {
                
                var display = CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
                
                Task {
                    guard let img = await DataModel.shared.getDisplay(item) else {
                        
                        print("Unwrap image failed to get CIImage from pixelbuffer")
                        
                        return
                    }
                    
                    display = img
                }
                
                if display.extent.width > 2.0 {
                    return display
                }
            }
        }
        return nil
    }
    
    private func clampedRect(_ rect: CGRect, in bounds: CGRect) -> CGRect {
        var newRect = rect
        
        // Horizontal clamp
        if newRect.minX < bounds.minX {
            newRect.origin.x = bounds.minX
        }
        if newRect.maxX > bounds.maxX {
            newRect.origin.x = bounds.maxX - newRect.width
        }
        
        // Vertical clamp
        if newRect.minY < bounds.minY {
            newRect.origin.y = bounds.minY
        }
        if newRect.maxY > bounds.maxY {
            newRect.origin.y = bounds.maxY - newRect.height
        }
        
        return newRect
    }
    
    
    
}


extension FilterPipeline {
    /// Applies the pipeline to all selected IDs in ThumbnailViewModel.
    func applyPipelineForSelectedItems(_ dataModel: DataModel) async {
        let selectedIDs = ThumbnailViewModel.shared.selectedIDs
        
        guard !selectedIDs.isEmpty else {
            print("No selected items to process")
            return
        }
        
        for id in selectedIDs {
             applyPipelineV2Sync(id, dataModel)
        }
    }
}
