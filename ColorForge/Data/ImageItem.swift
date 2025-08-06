import Foundation
import CoreImage
import CoreGraphics
import SwiftUI

enum GradientMaskType: String, Codable, Equatable {
    case linear
    case radial
}

struct ImageItem: Identifiable, Equatable {
	let id: UUID
	let url: URL
    
    var isExport: Bool = false
    
    // MARK: - Object Data
    
    
    var importDate: Date
    var captureDate: Date
    var nativeWidth: Int = 0
    var nativeHeight: Int = 0
    var nativeRotation: Int = 1
    var uiScale: Float = 0.2
    
    
    // MARK: - Save Variables
    var isSaved: Bool = false
    var saveScale: Float = 1.0
    var bitDepth: Int = 16
    var fileType: String = "tiff"
    
    
    
    // MARK: - MetaData
    var exifDict: [CFString: Any]? = nil
    var iptcDict: [CFString: Any]? = nil
    var gpsDict: [CFString: Any]? = nil
    

	// MARK: - Images
	var debayeredInit: CIImage? = nil
    var debayeredBuffer: CVPixelBuffer? = nil
    var debayeredFull: CIImage? = nil
    var debayeredFullBuffer: CVPixelBuffer? = nil
	var debayeredThumb: CIImage? = nil
	var thumbCIImage: CIImage? = nil
    var thumbBuffer: CVPixelBuffer? = nil
	var processImage: CIImage? = nil
	var thumbnailImage: NSImage? = nil
	var previewImage: NSImage? = nil
	var fullResCiImage: CIImage? = nil
    
    var uiGrainHigh: CIImage? = nil
    var uiGrainLow: CIImage? = nil
    
    // MARK: - FP100
    var applyTHOG: Bool = false
    var blend: Float = 100.0
    var variance: Float = 50
    var scale: Float = 30.0
    
    
    // MARK: - Tom Filters
    var applyTom: Bool = false

    // MARK: - Grain
    var grainPlatesLoaded: Bool = false
    
    var grain54_low: CIImage? = nil {
        didSet {
            print("5x4 grain loaded")
        }
    }
    var grain54_high: CIImage? = nil      // 127mm (Large Format 5x4)

    var grain60mm_low: CIImage? = nil{
        didSet {
            print("Medium format grain loaded")
        }
    }
    var grain60mm_high: CIImage? = nil    // 60mm (Medium Format)

    var grain53mm_low: CIImage? = nil{
        didSet {
            print("Crop medium format grain loaded")
        }
    }
    var grain53mm_high: CIImage? = nil    // 43.8mm (Crop Medium Sensor)

    var grain36mm_low: CIImage? = nil
    var grain36mm_high: CIImage? = nil    // 36mm (35mm)

    var grain25mm_low: CIImage? = nil
    var grain25mm_high: CIImage? = nil    // 24.89mm (Motion Super35)

    var grain21mm_low: CIImage? = nil
    var grain21mm_high: CIImage? = nil    // 21.95mm (Motion Standard 35mm)

    var grain18mm_low: CIImage? = nil
    var grain18mm_high: CIImage? = nil    // 18mm (Half Frame)

    var grain10mm_low: CIImage? = nil
    var grain10mm_high: CIImage? = nil    // 10.26mm (Motion 16mm)

    var grain5mm_low: CIImage? = nil
    var grain5mm_high: CIImage? = nil     // 4.8mm (Motion 8mm)

    var grain6mm_low: CIImage? = nil
    var grain6mm_high: CIImage? = nil     // 5.79mm (Motion Super8)
    
    
    
    // MARK: - Hald Images
    var hald1: CIImage? = nil
    var hald2: CIImage? = nil
    var hald3: CIImage? = nil
    var hald4: CIImage? = nil
	var c1Hald: CIImage? = nil
    
    // MARK: - Lut Data
    var data1: Data? = nil
    var data2: Data? = nil
    var data3: Data? = nil
    var data4: Data? = nil
	var c1Data: Data? = nil



