//
//  ContentView.swift
//  ColorForge
//
//  Created by Ben Quinton on 21/05/2025.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var pipeline: FilterPipeline
    @EnvironmentObject var imageViewModel: ImageViewModel
    @EnvironmentObject var thumbModel: ThumbnailViewModel
    @EnvironmentObject var shortcut: ShortcutViewModel
    @Environment(\.undoManager) private var undoManager
    @State var selectedURL: URL?
    @State var imageViewActive: Bool = false
    @State private var currentImage: CIImage? = nil
    @State var imageHasChanged: Bool = false
    @State private var maskingViewActive: Bool = false
    
    @State private var showsidebar: Bool = true
    @State private var folderPressed: Bool = false
    @State private var folderAnimationComplete: Bool = false
    
    // Copy Settings
    @State private var profile = CopyProfile()
    @State private var showCopySettings: Bool = false
    
    @State private var selectedTool: SAMTool?
    
    // Collapsed States
    @State private var isRawAdjustCollapsed: Bool = false
    
    var body: some View {
        VStack (spacing: 0) {
            
            TopbarView(
                imageViewActive: $imageViewActive,
                maskingViewActive: $maskingViewActive,
                profile: $profile,
                showCopySettings: $showCopySettings
            )
            .frame(height: imageViewModel.topBarHeight)
            
            HStack(spacing: 0) {
                
                if showsidebar {
                    
                    
                    SidebarView(
                        dataModel: dataModel,
                        pipeline: pipeline,
                        profile: $profile,
                        showCopySettings: $showCopySettings,
                        maskingViewActive: $maskingViewActive,
                        selectedMask: $selectedMask,
                        LinearStartPointBinding: LinearStartPointBinding,
                        LinearEndPointBinding: LinearEndPointBinding,
                        
                        aiMaskImageBinding: aiMaskImageBinding,
                        
                        radialStartPointBinding: radialStartPointBinding,
                        radialEndPointBinding: radialEndPointBinding,
                        radialFeatherBinding: radialFeatherBinding,
                        radialWidthBinding: radialWidthBinding,
                        radialHeightBinding: radialHeightBinding,
                        radialRotationBinding: radialRotationBinding,
                        radialInvertBinding: radialInvertBinding,
                        radialOpacityBinding: radialOpacityBinding,
                        showsidebar: $showsidebar,
                        selectedTool: $selectedTool,
                        isRawAdjustCollapsed: $isRawAdjustCollapsed,
                        
                        
                        aiFeatherBinding: aiFeatherBinding,
                        aiOpacityBinding: aiOpacityBinding,
                        aiInvertBinding: aiInvertBinding
                        
                    )
                    .transition(.move(edge: .leading))
                    //                    .frame(width: imageViewModel.sideBarWidth)
                }
                
                // Hidden button to bring sidebar back
                Button(action: {
                    if !showsidebar{
                        withAnimation {
                            showsidebar = true
                        }
                    } else {
                        withAnimation {
                            showsidebar = false
                        }
                    }
                }
                ) {
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("SideBarText"))
                        .padding(0)
                        .frame(width: 1, height: 1)
                        .opacity(0)
                }
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut("t", modifiers: [.command])
                
                
                // Show / hide mask hidden
                Button(action: {
                    guard imageViewModel.selectedMask != nil else { return }
                    if !imageViewModel.showMask {
                        imageViewModel.showMask = true
                    } else {
                        imageViewModel.showMask = false
                    }
                }) {
                    Image(systemName: "trash")
                        .resizable()
                        .foregroundColor(Color("SideBarText"))
                        .frame(width: 0, height: 1)
                        .padding(0)
                    
                }
                .opacity(0)
                .padding(0)
                .buttonStyle(PlainButtonStyle())
                .keyboardShortcut("m", modifiers: [.shift])
                
                
                
                GeometryReader { geo in
                    ZStack {
                        
                        //					if imageViewModel.sam2MaskMode {
                        //						GeometryReader { geo in
                        //							SamView(viewWidth: geo.size.width, viewHeight: geo.size.height)
                        //						}
                        //					} else {
                        
                        if imageViewActive {
                            ImageView(
                                image: $currentImage,
                                selectedMask: $selectedMask,
                                LinearStartPointBinding: LinearStartPointBinding,
                                LinearEndPointBinding: LinearEndPointBinding,
                                aiMaskImageBinding: aiMaskImageBinding,
                                
                                radialStartPointBinding: radialStartPointBinding,
                                radialEndPointBinding: radialEndPointBinding,
                                radialFeatherBinding: radialFeatherBinding,
                                radialWidthBinding: radialWidthBinding,
                                radialHeightBinding: radialHeightBinding,
                                radialRotationBinding: radialRotationBinding,
                                radialInvertBinding: radialInvertBinding,
                                radialOpacityBinding: radialOpacityBinding,
                                selectedTool: $selectedTool
                            )
                            
                            //                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .frame(width: geo.size.width, height: geo.size.height)
                        } else {
                            
                            
                            
                            if imageViewModel.processingComplete {
                                ThumbnailView(imageViewActive: $imageViewActive)
                                //                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .frame(width: geo.size.width, height: geo.size.height)
                            } else {
                                
                                
                                
                                
                                ZStack {
                                    // Grey Button
                                    Button(action: {
                                        folderPressed = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                            openImages()
                                            folderAnimationComplete = true
                                        }
                                    }) {
                                        Image(systemName: "folder.badge.plus")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .font(.caption)
                                            .opacity(folderPressed ? 0.0 : 1.0)
                                            .frame(width: geo.size.width / 15.0, height:  geo.size.width / 15.0)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                    //									.buttonStyle(OpenFolderStyle())
                                    .position(x: geo.size.width / 2.0, y: geo.size.height * 0.4)
                                    
                                    if folderAnimationComplete {
                                        
                                        ProgressView()
                                            .background(Color("MenuAccentDark"))
                                            .position(x: geo.size.width / 2.0, y: geo.size.height * 0.4)
                                            
                                        
                                    }
                                }
                                .background(Color("MenuAccentDark"))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                //                                .frame(width: geo.size.width, height: geo.size.height)
                                
                                
                                
                                
                            } // First else
                            
                        } // Second else
                        
                        if shortcut.showHelpers {
                            ShortcutView()
                                .zIndex(100)
                                .allowsHitTesting(false)
                                .position(x: geo.size.width / 2.0, y: geo.size.height * 0.7)
                                .opacity(0.8)
                        }
                    }
                    //                    .frame(width: geo.size.width, height: geo.size.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                }
                .ignoresSafeArea()
            }
            .padding(0)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            
            BottomBarView()
                .frame(height: imageViewModel.bottomBarHeight)
                .background(Color("MenuBackground"))
            
        }
        .padding(0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .onAppear {
            dataModel.undoManager = undoManager
        }
        .onChange(of: undoManager) { newValue in
            dataModel.undoManager = newValue
        }
    }
    
    // MARK: - Custom progress view
    
    private func openImages() {
        dataModel.loading = true
        dataModel.thumbsFullyLoaded = false
        thumbModel.isInitialLoad = true
        
        let panel = NSOpenPanel()
        //        panel.allowedFileTypes = ["dng", "DNG", "arw", "ARW", "RAF", "raf", "cr2", "CR2", "cr3", "CR3"]
        
        panel.allowedContentTypes = [
            UTType(filenameExtension: "dng"),
            UTType(filenameExtension: "arw"),
            UTType(filenameExtension: "raf"),
            UTType(filenameExtension: "cr2"),
            UTType(filenameExtension: "cr3"),
            UTType(filenameExtension: "iiq"),
            UTType(filenameExtension: "fff"),
            UTType(filenameExtension: "nef"),
            UTType.tiff,                              // .tiff
            UTType(filenameExtension: "tif")          // .tif
        ].compactMap { $0 }
        
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK {
            let selectedURLs = panel.urls
            if !selectedURLs.isEmpty {
                Task {
                    await dataModel.loadImagesV2(from: selectedURLs)
                }
            } else {
                // User clicked OK but selected nothing
                dataModel.loading = false
                dataModel.thumbsFullyLoaded = true
            }
        } else {
            // User cancelled the dialog
            dataModel.loading = false
            dataModel.thumbsFullyLoaded = true
        }
    }
    
    
    // MARK: - Mask Bindings
    
    @State var selectedMask: UUID?
    
    // In ImageViewModel or wherever appropriate
    
    var LinearStartPointBinding: Binding<CGPoint> {
        guard let maskId = selectedMask else { return .constant(.zero) }
        return dataModel.bindingToGradientMaskValue(
            maskId: maskId,
            keyPath: \.startPoint,
            defaultValue: .zero
        )
    }
    
    var LinearEndPointBinding: Binding<CGPoint> {
        guard let maskId = selectedMask else { return .constant(.zero) }
        return dataModel.bindingToGradientMaskValue(
            maskId: maskId,
            keyPath: \.endPoint,
            defaultValue: .zero
        )
    }
    
    
    var aiMaskImageBinding: Binding<CIImage?> {
        guard let maskId = selectedMask else { return .constant(nil) }
        return dataModel.bindingToAiMaskMaskImage(
            maskId: maskId,
            keyPath: \.maskImage,
            defaultValue: nil
        )
    }
    
    
    
    var aiFeatherBinding: Binding<Float> {
        guard let maskId = selectedMask else { return .constant(5.0) }
        return dataModel.bindingToAiMaskValue(
            maskId: maskId,
            keyPath: \.feather,
            defaultValue: 5.0
        )
    }
    
    var aiOpacityBinding: Binding<Float> {
        guard let maskId = selectedMask else { return .constant(100.0) }
        return dataModel.bindingToAiMaskValue(
            maskId: maskId,
            keyPath: \.opacity,
            defaultValue: 100.0
        )
    }
    
    var aiInvertBinding: Binding<Bool> {
        guard let maskId = selectedMask else { return .constant(false) }
        return dataModel.bindingToAiMaskValue(
            maskId: maskId,
            keyPath: \.invert,
            defaultValue: false
        )
    }
    
    
    
    var radialStartPointBinding: Binding<CGPoint> {
        guard let maskId = selectedMask else { return .constant(.zero) }
        return dataModel.bindingToRadialMaskValue(
            maskId: maskId,
            keyPath: \.startPoint,
            defaultValue: .zero
        )
    }
    
    var radialEndPointBinding: Binding<CGPoint> {
        guard let maskId = selectedMask else { return .constant(.zero) }
        return dataModel.bindingToRadialMaskValue(
            maskId: maskId,
            keyPath: \.endPoint,
            defaultValue: .zero
        )
    }
    
    var radialFeatherBinding: Binding<Float> {
        guard let maskId = selectedMask else { return .constant(50.0) }
        return dataModel.bindingToRadialMaskValue(
            maskId: maskId,
            keyPath: \.feather,
            defaultValue: 50.0
        )
    }
    
    var radialWidthBinding: Binding<CGFloat> {
        guard let maskId = selectedMask else { return .constant(1.0) }
        return dataModel.bindingToRadialMaskValue(
            maskId: maskId,
            keyPath: \.width,
            defaultValue: 1.0
        )
    }
    
    var radialHeightBinding: Binding<CGFloat> {
        guard let maskId = selectedMask else { return .constant(1.0) }
        return dataModel.bindingToRadialMaskValue(
            maskId: maskId,
            keyPath: \.height,
            defaultValue: 1.0
        )
    }
    
    var radialRotationBinding: Binding<Float> {
        guard let maskId = selectedMask else { return .constant(0.0) }
        return dataModel.bindingToRadialMaskValue(
            maskId: maskId,
            keyPath: \.rotation,
            defaultValue: 0.0
        )
    }
    
    var radialInvertBinding: Binding<Bool> {
        guard let maskId = selectedMask else { return .constant(false) }
        return dataModel.bindingToRadialMaskValue(
            maskId: maskId,
            keyPath: \.invert,
            defaultValue: false
        )
    }
    
    var radialOpacityBinding: Binding<Float> {
        guard let maskId = selectedMask else { return .constant(1.0) }
        return dataModel.bindingToRadialMaskValue(
            maskId: maskId,
            keyPath: \.opacity,
            defaultValue: 1.0
        )
    }
    
    
}
