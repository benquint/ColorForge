//
//  EmulationView.swift
//  ColorForge
//
//  Created by admin on 27/06/2025.
//

import SwiftUI

struct EmulationView: View {
    @EnvironmentObject var dataModel: DataModel
    
    // FilmStock
    @Binding var convertToNeg: Bool
    @Binding var stockChoice: Int

    // Enlarger
    @Binding var applyPrintMode: Bool
    @Binding var enlargerExp: Float
    @Binding var enlargerFStop: Float
    @Binding var bwMode: Bool
    @Binding var cyan: Float
    @Binding var magenta: Float
    @Binding var yellow: Float
    @Binding var applyFlash: Bool
    @Binding var useLegacy: Bool
    
    // Flash
    @Binding var previewFlash: Bool
    @Binding var flashEV: Float
    @Binding var flashFStop: Float
    @Binding var flashCyan: Float
    @Binding var flashMagenta: Float
    @Binding var flashYellow: Float

    // Scan - TBC
    @Binding var applyScanMode: Bool
    @Binding var applyPFE: Bool
    @Binding var apply2383: Bool
    @Binding var apply3513: Bool
    @Binding var offsetRGB: Float
    @Binding var offsetRed: Float
    @Binding var offsetGreen: Float
    @Binding var offsetBlue: Float
    @Binding var scanContrast: Float
    @Binding var lutBlend: Float

    var body: some View {
        VStack {
            Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)
            
            Spacer()
                .frame(height: 20)
            
            FilmStockView(
                convertToNeg: $convertToNeg,
                stockChoice: $stockChoice,
                bwMode: $bwMode
            )

            Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)
            
//            GrainTest()
            
            Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)

            EnlargerView(
                applyPrintMode: $applyPrintMode,
                enlargerExp: $enlargerExp,
                enlargerFStop: $enlargerFStop,
                bwMode: $bwMode,
                cyan: $cyan,
                magenta: $magenta,
                yellow: $yellow,
                applyFlash: $applyFlash,
                useLegacy: $useLegacy
            )
            
            Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)
            
            ScanView(
                applyPrintMode: $applyPrintMode,
                applyScanMode: $applyScanMode,
                applyPFE: $applyPFE,
                apply2383: $apply2383,
                apply3513: $apply3513,
                offsetRGB: $offsetRGB,
                offsetRed: $offsetRed,
                offsetGreen: $offsetGreen,
                offsetBlue: $offsetBlue,
                scanContrast: $scanContrast,
                lutBlend: $lutBlend
            )
//
//            ThogView(
//                applyTHOG: applyTHOG,
//                blend: blend,
//                variance: variance,
//                scale: scale
//            )
//            
//            Divider().overlay(Color("MenuAccent"))
//            
//            PrintFlashView(
//                applyPrintMode: $applyPrintMode,
//                applyFlash: $applyFlash,
//                previewFlash: $previewFlash,
//                flashEV: $flashEV,
//                flashFStop: $flashFStop,
//                flashCyan: $flashCyan,
//                flashMagenta: $flashMagenta,
//                flashYellow: $flashYellow
//            )
//            
            Divider().overlay(Color("MenuAccent"))
            
            Spacer()
        }
    }
    
    
    // Temporary binding for THOG
    private var applyTHOG: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.applyTHOG, defaultValue: false)
    }
    
    private var blend: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.blend, defaultValue: 100.0)
    }
    
    private var variance: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.variance, defaultValue: 50.0)
    }
    
    private var scale: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.scale, defaultValue: 30.0)
    }
}