	// MARK: - Temperature
	var xyChromaticity: CGPoint = CGPoint(x: 0.3, y: 0.3)
	var temp: Float = 5500.0
	var tint: Float = 0.0
	var initTemp: Float = 5500.0
	var initTint: Float = 0.0

	// MARK: - Raw Adjust
	var baselineExposure: Float = 0.0
	var exposure: Float = 0.0
	var contrast: Float = 0.0
	var saturation: Float = 0.0

	// MARK: - HDR
	var hdrWhite: Float = 0.0
	var hdrHighlight: Float = 0.0
	var hdrShadow: Float = 0.0
	var hdrBlack: Float = 0.0

	// MARK: - HSD Previews
	var previewRed: Bool = false
	var previewGreen: Bool = false
	var previewBlue: Bool = false
	var previewCyan: Bool = false
	var previewMagenta: Bool = false
	var previewYellow: Bool = false

	// MARK: - HSD Values
	var redHue: Float = 0.0
	var redSat: Float = 0.0
	var redDen: Float = 0.0
	var greenHue: Float = 0.0
	var greenSat: Float = 0.0
	var greenDen: Float = 0.0
	var blueHue: Float = 0.0
	var blueSat: Float = 0.0
	var blueDen: Float = 0.0
	var cyanHue: Float = 0.0
	var cyanSat: Float = 0.0
	var cyanDen: Float = 0.0
	var magentaHue: Float = 0.0
	var magentaSat: Float = 0.0
	var magentaDen: Float = 0.0
	var yellowHue: Float = 0.0
	var yellowSat: Float = 0.0
	var yellowDen: Float = 0.0

	// MARK: - Texture
	var applyMTF: Bool = false
	var mtfBlend: Float = 50.0
	var applyGrain: Bool = false
    var grainAmount: Float = 50.0
	var selectedGateWidth: Int = 9
	var scaleGrainToFormat: Bool = false

	// MARK: - Print Halation
    var printHalation_size: Float = 10.0
    var printHalation_amount: Float = 50.0
    var printHalation_darkenMode: Bool = true
    var printHalation_apply: Bool = false

	// MARK: - Neg Conversion
	var convertToNeg: Bool = false
	var stockChoice: Int = 0

	// MARK: - Enlarger
	var applyPrintMode: Bool = false
	var bwMode: Bool = false
	var useLegacy: Bool = false
	
    var enlargerExp: Float = 12.0
	var enlargerFStop: Float = 11.0
	var cyan: Float = 0.0
    var magenta: Float = 48.0
    var yellow: Float = 87.0
	
	
	var applyFlash: Bool = false
	var previewFlash: Bool = false
	var flashEV: Float = 0.0
	var flashFStop: Float = 11.0
	var flashCyan: Float = 0.0
	var flashMagenta: Float = 0.0
	var flashYellow: Float = 0.0
	
	

	
	var legacyExposure: Float = 0.0
	var legacyCyan: Float = 0.0
	var legacyMagenta: Float = 0.0
	var legacyYellow: Float = 0.0
	var legacyBWMode: Bool = false
	
	
	
	// MARK: - Scan
	var applyScanMode: Bool = false
	var applyPFE: Bool = false
	var offsetRGB: Float = 0.0
	var offsetRed: Float = 0.0
	var offsetGreen: Float = 0.0
	var offsetBlue: Float = 0.0
	var scanContrast: Float = 0.0
	var lutBlend: Float = 100.0

    
    
	// MARK: - Border
	var showPaperMask: Bool = false
	var borderImgScale: CGFloat = 1.0
	var borderScale: CGFloat = 1.0
	var borderXshift: CGFloat = 0.0
	var borderYshift: CGFloat = 0.0
    
    
    
    
    
    
    
    
    
    
	// MARK: - Masks
	var maskSettings: MaskSettings = MaskSettings()

    struct MaskSettings: Codable, Equatable {
        var linearGradients: [LinearGradientMask] = []
        var radialGradients: [RadialGradientMask] = []
        
