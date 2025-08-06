//
//  CopyPaste.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import CoreImage

struct CopyProfile {
    

    
    // MARK: - White balance
    var copy_allWhiteBalance: Bool = true
    
    var copy_temp: Bool = true
    var copy_tint: Bool = true
    
    
    // MARK: - Exposure
    var copy_allExposure: Bool = true
    
    var copy_exposure: Bool = true
    var copy_contrast: Bool = true
    var copy_saturation: Bool = true
    
    // MARK: - HDR
    var copy_allHDR: Bool = true
    
    var copy_hdrWhite: Bool = true
    var copy_hdrHighlight: Bool = true
    var copy_hdrShadow: Bool = true
    var copy_hdrBlack: Bool = true
    
    
    // MARK: - HSD
    var copy_allHSD: Bool = true
    var copy_allHue: Bool = true
    var copy_allSat: Bool = true
    var copy_allDen: Bool = true
    
    var copy_redHue: Bool = true
    var copy_redSat: Bool = true
    var copy_redDen: Bool = true
    var copy_greenHue: Bool = true
    var copy_greenSat: Bool = true
    var copy_greenDen: Bool = true
    var copy_blueHue: Bool = true
    var copy_blueSat: Bool = true
    var copy_blueDen: Bool = true
    var copy_cyanHue: Bool = true
    var copy_cyanSat: Bool = true
    var copy_cyanDen: Bool = true
    var copy_magentaHue: Bool = true
    var copy_magentaSat: Bool = true
    var copy_magentaDen: Bool = true
    var copy_yellowHue: Bool = true
    var copy_yellowSat: Bool = true
    var copy_yellowDen: Bool = true
    
    
    // MARK: - MTF Curve
    var copy_allMTF: Bool = true
    
    var copy_applyMTF: Bool = true
    var copy_mtfBlend: Bool = true
    var copy_selectedGateWidth: Bool = true
    
    
    // MARK: - Print Halation
    var copy_allPrintHalation: Bool = true
    
    var copy_printHalation_size: Bool = true
    var copy_printHalation_amount: Bool = true
    var copy_printHalation_darkenMode: Bool = true
    var copy_printHalation_apply: Bool = true
    
    
    // MARK: - Neg Conversion
    var copy_allNegConversion: Bool = true
    
    var copy_convertToNeg: Bool = true
    var copy_stockChoice: Bool = true
    
    
    // MARK: - Enlarger
    var copy_allEnlarger: Bool = true
    
    var copy_applyPrintMode: Bool = true
    var copy_bwMode: Bool = false
    var copy_enlargerExp: Bool = true
    var copy_enlargerFStop: Bool = true
    var copy_cyan: Bool = true
    var copy_magenta: Bool = true
    var copy_yellow: Bool = true
    
    
    // MARK: - Scan
    var copy_allScan: Bool = true
    
    var copy_applyScanMode: Bool = true
    var copy_applyPFE: Bool = true
    var copy_offsetRGB: Bool = true
    var copy_offsetRed: Bool = true
    var copy_offsetGreen: Bool = true
    var copy_offsetBlue: Bool = true
    var copy_scanContrast: Bool = true
    var copy_lutBlend: Bool = true
    
    
}

// MARK: - Copied Settings

struct CopiedImageSettings {
    // Raw fields for selected settings
    var temp: Float?
    var tint: Float?

    var exposure: Float?
    var contrast: Float?
    var saturation: Float?

    var hdrWhite: Float?
    var hdrHighlight: Float?
    var hdrShadow: Float?
    var hdrBlack: Float?

    var redHue: Float?
    var redSat: Float?
    var redDen: Float?
    var greenHue: Float?
    var greenSat: Float?
    var greenDen: Float?
    var blueHue: Float?
    var blueSat: Float?
    var blueDen: Float?
    var cyanHue: Float?
    var cyanSat: Float?
    var cyanDen: Float?
    var magentaHue: Float?
    var magentaSat: Float?
    var magentaDen: Float?
    var yellowHue: Float?
    var yellowSat: Float?
    var yellowDen: Float?

    var applyMTF: Bool?
    var mtfBlend: Float?
    var selectedGateWidth: Int?

    var printHalationSize: Float?
    var printHalationAmount: Float?
    var printHalationDarkenMode: Bool?
    var printHalationApply: Bool?

    var convertToNeg: Bool?
    var stockChoice: Int?

