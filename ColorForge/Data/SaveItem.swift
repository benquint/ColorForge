//
//  SaveItem.swift
//  ColorForge
//
//  Created by Ben Quinton on 07/08/2025.
//


import Foundation
import CoreImage
import CoreGraphics
import SwiftUI



// Save functions
extension ImageItem {
    func toSaveItem() -> SaveItem {
        SaveItem.from(self)
    }
    
    func toDisk() {
        let saveItem = self.toSaveItem()
        let appData = AppDataManager.shared
        appData.saveSettings(for: saveItem)
    }

}

extension SaveItem {
    static func from(_ imageItem: ImageItem) -> SaveItem {
        return SaveItem(

            id: imageItem.id,
            url: imageItem.url,
            importDate: imageItem.importDate,
            
            saveScale: imageItem.saveScale,
            bitDepth: imageItem.bitDepth,
            fileType: imageItem.fileType,
            
            applyTHOG: imageItem.applyTHOG,
            blend: imageItem.blend,
            variance: imageItem.variance,
            scale: imageItem.scale,
            
            xyChromaticity: imageItem.xyChromaticity,
            temp: imageItem.temp,
            tint: imageItem.tint,
            initTemp: imageItem.initTemp,
            initTint: imageItem.initTint,
            
            baselineExposure: imageItem.baselineExposure,
            exposure: imageItem.exposure,
            contrast: imageItem.contrast,
            saturation: imageItem.saturation,
            
            hdrWhite: imageItem.hdrWhite,
            hdrHighlight: imageItem.hdrHighlight,
            hdrShadow: imageItem.hdrShadow,
            hdrBlack: imageItem.hdrBlack,
            
            redHue: imageItem.redHue,
            redSat: imageItem.redSat,
            redDen: imageItem.redDen,
            greenHue: imageItem.greenHue,
            greenSat: imageItem.greenSat,
            greenDen: imageItem.greenDen,
            blueHue: imageItem.blueHue,
            blueSat: imageItem.blueSat,
            blueDen: imageItem.blueDen,
            cyanHue: imageItem.cyanHue,
            cyanSat: imageItem.cyanSat,
            cyanDen: imageItem.cyanDen,
            magentaHue: imageItem.magentaHue,
            magentaSat: imageItem.magentaSat,
            magentaDen: imageItem.magentaDen,
            yellowHue: imageItem.yellowHue,
            yellowSat: imageItem.yellowSat,
            yellowDen: imageItem.yellowDen,
            
            
            applyMTF: imageItem.applyMTF,
            mtfBlend: imageItem.mtfBlend,
            applyGrain: imageItem.applyGrain,
            grainAmount: imageItem.grainAmount,
            selectedGateWidth: imageItem.selectedGateWidth,
            scaleGrainToFormat: imageItem.scaleGrainToFormat,
            

            printHalation_size: imageItem.printHalation_size,
            printHalation_amount: imageItem.printHalation_amount,
            printHalation_darkenMode: imageItem.printHalation_darkenMode,
            printHalation_apply: imageItem.printHalation_apply,

            convertToNeg: imageItem.convertToNeg,
            stockChoice: imageItem.stockChoice,

            applyPrintMode: imageItem.applyPrintMode,
            bwMode: imageItem.bwMode,
            useLegacy: imageItem.useLegacy,

            enlargerExp: imageItem.enlargerExp,
            enlargerFStop: imageItem.enlargerFStop,
            cyan: imageItem.cyan,
            magenta: imageItem.magenta,
            yellow: imageItem.yellow,

            applyFlash: imageItem.applyFlash,
            previewFlash: imageItem.previewFlash,
            flashEV: imageItem.flashEV,
            flashFStop: imageItem.flashFStop,
            flashCyan: imageItem.flashCyan,
            flashMagenta: imageItem.flashMagenta,
            flashYellow: imageItem.flashYellow,
            
            legacyExposure: imageItem.legacyExposure,
            legacyCyan: imageItem.legacyCyan,
            legacyMagenta: imageItem.legacyMagenta,
            legacyYellow: imageItem.legacyYellow,
            legacyBWMode: imageItem.legacyBWMode,

            applyScanMode: imageItem.applyScanMode,
            applyPFE: imageItem.applyPFE,
            offsetRGB: imageItem.offsetRGB,
            offsetRed: imageItem.offsetRed,
            offsetGreen: imageItem.offsetGreen,
            offsetBlue: imageItem.offsetBlue,
            scanContrast: imageItem.scanContrast,
            lutBlend: imageItem.lutBlend,

            showPaperMask: imageItem.showPaperMask,
            borderImgScale: imageItem.borderImgScale,
            borderScale: imageItem.borderScale,
            borderXshift: imageItem.borderXshift,
            borderYshift: imageItem.borderYshift,

            maskSettings: imageItem.maskSettings
        )
    }
}

struct SaveItem: Codable, Equatable {
    let id: UUID
    let url: URL
    var importDate: Date

    
    // MARK: - Save Variables
    var saveScale: Float = 1.0
    var bitDepth: Int = 16
    var fileType: String = "tiff"
    
    
    // MARK: - FP100
    var applyTHOG: Bool = false
    var blend: Float = 100.0
    var variance: Float = 50
    var scale: Float = 30.0


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


    // MARK: - Equatable
    static func == (lhs: SaveItem, rhs: SaveItem) -> Bool {
        lhs.id == rhs.id  && lhs.url == rhs.url
    }
}