        var selectedMaskID: UUID?
        var selectedMaskType: GradientMaskType?
        
        var settingsByMaskID: [UUID: MaskParameterSet] = [:]
        
        init(
            linearGradients: [LinearGradientMask] = [],
            radialGradients: [RadialGradientMask] = [],
            selectedMaskID: UUID? = nil,
            selectedMaskType: GradientMaskType? = nil,
            settingsByMaskID: [UUID: MaskParameterSet] = [:]
        ) {
            self.linearGradients = linearGradients
            self.radialGradients = radialGradients
            self.selectedMaskID = selectedMaskID
            self.selectedMaskType = selectedMaskType
            self.settingsByMaskID = settingsByMaskID
        }
    }
    
    
    // MARK: - Mask parameters
    
    struct MaskParameterSet: Codable, Equatable {
        
        
        // MARK: - TempAndTintNode
        var xyChromaticity: CGPoint = CGPoint(x: 0.3, y: 0.3)
        var temp: Float = 5500.0
        var tint: Float = 0.0
        var initTemp: Float = 5500.0
        var initTint: Float = 0.0
        
        
        // MARK: - RawExposureNode
        var exposure: Float = 0.0
        
        
        
        // MARK: - RawContrastNode
        var contrast: Float = 0.0
        
        
        // MARK: - GlobalSaturationNode
        var saturation: Float = 0.0
        

        // MARK: - HDRNode
        var hdrWhite: Float = 0.0
        var hdrHighlight: Float = 0.0
        var hdrShadow: Float = 0.0
        var hdrBlack: Float = 0.0
        
    
        // MARK: - HueSaturationDensityNode
        var redHue: Float = 0.0
        var redSat: Float = 0.0
        var redDen: Float = 0.0
        var greenHue: Float = 0.0
        var greenSat: Float = 0.0
        var greenDen: Float = 0.0
        var blueHue: Float = 0.0
        var blueSat: Float = 0.0
        var blueDen: Float = 0.0
        var cyanHue: Float = 0.0
        var cyanSat: Float = 0.0
        var cyanDen: Float = 0.0
        var magentaHue: Float = 0.0
        var magentaSat: Float = 0.0
        var magentaDen: Float = 0.0
        var yellowHue: Float = 0.0
        var yellowSat: Float = 0.0
        var yellowDen: Float = 0.0

        
        // MARK: - Print Halation
        var printHalation_size: Float = 10.0
        var printHalation_amount: Float = 50.0
        var printHalation_darkenMode: Bool = true
        var printHalation_apply: Bool = false
	
        
        