    var applyPrintMode: Bool?
    var bwMode: Bool?
    var enlargerExp: Float?
    var enlargerFStop: Float?
    var cyan: Float?
    var magenta: Float?
    var yellow: Float?

    var applyScanMode: Bool?
    var applyPFE: Bool?
    var offsetRGB: Float?
    var offsetRed: Float?
    var offsetGreen: Float?
    var offsetBlue: Float?
    var scanContrast: Float?
    var lutBlend: Float?
}


// MARK: - Copy / Paste Functions


extension CopiedImageSettings {
    init(from item: ImageItem, using profile: CopyProfile) {
        if profile.copy_temp { self.temp = item.temp }
        if profile.copy_tint { self.tint = item.tint }

        if profile.copy_exposure { self.exposure = item.exposure }
        if profile.copy_contrast { self.contrast = item.contrast }
        if profile.copy_saturation { self.saturation = item.saturation }

        if profile.copy_hdrWhite { self.hdrWhite = item.hdrWhite }
        if profile.copy_hdrHighlight { self.hdrHighlight = item.hdrHighlight }
        if profile.copy_hdrShadow { self.hdrShadow = item.hdrShadow }
        if profile.copy_hdrBlack { self.hdrBlack = item.hdrBlack }

        if profile.copy_redHue { self.redHue = item.redHue }
        if profile.copy_redSat { self.redSat = item.redSat }
        if profile.copy_redDen { self.redDen = item.redDen }

        if profile.copy_greenHue { self.greenHue = item.greenHue }
        if profile.copy_greenSat { self.greenSat = item.greenSat }
        if profile.copy_greenDen { self.greenDen = item.greenDen }

        if profile.copy_blueHue { self.blueHue = item.blueHue }
        if profile.copy_blueSat { self.blueSat = item.blueSat }
        if profile.copy_blueDen { self.blueDen = item.blueDen }

        if profile.copy_cyanHue { self.cyanHue = item.cyanHue }
        if profile.copy_cyanSat { self.cyanSat = item.cyanSat }
        if profile.copy_cyanDen { self.cyanDen = item.cyanDen }

        if profile.copy_magentaHue { self.magentaHue = item.magentaHue }
        if profile.copy_magentaSat { self.magentaSat = item.magentaSat }
        if profile.copy_magentaDen { self.magentaDen = item.magentaDen }

        if profile.copy_yellowHue { self.yellowHue = item.yellowHue }
        if profile.copy_yellowSat { self.yellowSat = item.yellowSat }
        if profile.copy_yellowDen { self.yellowDen = item.yellowDen }

        if profile.copy_applyMTF { self.applyMTF = item.applyMTF }
        if profile.copy_mtfBlend { self.mtfBlend = item.mtfBlend }
        if profile.copy_selectedGateWidth { self.selectedGateWidth = item.selectedGateWidth }

        if profile.copy_printHalation_size { self.printHalationSize = item.printHalation_size }
        if profile.copy_printHalation_amount { self.printHalationAmount = item.printHalation_amount }
        if profile.copy_printHalation_darkenMode { self.printHalationDarkenMode = item.printHalation_darkenMode }
        if profile.copy_printHalation_apply { self.printHalationApply = item.printHalation_apply }

        if profile.copy_convertToNeg { self.convertToNeg = item.convertToNeg }
        if profile.copy_stockChoice { self.stockChoice = item.stockChoice }

        if profile.copy_applyPrintMode { self.applyPrintMode = item.applyPrintMode }
        if profile.copy_bwMode { self.bwMode = item.bwMode }
        if profile.copy_enlargerExp { self.enlargerExp = item.enlargerExp }
        if profile.copy_enlargerFStop { self.enlargerFStop = item.enlargerFStop }
        if profile.copy_cyan { self.cyan = item.cyan }
        if profile.copy_magenta { self.magenta = item.magenta }
        if profile.copy_yellow { self.yellow = item.yellow }

        if profile.copy_applyScanMode { self.applyScanMode = item.applyScanMode }
        if profile.copy_applyPFE { self.applyPFE = item.applyPFE }
        if profile.copy_offsetRGB { self.offsetRGB = item.offsetRGB }
        if profile.copy_offsetRed { self.offsetRed = item.offsetRed }
        if profile.copy_offsetGreen { self.offsetGreen = item.offsetGreen }
        if profile.copy_offsetBlue { self.offsetBlue = item.offsetBlue }
        if profile.copy_scanContrast { self.scanContrast = item.scanContrast }
        if profile.copy_lutBlend { self.lutBlend = item.lutBlend }
    }
}


