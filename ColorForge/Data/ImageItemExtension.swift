//
//  ImageItemExtension.swift
//  ColorForge
//
//  Created by Ben Quinton on 07/08/2025.
//

import Foundation


extension ImageItem {
    
    static func from(_ item: SaveItem) -> ImageItem {
        return ImageItem(

            id: item.id,
            url: item.url,
            
            isExport: false,
            
            
            debayeredInit: nil,
            debayeredBuffer: nil,
            debayeredFull: nil,
            debayeredFullBuffer: nil,
            debayeredThumb: nil,
            thumbCIImage: nil,
            thumbBuffer: nil,
            processImage: nil,
            thumbnailImage: nil,
            previewImage: nil,
            fullResCiImage: nil,
            
            
            uiGrainHigh: nil,
            uiGrainLow: nil,
            
            
            applyTHOG: item.applyTHOG,
            blend: item.blend,
            variance: item.variance,
            scale: item.scale,
            
            
            exifDict: nil,
            iptcDict: nil,
            gpsDict: nil,
            tiffDict: nil,
            
            
            // Grain by gate width (Low / High pairs)
            grainPlatesLoaded: false,
            
            grain54_low: nil,
            grain54_high: nil,      // 127mm (Large Format 5×4)

            grain60mm_low: nil,
            grain60mm_high: nil,    // 60mm (Medium Format)

            grain53mm_low: nil,
            grain53mm_high: nil,    // 43.8mm (Crop Medium Sensor)

            grain36mm_low: nil,
            grain36mm_high: nil,    // 36mm (35mm)

            grain25mm_low: nil,
            grain25mm_high: nil,    // 24.89mm (Motion Super35)

            grain21mm_low: nil,
            grain21mm_high: nil,    // 21.95mm (Motion Standard 35mm)

            grain18mm_low: nil,
            grain18mm_high: nil,    // 18mm (Half Frame)

            grain10mm_low: nil,
            grain10mm_high: nil,    // 10.26mm (Motion 16mm)

            grain5mm_low: nil,
            grain5mm_high: nil,     // 4.8mm (Motion 8mm)

            grain6mm_low: nil,
            grain6mm_high: nil,      // 5.79mm (Motion Super8)
            
            
            hald1: nil,
            hald2: nil,
            hald3: nil,
            hald4: nil,
            c1Hald: nil,
            
            data1: nil,
            data2: nil,
            data3: nil,
            data4: nil,
            c1Data: nil,
            

            
            
            // MARK: - Tom
            applyTom: false,
            
            
            importDate: item.importDate,
            captureDate: .distantPast,
            nativeWidth: 0,
            nativeHeight: 0,
            nativeRotation: 1,
            uiScale: 0.2,
            
            isSaved: false,
            saveScale: item.saveScale,
            bitDepth: item.bitDepth,
            fileType: item.fileType,
            
            
            
            xyChromaticity: item.xyChromaticity,
            temp: item.temp,
            tint: item.tint,
            initTemp: item.initTemp,
            initTint: item.initTint,
            

            baselineExposure: item.baselineExposure,
            exposure: item.exposure,
            contrast: item.contrast,
            saturation: item.saturation,
            
            hdrWhite: item.hdrWhite,
            hdrHighlight: item.hdrHighlight,
            hdrShadow: item.hdrShadow,
            hdrBlack: item.hdrBlack,

            
            previewRed: false,
            previewGreen: false,
            previewBlue: false,
            previewCyan: false,
            previewMagenta: false,
            previewYellow: false,
            
            redHue: item.redHue,
            redSat: item.redSat,
            redDen: item.redDen,
            greenHue: item.greenHue,
            greenSat: item.greenSat,
            greenDen: item.greenDen,
            blueHue: item.blueHue,
            blueSat: item.blueSat,
            blueDen: item.blueDen,
            cyanHue: item.cyanHue,
            cyanSat: item.cyanSat,
            cyanDen: item.cyanDen,
            magentaHue: item.magentaHue,
            magentaSat: item.magentaSat,
            magentaDen: item.magentaDen,
            yellowHue: item.yellowHue,
            yellowSat: item.yellowSat,
            yellowDen: item.yellowDen,
            
            applyMTF: item.applyMTF,
            mtfBlend: item.mtfBlend,
            applyGrain: item.applyGrain,
            grainAmount: item.grainAmount,
            selectedGateWidth: item.selectedGateWidth,
            scaleGrainToFormat: item.scaleGrainToFormat,

            

            showPaperMask: item.showPaperMask,
            borderImgScale: item.borderImgScale,
            borderScale: item.borderScale,
            borderXshift: item.borderXshift,
            borderYshift: item.borderYshift,
            
 
            printHalation_size: item.printHalation_size,
            printHalation_amount: item.printHalation_amount,
            printHalation_darkenMode: item.printHalation_darkenMode,
            printHalation_apply: item.printHalation_apply,
            
            convertToNeg: item.convertToNeg,
            stockChoice: item.stockChoice,
            

            applyPrintMode: item.applyPrintMode,
            enlargerExp: item.enlargerExp,
            enlargerFStop: item.enlargerFStop,
            bwMode: item.bwMode,
            cyan: item.cyan,
            magenta: item.magenta,
            yellow: item.yellow,
            useLegacy: item.useLegacy,

            applyFlash: item.applyFlash,
            previewFlash: item.previewFlash,
            flashEV: item.flashEV,
            flashFStop: item.flashFStop,
            flashCyan: item.flashCyan,
            flashMagenta: item.flashMagenta,

            
            
            legacyExposure: item.legacyExposure,
            legacyCyan: item.legacyCyan,
            legacyMagenta: item.legacyMagenta,
            legacyYellow: item.legacyYellow,
            legacyBWMode: item.legacyBWMode,

            applyScanMode: item.applyScanMode,
            applyPFE: item.applyPFE,
            apply2383: item.apply2383,
            apply3513: item.apply3513,
            offsetRGB: item.offsetRGB,
            offsetRed: item.offsetRed,
            offsetGreen: item.offsetGreen,
            offsetBlue: item.offsetBlue,
            scanContrast: item.scanContrast,
            lutBlend: item.lutBlend,



            maskSettings: item.maskSettings

        )
    }
}