        // MARK: - EnlargerV2Node
		var enlargerExp: Float = 0.0
        var enlargerFStop: Float = 11.0
        var cyan: Float = 0.0
		var magenta: Float = 0.0
		var yellow: Float = 0.0
        var applyFlash: Bool = false


        
        // MARK: - LegacyEnlargerNode
        var legacyExposure: Float = 0.0
        var legacyCyan: Float = 0.0
        var legacyMagenta: Float = 0.0
        var legacyYellow: Float = 0.0
        
        
        // MARK: - Scan - dont do this yet
        var applyPFE: Bool = false
        var offsetRGB: Float = 0.0
        var offsetRed: Float = 0.0
        var offsetGreen: Float = 0.0
        var offsetBlue: Float = 0.0
        var scanContrast: Float = 0.0
        var lutBlend: Float = 100.0
        
        
        // MARK: - Shared - dont observe these changes when marking which node to apply
        var useLegacy: Bool = false
        var bwMode: Bool = false
        var applyPrintMode: Bool = false
        var applyScanMode: Bool = false
        var convertToNeg: Bool = false
        
        
        init(

            
            xyChromaticity: CGPoint = CGPoint(x: 0.3, y: 0.3),
            temp: Float = 5500.0,
            tint: Float = 0.0,
            initTemp: Float = 5500.0,
            initTint: Float = 0.0,
            
            
            exposure: Float = 0.0,
            contrast: Float = 0.0,
            saturation: Float = 0.0,


            hdrWhite: Float = 0.0,
            hdrHighlight: Float = 0.0,
            hdrShadow: Float = 0.0,
            hdrBlack: Float = 0.0,
            
            

            redHue: Float = 0.0,
            redSat: Float = 0.0,
            redDen: Float = 0.0,
            greenHue: Float = 0.0,
            greenSat: Float = 0.0,
            greenDen: Float = 0.0,
            blueHue: Float = 0.0,
            blueSat: Float = 0.0,
            blueDen: Float = 0.0,
            cyanHue: Float = 0.0,
            cyanSat: Float = 0.0,
            cyanDen: Float = 0.0,
            magentaHue: Float = 0.0,
            magentaSat: Float = 0.0,
            magentaDen: Float = 0.0,
            yellowHue: Float = 0.0,
            yellowSat: Float = 0.0,
            yellowDen: Float = 0.0,


            printHalation_size: Float = 10.0,
            printHalation_amount: Float = 50.0,
            printHalation_darkenMode: Bool = true,
            printHalation_apply: Bool = false,
            
            
            convertToNeg: Bool = false,

            

            applyPrintMode: Bool = false,
            enlargerExp: Float = 0.0,
            enlargerFStop: Float = 11.0,
            bwMode: Bool = false,
            cyan: Float = 0.0,
            magenta: Float = 0.0,
            yellow: Float = 0.0,
            applyFlash: Bool = false,
            useLegacy: Bool = false,
            
            legacyExposure: Float = 0.0,
            legacyCyan: Float = 0.0,
            legacyMagenta: Float = 0.0,
            legacyYellow: Float = 0.0,


            applyScanMode: Bool = false,
            applyPFE: Bool = false,
            offsetRGB: Float = 0.0,
            offsetRed: Float = 0.0,
            offsetGreen: Float = 0.0,
            offsetBlue: Float = 0.0,
            scanContrast: Float = 0.0,
            lutBlend: Float = 100.0
            
        ) {


            self.xyChromaticity = xyChromaticity
            self.temp = temp
            self.tint = tint
            self.initTemp = initTemp
            self.initTint = initTint
            
            
            
            self.exposure = exposure
            self.contrast = contrast
            self.saturation = saturation
            
            self.convertToNeg = convertToNeg
            
            self.hdrWhite = hdrWhite
            self.hdrHighlight = hdrHighlight
            self.hdrShadow = hdrShadow
            self.hdrBlack = hdrBlack
            
            
            self.redHue = redHue
            self.redSat = redSat
            self.redDen = redDen
            self.greenHue = greenHue
            self.greenSat = greenSat
            self.greenDen = greenDen
            self.blueHue = blueHue
            self.blueSat = blueSat
            self.blueDen = blueDen
            self.cyanHue = cyanHue
            self.cyanSat = cyanSat
            self.cyanDen = cyanDen
            self.magentaHue = magentaHue
            self.magentaSat = magentaSat
            self.magentaDen = magentaDen
            self.yellowHue = yellowHue
            self.yellowSat = yellowSat
            self.yellowDen = yellowDen
            
            
            self.printHalation_size = printHalation_size
            self.printHalation_amount = printHalation_amount
            self.printHalation_darkenMode = printHalation_darkenMode
            self.printHalation_apply = printHalation_apply
            
            
            
            
            self.applyPrintMode = applyPrintMode
            self.enlargerExp = enlargerExp
            self.enlargerFStop = enlargerFStop
            self.bwMode = bwMode
            self.cyan = cyan
            self.magenta = magenta
            self.yellow = yellow
            self.applyFlash = applyFlash
            self.useLegacy = useLegacy
            
            self.legacyExposure = legacyExposure
            self.legacyCyan = legacyCyan
            self.legacyMagenta = legacyMagenta
            self.legacyYellow = legacyYellow
            
            
            self.applyScanMode = applyScanMode
            self.applyPFE = applyPFE
            self.offsetRGB = offsetRGB
            self.offsetRed = offsetRed
            self.offsetGreen = offsetGreen
            self.offsetBlue = offsetBlue
            self.scanContrast = scanContrast
            self.lutBlend = lutBlend
        }
    }