extension CopiedImageSettings {
    func apply(to item: inout ImageItem) {
        if let temp = self.temp { item.temp = temp }
        if let tint = self.tint { item.tint = tint }

        if let exposure = self.exposure { item.exposure = exposure }
        if let contrast = self.contrast { item.contrast = contrast }
        if let saturation = self.saturation { item.saturation = saturation }

        if let hdrWhite = self.hdrWhite { item.hdrWhite = hdrWhite }
        if let hdrHighlight = self.hdrHighlight { item.hdrHighlight = hdrHighlight }
        if let hdrShadow = self.hdrShadow { item.hdrShadow = hdrShadow }
        if let hdrBlack = self.hdrBlack { item.hdrBlack = hdrBlack }

        if let redHue = self.redHue { item.redHue = redHue }
        if let redSat = self.redSat { item.redSat = redSat }
        if let redDen = self.redDen { item.redDen = redDen }

        if let greenHue = self.greenHue { item.greenHue = greenHue }
        if let greenSat = self.greenSat { item.greenSat = greenSat }
        if let greenDen = self.greenDen { item.greenDen = greenDen }

        if let blueHue = self.blueHue { item.blueHue = blueHue }
        if let blueSat = self.blueSat { item.blueSat = blueSat }
        if let blueDen = self.blueDen { item.blueDen = blueDen }

        if let cyanHue = self.cyanHue { item.cyanHue = cyanHue }
        if let cyanSat = self.cyanSat { item.cyanSat = cyanSat }
        if let cyanDen = self.cyanDen { item.cyanDen = cyanDen }

        if let magentaHue = self.magentaHue { item.magentaHue = magentaHue }
        if let magentaSat = self.magentaSat { item.magentaSat = magentaSat }
        if let magentaDen = self.magentaDen { item.magentaDen = magentaDen }

        if let yellowHue = self.yellowHue { item.yellowHue = yellowHue }
        if let yellowSat = self.yellowSat { item.yellowSat = yellowSat }
        if let yellowDen = self.yellowDen { item.yellowDen = yellowDen }

        if let applyMTF = self.applyMTF { item.applyMTF = applyMTF }
        if let mtfBlend = self.mtfBlend { item.mtfBlend = mtfBlend }
        if let selectedGateWidth = self.selectedGateWidth { item.selectedGateWidth = selectedGateWidth }

        if let printHalationSize = self.printHalationSize { item.printHalation_size = printHalationSize }
        if let printHalationAmount = self.printHalationAmount { item.printHalation_amount = printHalationAmount }
        if let printHalationDarkenMode = self.printHalationDarkenMode { item.printHalation_darkenMode = printHalationDarkenMode }
        if let printHalationApply = self.printHalationApply { item.printHalation_apply = printHalationApply }

        if let convertToNeg = self.convertToNeg { item.convertToNeg = convertToNeg }
        if let stockChoice = self.stockChoice { item.stockChoice = stockChoice }

        if let applyPrintMode = self.applyPrintMode { item.applyPrintMode = applyPrintMode }
        if let bwMode = self.bwMode { item.bwMode = bwMode }
        if let enlargerExp = self.enlargerExp { item.enlargerExp = enlargerExp }
        if let enlargerFStop = self.enlargerFStop { item.enlargerFStop = enlargerFStop }
        if let cyan = self.cyan { item.cyan = cyan }
        if let magenta = self.magenta { item.magenta = magenta }
        if let yellow = self.yellow { item.yellow = yellow }

        if let applyScanMode = self.applyScanMode { item.applyScanMode = applyScanMode }
        if let applyPFE = self.applyPFE { item.applyPFE = applyPFE }
        if let offsetRGB = self.offsetRGB { item.offsetRGB = offsetRGB }
        if let offsetRed = self.offsetRed { item.offsetRed = offsetRed }
        if let offsetGreen = self.offsetGreen { item.offsetGreen = offsetGreen }
        if let offsetBlue = self.offsetBlue { item.offsetBlue = offsetBlue }
        if let scanContrast = self.scanContrast { item.scanContrast = scanContrast }
        if let lutBlend = self.lutBlend { item.lutBlend = lutBlend }
    }
}
