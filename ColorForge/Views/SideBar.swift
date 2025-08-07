//
//  SideBar.swift
//  ColorForge
//
//  Created by admin on 22/05/2025.
//

import Foundation
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var viewModel: ImageViewModel
    @ObservedObject var dataModel: DataModel
    @ObservedObject var pipeline: FilterPipeline
    @EnvironmentObject var sidebarViewModel: SidebarViewModel
    
    @EnvironmentObject var shortcut: ShortcutViewModel
    
    @Binding var profile: CopyProfile
    @Binding var showCopySettings: Bool
    
    @Binding var maskingViewActive: Bool
    @Binding var selectedMask: UUID?
    
    // Linear mask bindings
    @Binding var LinearStartPointBinding: CGPoint
    @Binding var LinearEndPointBinding: CGPoint
    
    // Radial mask bindings
    @Binding var radialStartPointBinding: CGPoint
    @Binding var radialEndPointBinding: CGPoint
    @Binding var radialFeatherBinding: Float
    @Binding var radialWidthBinding: CGFloat
    @Binding var radialHeightBinding: CGFloat
    @Binding var radialRotationBinding: Float
    @Binding var radialInvertBinding: Bool
    @Binding var radialOpacityBinding: Float
    
    
    @Binding var showsidebar: Bool
    
    @Binding var selectedTool: SAMTool?
    
    
    
    @Binding var isRawAdjustCollapsed: Bool
    
    
    // MARK: - View Toggle Enum
    
    // State to toggle between views
    @State private var selectedView: SidebarViewType = .raw
    
    enum SidebarViewType {
        case raw
        case texture
        case emulation
        case refine
        case export
    }
    
    // MARK: - Body
    
    var body: some View {
        
        VStack {
            
            // Histogram / VectorScope to go here
            HistogramView()
                .frame(width: viewModel.sideBarWidth)
                .padding(.horizontal, 25) // or whatever spacing you intended
            
          
            if showCopySettings {
                Divider().overlay(Color("MenuAccent"))
                
                
                CopySettingsView(profile: $profile)
                    .frame(width: viewModel.sideBarWidth)
                    .padding(.horizontal, 25) // or whatever spacing you intended
            } else {
                
                if maskingViewActive{
                    
                    MaskingView(
                        selectedMask: $selectedMask,
                        
                        // Linear
                        LinearStartPointBinding: $LinearStartPointBinding,
                        LinearEndPointBinding: $LinearEndPointBinding,
                        
                        // Radial
                        radialStartPointBinding: $radialStartPointBinding,
                        radialEndPointBinding: $radialEndPointBinding,
                        radialFeatherBinding: $radialFeatherBinding,
                        radialWidthBinding: $radialWidthBinding,
                        radialHeightBinding: $radialHeightBinding,
                        radialRotationBinding: $radialRotationBinding,
                        radialInvertBinding: $radialInvertBinding,
                        radialOpacityBinding: $radialOpacityBinding,
                        
                        mainApplyPrint: applyPrintMode,
                        
                        selectedTool: $selectedTool
                    )
//                    .frame(width: viewModel.sideBarWidth)
//                    .padding(.horizontal, 25) // or whatever spacing you intended
                    
                } else {
                    
                    Divider().overlay(Color("MenuAccent"))
                    
                    // MARK: - Select view category
                    HStack {
                        VStack {
                            Button(action: {
                                shortcut.show(.rawAdjustView)
                                selectedView = .raw
                                
                            }
                            ) {
                                Image(systemName: "slider.horizontal.3")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(selectedView == .raw ? Color("IconActive") : Color("SideBarText"))
                                    .padding(5)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut("r", modifiers: [])
                            
                            Text("Raw")
                                .font(.caption)
                                .foregroundColor(selectedView == .raw ? Color("IconActive") : Color("SideBarText"))
                        }
                        .padding(10)
                        
                        
                        VStack {
                            Button(action: {
                                shortcut.show(.emulationView)
                                selectedView = .emulation
                            }) {
                                Image(selectedView == .emulation ? "PrintIconActive" : "PrintIcon") // Conditional icon
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .padding(5)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut("e", modifiers: [])
                            
                            Text("Emulation")
                                .font(.caption)
                                .foregroundColor(selectedView == .emulation ? Color("IconActive") : Color("SideBarText"))
                        }
                        .padding(10)
                        
                        
                        VStack {
                            Button(action: {
                                selectedView = .texture
                                shortcut.show(.textureView)
                            }) {
                                Image(systemName: "drop.triangle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(selectedView == .texture ? Color("IconActive") : Color("SideBarText"))
                                    .padding(5)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut("t", modifiers: [])
                            
                            Text("Texture")
                                .font(.caption)
                            .foregroundColor(selectedView == .texture ? Color("IconActive") : Color("SideBarText"))                }
                        .padding(10)
                        
                        
                        
                        
                        VStack {
                            Button(action: {
                                shortcut.show(.export)
                                saveImages()
                                
                            }) {
                                Image(systemName: "arrow.down.square")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(selectedView == .export ? Color("IconActive") : Color("SideBarText"))
                                    .padding(5)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .keyboardShortcut("e", modifiers: [.command])
                            
                            Text("Save")
                                .font(.caption)
                                .foregroundColor(selectedView == .export ? Color("IconActive") : Color("SideBarText"))
                        }
                        .padding(10)
                    }
                    .frame(height: 60) // Increased height to allow space for text
//                    .frame(width: viewModel.sideBarWidth - 50)
                    
                    
                    
                    
                    
                    // MARK: - Views
                    
                    
                    ScrollView(.vertical) {
                        VStack {
                            
                            // Conditional Views
                            if selectedView == .raw {
                                RawView(
                                    temp: temp,
                                    tint: tint,
                                    initTemp: initTemp,
                                    initTint: initTint,
                                    exposure: exposure,
                                    contrast: contrast,
                                    saturation: saturation,
                                    hdrWhite: hdrWhite,
                                    hdrHighlight: hdrHighlight,
                                    hdrShadow: hdrShadow,
                                    hdrBlack: hdrBlack,
                                    redHue: redHue,
                                    redSat: redSat,
                                    redDen: redDen,
                                    greenHue: greenHue,
                                    greenSat: greenSat,
                                    greenDen: greenDen,
                                    blueHue: blueHue,
                                    blueSat: blueSat,
                                    blueDen: blueDen,
                                    cyanHue: cyanHue,
                                    cyanSat: cyanSat,
                                    cyanDen: cyanDen,
                                    magentaHue: magentaHue,
                                    magentaSat: magentaSat,
                                    magentaDen: magentaDen,
                                    yellowHue: yellowHue,
                                    yellowSat: yellowSat,
                                    yellowDen: yellowDen,
                                    isRawAdjustCollapsed: $isRawAdjustCollapsed
                                )
                            } else if selectedView == .texture {
                                TextureView(
                                    applyMTF: applyMTF,
                                    mtfBlend: mtfBlend,
                                    applyGrain: applyGrain,
                                    grainAmount: grainAmount,
                                    selectedGateWidth: selectedGateWidth,
                                    scaleGrainToFormat: scaleGrainToFormat,
                                    printHalation_size: printHalation_size,
                                    printHalation_amount: printHalation_amount,
                                    printHalation_darkenMode: printHalation_darkenMode,
                                    printHalation_apply: printHalation_apply
                                )
                            } else if selectedView == .emulation {
                                EmulationView(
                                    convertToNeg: convertToNeg,
                                    stockChoice: stockChoice,
                                    applyPrintMode: applyPrintMode,
                                    enlargerExp: enlargerExp,
                                    enlargerFStop: enlargerFStop,
                                    bwMode: bwMode,
                                    cyan: cyan,
                                    magenta: magenta,
                                    yellow: yellow,
                                    applyFlash: applyFlash,
                                    useLegacy: useLegacy,
                                    previewFlash: previewFlash,
                                    flashEV: flashEV,
                                    flashFStop: flashFStop,
                                    flashCyan: flashCyan,
                                    flashMagenta: flashMagenta,
                                    flashYellow: flashYellow,
                                    
                                    applyScanMode: applyScanMode,
                                    applyPFE: applyPFE,
                                    offsetRGB: offsetRGB,
                                    offsetRed: offsetRed,
                                    offsetGreen: offsetGreen,
                                    offsetBlue: offsetBlue,
                                    scanContrast: scanContrast,
                                    lutBlend: lutBlend
                                )
                            } else if selectedView == .export {
                                //                        ExportView()
                                
                            }
                            
                        }
                    }
                    .frame(width: viewModel.sideBarWidth)
                    .padding(.horizontal, 25) // or whatever spacing you intended
                    
                }
            }
            
            
            Spacer()
            
            
            Divider().overlay(Color("MenuAccent"))
            
            // MARK: - Sidebar options
            
            // Detach icon, and hamburger menu for sidebar options
            HStack (spacing: 0) {
                
                // Move / detach sidebar button
                // Should have haptic feed back, and only be moveable after long hold of 0.5 seconds
                Button(action: {
                    
                    
                }
                ) {
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("SideBarText"))
                        .padding(5)
                        .frame(width: 25, height: 25)
                }
                .buttonStyle(PlainButtonStyle())
                
                
                // Show / hide sidebar icon
                Button(action: {
                    withAnimation {
                        showsidebar = false
                    }
                }
                ) {
                    Image(systemName: "eye")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("SideBarText"))
                        .padding(5)
                        .frame(width: 25, height: 25)
                }
                .buttonStyle(PlainButtonStyle())
                
                
                
                Spacer()
                
                
                // Will become the menu options
                Button(action: {
                    
                }
                ) {
                    Image(systemName: "gearshape")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("SideBarText"))
                        .padding(5)
                        .frame(width: 25, height: 25)
                }
                .buttonStyle(PlainButtonStyle())
                //                .keyboardShortcut("r", modifiers: [])
                
            }
            // .frame(width: viewModel.sideBarWidth - 50)
            .padding(.leading, 25)
            .padding(.trailing, 25)
            .padding(.bottom, 0)
            
            
            
            
            
            
        } // End of main VStack
        .background(Color("MenuBackground"))
        .frame(maxHeight: .infinity)
//        .frame(width: viewModel.sideBarWidth)
        
        
    }
    
    
    // MARK: - Save Images
    
    private func saveImages() {
        let thumbModel = ThumbnailViewModel.shared
        let saveModel = SaveModel.shared
        
        
        // Batch export if multiple images selected
        if !thumbModel.saveIDs.isEmpty {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.canCreateDirectories = true
            panel.canChooseFiles = false
            panel.prompt = "Select Folder"
            
            if let currentID = viewModel.currentImgID, !thumbModel.saveIDs.contains(currentID) {
                thumbModel.saveIDs.append(currentID)
            }
            
            
            
            
            for id in thumbModel.saveIDs {
                dataModel.updateItem(id: id) { item in
                    item.isExport = true
                    item.isSaved = false
                }
            }
            
            panel.begin { response in
                if response == .OK, let folderURL = panel.url {
                    viewModel.saveToggled = true
                    
                    Task {
                        await saveModel.batchSave(thumbModel.saveIDs, dataModel, folderURL)
                    }
                }
            }
        } else {
            // Single image export
            guard let id = viewModel.currentImgID else {
                print("debugHaldRead: No current URL set in pipeline.")
                return
            }
            guard let item = dataModel.items.first(where: { $0.id == id }) else {
                return
            }
            
            let ids = [id]
            
            dataModel.updateItem(id: id) { item in
                item.isExport = true
                item.isSaved = false
            }
            
            let panel = NSSavePanel()
            panel.allowedFileTypes = ["tiff"]
            panel.canCreateDirectories = true
            
            let currentUrl = item.url
            let originalFilename = currentUrl.deletingPathExtension().lastPathComponent
            panel.nameFieldStringValue = "\(originalFilename).tiff"
            
            panel.begin { response in
                if response == .OK, let saveURL = panel.url {
                    viewModel.saveToggled = true
                    Task {
                        await saveModel.batchSave(ids, dataModel, saveURL)
                    }
                }
            }
        }
    }
    
    
    
    // MARK: - Bindings
    
    
    
    
    
    // MARK: - White Balance
    private var temp: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.temp, defaultValue: 5500.0)
    }
    
    private var tint: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.tint, defaultValue: 0.0)
    }
    
    private var initTemp: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.initTemp, defaultValue: 5500.0)
    }
    
    private var initTint: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.initTint, defaultValue: 0.0)
    }
    
    // MARK: - Raw Adjust
    private var exposure: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.exposure, defaultValue: 0)
    }
    
    private var contrast: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.contrast, defaultValue: 0)
    }
    
    private var saturation: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.saturation, defaultValue: 0)
    }
    
    // MARK: - HDR
    private var hdrWhite: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.hdrWhite, defaultValue: 0.0)
    }
    private var hdrHighlight: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.hdrHighlight, defaultValue: 0.0)
    }
    private var hdrShadow: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.hdrShadow, defaultValue: 0.0)
    }
    private var hdrBlack: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.hdrBlack, defaultValue: 0.0)
    }
    
    // MARK: - HSD Values
    private var redHue: Binding<Float> { dataModel.bindingToItem(keyPath: \.redHue, defaultValue: 0.0) }
    private var redSat: Binding<Float> { dataModel.bindingToItem(keyPath: \.redSat, defaultValue: 0.0) }
    private var redDen: Binding<Float> { dataModel.bindingToItem(keyPath: \.redDen, defaultValue: 0.0) }
    
    private var greenHue: Binding<Float> { dataModel.bindingToItem(keyPath: \.greenHue, defaultValue: 0.0) }
    private var greenSat: Binding<Float> { dataModel.bindingToItem(keyPath: \.greenSat, defaultValue: 0.0) }
    private var greenDen: Binding<Float> { dataModel.bindingToItem(keyPath: \.greenDen, defaultValue: 0.0) }
    
    private var blueHue: Binding<Float> { dataModel.bindingToItem(keyPath: \.blueHue, defaultValue: 0.0) }
    private var blueSat: Binding<Float> { dataModel.bindingToItem(keyPath: \.blueSat, defaultValue: 0.0) }
    private var blueDen: Binding<Float> { dataModel.bindingToItem(keyPath: \.blueDen, defaultValue: 0.0) }
    
    private var cyanHue: Binding<Float> { dataModel.bindingToItem(keyPath: \.cyanHue, defaultValue: 0.0) }
    private var cyanSat: Binding<Float> { dataModel.bindingToItem(keyPath: \.cyanSat, defaultValue: 0.0) }
    private var cyanDen: Binding<Float> { dataModel.bindingToItem(keyPath: \.cyanDen, defaultValue: 0.0) }
    
    private var magentaHue: Binding<Float> { dataModel.bindingToItem(keyPath: \.magentaHue, defaultValue: 0.0) }
    private var magentaSat: Binding<Float> { dataModel.bindingToItem(keyPath: \.magentaSat, defaultValue: 0.0) }
    private var magentaDen: Binding<Float> { dataModel.bindingToItem(keyPath: \.magentaDen, defaultValue: 0.0) }
    
    private var yellowHue: Binding<Float> { dataModel.bindingToItem(keyPath: \.yellowHue, defaultValue: 0.0) }
    private var yellowSat: Binding<Float> { dataModel.bindingToItem(keyPath: \.yellowSat, defaultValue: 0.0) }
    private var yellowDen: Binding<Float> { dataModel.bindingToItem(keyPath: \.yellowDen, defaultValue: 0.0) }
    
    // MARK: - Texture
    private var applyMTF: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.applyMTF, defaultValue: false)
    }
    private var mtfBlend: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.mtfBlend, defaultValue: 50.0)
    }
    private var applyGrain: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.applyGrain, defaultValue: false)
    }
    private var grainAmount: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.grainAmount, defaultValue: 50.0)
    }
    private var selectedGateWidth: Binding<Int> {
        dataModel.bindingToItem(keyPath: \.selectedGateWidth, defaultValue: 0)
    }
    private var scaleGrainToFormat: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.scaleGrainToFormat, defaultValue: false)
    }
    
    // MARK: - Print Halation
    
    private var printHalation_size: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.printHalation_size, defaultValue: 10.0)
    }
    private var printHalation_amount: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.printHalation_amount, defaultValue: 50.0)
    }
    private var printHalation_darkenMode: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.printHalation_darkenMode, defaultValue: true)
    }
    private var printHalation_apply: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.printHalation_apply, defaultValue: false)
    }
    
    // MARK: - Neg Conversion
    private var convertToNeg: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.convertToNeg, defaultValue: false)
    }
    private var stockChoice: Binding<Int> {
        dataModel.bindingToItem(keyPath: \.stockChoice, defaultValue: 0)
    }
    
    // MARK: - Enlarger
    private var applyPrintMode: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.applyPrintMode, defaultValue: false)
    }
    private var enlargerExp: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.enlargerExp, defaultValue: 0.0)
    }
    private var enlargerFStop: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.enlargerFStop, defaultValue: 11.0)
    }
    private var bwMode: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.bwMode, defaultValue: false)
    }
    private var cyan: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.cyan, defaultValue: 0.0)
    }
    private var magenta: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.magenta, defaultValue: 0.0)
    }
    private var yellow: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.yellow, defaultValue: 0.0)
    }
    private var useLegacy: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.useLegacy, defaultValue: true)
    }
    
    // MARK: - Print Flash
    private var applyFlash: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.applyFlash, defaultValue: false)
    }
    private var previewFlash: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.previewFlash, defaultValue: false)
    }
    private var flashEV: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.flashEV, defaultValue: 0.0)
    }
    private var flashFStop: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.flashFStop, defaultValue: 11.0)
    }
    private var flashCyan: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.flashCyan, defaultValue: 0.0)
    }
    private var flashMagenta: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.flashMagenta, defaultValue: 0.0)
    }
    private var flashYellow: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.flashYellow, defaultValue: 0.0)
    }
    
    
    // MARK: - Scan
    private var applyScanMode: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.applyScanMode, defaultValue: false)
    }
    private var applyPFE: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.applyPFE, defaultValue: false)
    }
    private var offsetRGB: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.offsetRGB, defaultValue: 0.0)
    }
    private var offsetRed: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.offsetRed, defaultValue: 0.0)
    }
    private var offsetGreen: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.offsetGreen, defaultValue: 0.0)
    }
    private var offsetBlue: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.offsetBlue, defaultValue: 0.0)
    }
    private var scanContrast: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.scanContrast, defaultValue: 0.0)
    }
    private var lutBlend: Binding<Float> {
        dataModel.bindingToItem(keyPath: \.lutBlend, defaultValue: 100.0)
    }
    
    
    // MARK: - Functions
    
    
    
    //    private func debugHaldRead() {
    //        let lutModel = LutModel.shared
    //
    //        guard let id = viewModel.currentImgID else {
    //            print("debugHaldRead: No current URL set in pipeline.")
    //            return
    //        }
    //
    //        lutModel.generateCaptureOneLUT(id, pipeline, dataModel)
    //
    //        guard let item = dataModel.items.first(where: { $0.id == id }) else {
    //            return
    //        }
    //
    //        guard let debayered = item.debayeredInit else {
    //            return
    //        }
    //
    //        let node = RawExposureNode(
    //            exposure: item.exposure,
    //            convertToNeg: false,
    //            bwMode: false,
    //            isLut: false
    //        )
    //
    //        var exposureApplied = node.apply(to: debayered)
    //        exposureApplied = exposureApplied.LogC2Lin()
    //        exposureApplied = exposureApplied.AWGtoP3()
    //
    //        debugSave(exposureApplied, "linear")
    //
    ////
    ////        guard let haldImage = pipeline.applyHaldPipeline(for: id, in: dataModel) else {return}
    ////
    ////
    ////        guard let data = lutModel.readCubeData(from: haldImage, size: 64) else {
    ////            print("debugHaldRead: Failed to extract cube data from hald image.")
    ////            return
    ////        }
    ////
    ////        lutModel.saveCubeDataAsCubeFile(data, "combinedResult")
    ////
    ////
    ////        let isMask = false
    //
    ////        let node = TempAndTintNode(
    ////            isMask: isMask,
    ////            targetTemp: item.initTemp,
    ////            targetTint: item.initTint,
    ////            sourceTemp: item.temp,
    ////            sourceTint: item.tint,
    ////            convertToNeg: item.convertToNeg
    ////        )
    //
    ////        let c1Color = applyC1Matrix(debayered)
    ////        let captureOne = debayered.convertToCaptureOneInput()
    //////        let c1Color = captureOne.applyLut("CaptureOneInput")
    ////
    ////        debugSave(debayered, "linear")
    ////        debugSave(captureOne, "gamma18")
    ////        let lutImage = debayered.applyLutData(data)
    ////        debugSave(lutImage, "lut_applied")
    ////
    //
    //
    //
    //
    ////        print("debugHaldRead: Successfully read cube data, writing to text file...")
    ////        lutModel.saveCubeDataAsText(data)
    ////
    ////        let testImage: CIImage = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 500, height: 500))
    ////        let lutImage = testImage.applyLutData(data)
    ////
    ////        debugSave(lutImage)
    //
    //    }
    
    private func applyC1Matrix(_ input: CIImage) -> CIImage {
        let filter = CIFilter.colorMatrix()
        filter.inputImage = input
        
        filter.rVector = CIVector(x: 0.567264, y: 0.220259, z: 0.212477, w: 0)
        filter.gVector = CIVector(x: 0.053290, y: 0.580767, z: 0.365943, w: 0)
        filter.bVector = CIVector(x: -0.004724, y: 0.197315, z: 0.807409, w: 0)
        filter.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        filter.biasVector = CIVector(x: 0, y: 0, z: 0, w: 0)
        
        return filter.outputImage!
    }
    
}