	struct LinearGradientMask: Identifiable, Codable, Equatable, Hashable {
		let id: UUID
		var name: String
		var startPoint: CGPoint
		var endPoint: CGPoint
		var invert: Bool
		var opacity: Float
		
		
		init(
			id: UUID = UUID(),
			name: String,
			startPoint: CGPoint,
			endPoint: CGPoint,
			invert: Bool = false,
			opacity: Float = 1.0
			
		) {
			self.id = id
			self.name = name
			self.startPoint = startPoint
			self.endPoint = endPoint
			self.invert = invert
			self.opacity = opacity
		}
		
	}
    
    // MARK: - Radial Gradients
    struct RadialGradientMask: Identifiable, Codable, Equatable, Hashable {
        let id: UUID
        var name: String
        var startPoint: CGPoint
        var endPoint: CGPoint // radius 1, where the inner color ends and outer color starts, aka softness
        var feather: Float // Blur amount (0-100) deafult 50, calulated as: gradientWidth / 100 * feather
        var width: CGFloat
        var height: CGFloat
        var rotation: Float
        var invert: Bool
        var opacity: Float
        
        
        
        init(
            id: UUID = UUID(),
            name: String,
            startPoint: CGPoint,
            endPoint: CGPoint,
            feather: Float = 50.0,
            width: CGFloat = 1.0,
            height: CGFloat = 1.0,
            rotation: Float = 0.0,
            invert: Bool = false,
            opacity: Float = 100
        ) {
            self.id = id
            self.name = name
            self.startPoint = startPoint
            self.endPoint = endPoint
            self.feather = feather
            self.width = width
            self.height = height
            self.rotation = rotation
            self.invert = invert
            self.opacity = opacity
        }
        
    }

