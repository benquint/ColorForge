//
//  MaskSettings.swift
//  ColorForge
//
//  Created by Ben Quinton on 07/08/2025.
//

import Foundation


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