	// MARK: - Init
	init(
		// MARK: - Identity
		id: UUID = UUID(),
		url: URL,
        
        isExport: Bool = false,

		// MARK: - Images
		debayeredInit: CIImage? = nil,
        debayeredBuffer: CVPixelBuffer? = nil,
        debayeredFull: CIImage? = nil,
        debayeredFullBuffer: CVPixelBuffer? = nil,
		debayeredThumb: CIImage? = nil,
		thumbCIImage: CIImage? = nil,
        thumbBuffer: CVPixelBuffer? = nil,
		processImage: CIImage? = nil,
		thumbnailImage: NSImage? = nil,
		previewImage: NSImage? = nil,
		fullResCiImage: CIImage? = nil,
        
        uiGrainHigh: CIImage? = nil,
        uiGrainLow: CIImage? = nil,
        exportGrainHigh: CIImage? = nil,
        exportGrainLow: CIImage? = nil,
        
        applyTHOG: Bool = false,
        blend: Float = 100.0,
        variance: Float = 50,
        scale: Float = 30.0,
        
        
    // MARK: - MetaData
        exifDict: [CFString: Any]? = nil,
        iptcDict: [CFString: Any]? = nil,
        gpsDict: [CFString: Any]? = nil,
        
        
        // Grain by gate width (Low / High pairs)
        grainPlatesLoaded: Bool = false,
        
        grain54_low: CIImage? = nil,
        grain54_high: CIImage? = nil,      // 127mm (Large Format 5×4)

        grain60mm_low: CIImage? = nil,
        grain60mm_high: CIImage? = nil,    // 60mm (Medium Format)

        grain53mm_low: CIImage? = nil,
        grain53mm_high: CIImage? = nil,    // 43.8mm (Crop Medium Sensor)

        grain36mm_low: CIImage? = nil,
        grain36mm_high: CIImage? = nil,    // 36mm (35mm)

        grain25mm_low: CIImage? = nil,
        grain25mm_high: CIImage? = nil,    // 24.89mm (Motion Super35)

        grain21mm_low: CIImage? = nil,
        grain21mm_high: CIImage? = nil,    // 21.95mm (Motion Standard 35mm)

        grain18mm_low: CIImage? = nil,
        grain18mm_high: CIImage? = nil,    // 18mm (Half Frame)

        grain10mm_low: CIImage? = nil,
        grain10mm_high: CIImage? = nil,    // 10.26mm (Motion 16mm)

        grain5mm_low: CIImage? = nil,
        grain5mm_high: CIImage? = nil,     // 4.8mm (Motion 8mm)

        grain6mm_low: CIImage? = nil,
        grain6mm_high: CIImage? = nil,      // 5.79mm (Motion Super8)
        
        
        hald1: CIImage? = nil,
        hald2: CIImage? = nil,
        hald3: CIImage? = nil,
        hald4: CIImage? = nil,
		c1Hald: CIImage? = nil,
        
        data1: Data? = nil,
        data2: Data? = nil,
        data3: Data? = nil,
        data4: Data? = nil,
		c1Data: Data? = nil,
        
        
        // MARK: - Tom
        applyTom: Bool = false,
        

		// MARK: - Object Data
		importDate: Date,
		captureDate: Date,
		nativeWidth: Int = 0,
		nativeHeight: Int = 0,
		nativeRotation: Int = 1,
        uiScale: Float = 0.2,
        
        
        // MARK: - Save Variables
        isSaved: Bool = false,
        saveScale: Float = 1.0,
        bitDepth: Int = 16,
        fileType: String = "tiff",
    

		// MARK: - Temperature
		xyChromaticity: CGPoint = CGPoint(x: 0.3, y: 0.3),
		temp: Float = 5500.0,
		tint: Float = 0.0,
		initTemp: Float = 5500.0,
		initTint: Float = 0.0,

		// MARK: - Raw Adjust
		baselineExposure: Float = 0.0,
		exposure: Float = 0.0,
		contrast: Float = 0.0,
		saturation: Float = 0.0,

		// MARK: - HDR
		hdrWhite: Float = 0.0,
		hdrHighlight: Float = 0.0,
		hdrShadow: Float = 0.0,
		hdrBlack: Float = 0.0,

		// MARK: - HSD Previews
		previewRed: Bool = false,
		previewGreen: Bool = false,
		previewBlue: Bool = false,
		previewCyan: Bool = false,
		previewMagenta: Bool = false,
		previewYellow: Bool = false,

		// MARK: - HSD Values
		redHue: Float = 0.0,
		redSat: Float = 0.0,
		redDen: Float = 0.0,
		greenHue: Float = 0.0,
		greenSat: Float = 0.0,
		greenDen: Float = 0.0,
		blueHue: Float = 0.0,
		blueSat: Float = 0.0,
		blueDen: Float = 0.0,
		cyanHue: Float = 0.0,
		cyanSat: Float = 0.0,
		cyanDen: Float = 0.0,
		magentaHue: Float = 0.0,
		magentaSat: Float = 0.0,
		magentaDen: Float = 0.0,
		yellowHue: Float = 0.0,
		yellowSat: Float = 0.0,
		yellowDen: Float = 0.0,

		// MARK: - Texture
		applyMTF: Bool = false,
		mtfBlend: Float = 50.0,
		applyGrain: Bool = false,
        grainAmount: Float = 50.0,
		selectedGateWidth: Int = 9,
		scaleGrainToFormat: Bool = false,
		
		showPaperMask: Bool = false,
		borderImgScale: CGFloat = 1.0,
		borderScale: CGFloat = 1.0,
		borderXshift: CGFloat = 0.0,
		borderYshift: CGFloat = 0.0,

		// MARK: - Print Halation
        printHalation_size: Float = 10.0,
        printHalation_amount: Float = 50.0,
        printHalation_darkenMode: Bool = true,
        printHalation_apply: Bool = false,

		// MARK: - Neg Conversion
		convertToNeg: Bool = false,
		stockChoice: Int = 0,

		// MARK: - Enlarger
		applyPrintMode: Bool = false,
        enlargerExp: Float = 12.0,
		enlargerFStop: Float = 11.0,
		bwMode: Bool = false,
		cyan: Float = 0.0,
		magenta: Float = 48.0,
		yellow: Float = 80.0,
		useLegacy: Bool = false,
		
		
		// MARK: - Print Flash
		
		applyFlash: Bool = false,
		previewFlash: Bool = false,
		flashEV: Float = 0.0,
		flashFStop: Float = 11.0,
		flashCyan: Float = 0.0,
		flashMagenta: Float = 0.0,
		
		
		
		// MARK: - Legacy Enlarger
		legacyExposure: Float = 0.0,
		legacyCyan: Float = 0.0,
		legacyMagenta: Float = 0.0,
		legacyYellow: Float = 0.0,
		legacyBWMode: Bool = false,

		// MARK: - Scan
		applyScanMode: Bool = false,
		applyPFE: Bool = false,
		offsetRGB: Float = 0.0,
		offsetRed: Float = 0.0,
		offsetGreen: Float = 0.0,
		offsetBlue: Float = 0.0,
		scanContrast: Float = 0.0,
		lutBlend: Float = 100.0,

		// MARK: - Masks
		maskSettings: MaskSettings = MaskSettings()
	) {
		self.id = id
		self.url = url
        
        self.isExport = isExport
        
		self.debayeredInit = debayeredInit
        self.debayeredBuffer = debayeredBuffer
        self.debayeredFull = debayeredFull
        self.debayeredFullBuffer = debayeredFullBuffer
		self.debayeredThumb = debayeredThumb
		self.thumbCIImage = thumbCIImage
        self.thumbBuffer = thumbBuffer
		self.processImage = processImage
		self.previewImage = previewImage
		self.thumbnailImage = thumbnailImage
		self.fullResCiImage = fullResCiImage
        
        self.applyTHOG = applyTHOG
        self.blend = blend
        self.variance = variance
        self.scale = scale
        
        
        self.exifDict = exifDict
        self.iptcDict = iptcDict
        self.gpsDict = gpsDict
        
        self.uiGrainHigh = uiGrainHigh
        self.uiGrainLow = uiGrainLow
        
        // Grain by gate width (Low / High pairs)
        
        self.grainPlatesLoaded = grainPlatesLoaded
        self.grain54_low = grain54_low
        self.grain54_high = grain54_high        // 127mm (Large Format 5×4)

        self.grain60mm_low = grain60mm_low
        self.grain60mm_high = grain60mm_high    // 60mm (Medium Format)

        self.grain53mm_low = grain53mm_low
        self.grain53mm_high = grain53mm_high    // 43.8mm (Crop Medium Sensor)

        self.grain36mm_low = grain36mm_low
        self.grain36mm_high = grain36mm_high    // 36mm (35mm)

        self.grain25mm_low = grain25mm_low
        self.grain25mm_high = grain25mm_high    // 24.89mm (Motion Super35)

        self.grain21mm_low = grain21mm_low
        self.grain21mm_high = grain21mm_high    // 21.95mm (Motion Standard 35mm)

        self.grain18mm_low = grain18mm_low
        self.grain18mm_high = grain18mm_high    // 18mm (Half Frame)

        self.grain10mm_low = grain10mm_low
        self.grain10mm_high = grain10mm_high    // 10.26mm (Motion 16mm)

        self.grain5mm_low = grain5mm_low
        self.grain5mm_high = grain5mm_high      // 4.8mm (Motion 8mm)

        self.grain6mm_low = grain6mm_low
        self.grain6mm_high = grain6mm_high      // 5.79mm (Motion Super8)
        
        
        self.hald1 = hald1
        self.hald2 = hald2
        self.hald3 = hald3
        self.hald4 = hald4
		self.c1Hald = c1Hald
        self.data1 = data1
        self.data2 = data2
        self.data3 = data3
        self.data4 = data4
		self.c1Data = c1Data
		self.importDate = importDate
		self.captureDate = captureDate
		self.nativeWidth = nativeWidth
		self.nativeHeight = nativeHeight
		self.nativeRotation = nativeRotation
        self.uiScale = uiScale
        self.isSaved = isSaved
        self.saveScale = saveScale
        self.bitDepth = bitDepth
        self.fileType = fileType
		self.xyChromaticity = xyChromaticity
		self.temp = temp
		self.tint = tint
		self.initTemp = initTemp
		self.initTint = initTint
		self.baselineExposure = baselineExposure
		self.exposure = exposure
		self.contrast = contrast
		self.saturation = saturation
		self.hdrWhite = hdrWhite
		self.hdrHighlight = hdrHighlight
		self.hdrShadow = hdrShadow
		self.hdrBlack = hdrBlack
		self.previewRed = previewRed
		self.previewGreen = previewGreen
		self.previewBlue = previewBlue
		self.previewCyan = previewCyan
		self.previewMagenta = previewMagenta
		self.previewYellow = previewYellow
		self.redHue = redHue
		self.redSat = redSat
		self.redDen = redDen
		self.greenHue = greenHue
		self.greenSat = greenSat
		self.greenDen = greenDen
		self.blueHue = blueHue
		self.blueSat = blueSat
		self.blueDen = blueDen
		self.cyanHue = cyanHue
		self.cyanSat = cyanSat
		self.cyanDen = cyanDen
		self.magentaHue = magentaHue
		self.magentaSat = magentaSat
		self.magentaDen = magentaDen
		self.yellowHue = yellowHue
		self.yellowSat = yellowSat
		self.yellowDen = yellowDen
		self.applyMTF = applyMTF
		self.mtfBlend = mtfBlend
		self.applyGrain = applyGrain
		self.grainAmount = grainAmount
		self.selectedGateWidth = selectedGateWidth
		self.scaleGrainToFormat = scaleGrainToFormat
        self.printHalation_size = printHalation_size
        self.printHalation_amount = printHalation_amount
        self.printHalation_darkenMode = printHalation_darkenMode
        self.printHalation_apply = printHalation_apply
		self.convertToNeg = convertToNeg
		self.stockChoice = stockChoice
		self.applyPrintMode = applyPrintMode
		self.enlargerExp = enlargerExp
		self.enlargerFStop = enlargerFStop
		self.bwMode = bwMode
		self.cyan = cyan
		self.magenta = magenta
		self.yellow = yellow
		
		self.showPaperMask = showPaperMask
		self.borderImgScale = borderImgScale
		self.borderScale = borderScale
		self.borderXshift = borderXshift
		self.borderYshift = borderYshift
		
		self.applyFlash = applyFlash
		self.previewFlash = previewFlash
		self.flashEV = flashEV
		self.flashFStop = flashFStop
		self.flashCyan = flashCyan
		self.flashMagenta = flashMagenta
		
		
		self.useLegacy = useLegacy
		
		self.legacyExposure = legacyExposure
		self.legacyCyan = legacyCyan
		self.legacyMagenta = legacyMagenta
		self.legacyYellow = legacyYellow
		self.legacyBWMode = legacyBWMode
		
		self.applyScanMode = applyScanMode
		self.applyPFE = applyPFE
		self.offsetRGB = offsetRGB
		self.offsetRed = offsetRed
		self.offsetGreen = offsetGreen
		self.offsetBlue = offsetBlue
		self.scanContrast = scanContrast
		self.lutBlend = lutBlend
		self.maskSettings = maskSettings
        
        
        self.applyTom = applyTom
	}

	// MARK: - Equatable
	static func == (lhs: ImageItem, rhs: ImageItem) -> Bool {
		lhs.id == rhs.id  && lhs.url == rhs.url
	}
}
