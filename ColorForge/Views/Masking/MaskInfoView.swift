//
//  MaskingView.swift
//  ColorForge
//
//  Created by Ben Quinton on 09/08/2025.
//

import Foundation
import SwiftUI


struct MaskInfoView: View {
    @EnvironmentObject var pipeline: FilterPipeline
    @EnvironmentObject var viewModel: ImageViewModel
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var samModel: SamModel
    
    @FocusState private var focusedField: String?
    
    
    
    @State private var showingNamePopup = false
    @State private var namingMaskId: UUID? = nil
    @State private var pendingMaskName: String = ""
    
    @Binding var aiMaskImageBinding: CIImage?
    
    @Binding var selectedMask: UUID?
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
    
    
    @Binding var selectedTool: SAMTool?
    var tools: [SAMTool] = [pointTool, boundingBoxTool]
    
    @Binding var aiFeatherBinding: Float
    @Binding var aiOpacityBinding: Float
    @Binding var aiInvertBinding: Bool
    
    
    
    
    
    
    
    @State var aiOpacity: Float = 100.0
    @State var aiFeather: Float = 5.0
    @State var aiInvert: Bool = false
    
    
    @State var opacity: Float = 100.0
    @State var feather: Float = 50.0
    @State var expand: Float = 0.0
    @State var shrink: Float = 0.0
    @State var invert: Bool = false
    
    @State private var isMaskTypePopoverPresented = false
    @State private var pendingMaskType: PendingMaskType = .linear
    private enum PendingMaskType {
        case linear
        case radial
        case ai
    }
    
    
    var body: some View {
        VStack {
            Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)
            
            //plus.app.fill
            Spacer()
                .frame(height: 20)
            
            // MARK: - Add Mask
            HStack {
                
                Button(action: {
                    isMaskTypePopoverPresented.toggle()
                }) {
                    Image(systemName: "plus.app.fill")
                        .font(.title2)
                        .foregroundStyle(Color("SideBarText"))
                    
                    Text("New Mask")
                        .foregroundStyle(Color("SideBarText"))
                }
                .buttonStyle(PlainButtonStyle())
                .popover(isPresented: $isMaskTypePopoverPresented, arrowEdge: .bottom) {
                    VStack(alignment: .leading, spacing: 0) {
                        popoverMaskTypeRow(type: .linear, label: "Linear Gradient", icon: "square.bottomhalf.filled")
                        popoverMaskTypeRow(type: .radial, label: "Radial Gradient", icon: "circle.righthalf.filled")
                        popoverMaskTypeRow(type: .ai, label: "AI Mask", icon: "sparkles")
                    }
                    .background(Color("MenuAccent"))
                    .frame(width: 150)
                }
                
                Spacer()
                
                // MARK: - Hidden buttons
                Button (action: {createNewLinearMask()}
                ){
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(0)
                .keyboardShortcut("g", modifiers: [])
                
                
                Button (action: {createNewRadialMask()}
                ){
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(0)
                .keyboardShortcut("j", modifiers: [])
                
                Button (action: {createNewAiMask()}
                ){
                    Image(systemName: "arrow.counterclockwise")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 1)
                }
                .buttonStyle(PlainButtonStyle())
                .opacity(0)
                .keyboardShortcut("a", modifiers: [])
                
                
                // Mask settings
                Button(action: {
                    
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundStyle(Color("SideBarText"))
                    
                }
                .buttonStyle(PlainButtonStyle())
                
                // Reset all masks
                Button(action: {
                    
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(Color("SideBarText"))
                    
                }
                .buttonStyle(PlainButtonStyle())
                
            }
            .padding(5)
            .padding(.horizontal, 20)
            
            
            
            
            // MARK: - Adjustments
            Spacer()
                .frame(height: 20)
            
            VStack {
                // Feather
                FeatherSlider(feather: viewModel.sam2MaskMode ? $aiFeather : $radialFeatherBinding)
                    .onChange(of: aiFeather) {
                        aiFeatherBinding = aiFeather
                        samModel.updateMask(dataModel)
                    }
                    .onChange(of: aiFeatherBinding) {
                        aiFeather = aiFeatherBinding
                    }
                    .onAppear{
                        aiFeather = aiFeatherBinding
                    }
                
                
                // Opacity
                OpacitySlider(opacity: viewModel.sam2MaskMode ? $aiOpacity : $radialOpacityBinding)
                    .onChange(of: aiOpacity) {
                        aiOpacityBinding = aiOpacity
                        samModel.updateMask(dataModel)
                    }
                    .onChange(of: aiOpacityBinding) {
                        aiOpacity = aiOpacityBinding
                    }
                    .onAppear{
                        aiOpacity = aiOpacityBinding
                    }
                
                //            SliderViewMock(label: "Opacity:")
                //            SliderViewMock(label: "Feather:")
                //            SliderViewMock(label: "Expand:")
                //            SliderViewMock(label: "Shrink:")
                
            }
            .padding(.horizontal, 20)
            
            Spacer()
                .frame(height: 20)
            
            Divider().overlay(Color("MenuAccent"))
            
            Spacer()
                .frame(height: 20)
            
            
            
            
            
            
            // MARK: Tool Selection
            
            HStack {
                
                Spacer()
                
                Button(action: {
                    
                    selectedTool = tools[0]
                    
                }) {
                    
                    Spacer()
                        .frame(width: 5)
                    
                    Image(systemName: "hand.point.up")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("Point Select")
                        .foregroundStyle(Color("SideBarText"))
                    
                    Spacer()
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 120)
                .padding(5)
                .background(Color("MenuAccent"))
                .border(selectedTool == tools[0] ? Color("IconActive").opacity(0.8) : Color.gray, width: 1)
                
                Spacer()
                
                Button(action: {
                    selectedTool = tools[1]
                }) {
                    
                    Spacer()
                        .frame(width: 5)
                    
                    Image(systemName: "square.dashed")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("Box Select")
                        .foregroundStyle(Color("SideBarText"))
                    
                    Spacer()
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 120)
                .padding(5)
                .background(Color("MenuAccent"))
                .border(selectedTool == tools[1] ? Color("IconActive").opacity(0.8) : Color.gray, width: 1)
                
                Spacer()
                
            }
            .onChange(of: viewModel.sam2MaskMode){
                if viewModel.sam2MaskMode {
                    selectedTool = tools[0]
                }  else {
                    selectedTool = nil
                }
            }
            .disabled(!viewModel.sam2MaskMode)
            .opacity(viewModel.sam2MaskMode ? 1 : 0.5)
            
            Spacer()
                .frame(height: 10)
            
            
            
            
            
            // MARK: - Add Subtract
            
            
            HStack {
                
                Spacer()
                
                Button(action: {
                    if samModel.addToMask {
                        samModel.addToMask = false
                    } else {
                        samModel.addToMask = true
                        samModel.subtractFromMask = false
                    }
                }) {
                    
                    Spacer()
                        .frame(width: 5)
                    
                    Image(systemName: "plus.app")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("Add")
                        .foregroundStyle(Color("SideBarText"))
                    
                    Spacer()
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 120)
                .padding(5)
                .background(Color("MenuAccent"))
                .border(samModel.addToMask ? Color("IconActive").opacity(0.8) : Color.gray, width: 1)
                
                Spacer()
                
                Button(action: {
                    if samModel.subtractFromMask {
                        samModel.subtractFromMask = false
                    } else {
                        samModel.subtractFromMask = true
                        samModel.addToMask = false
                    }
                }) {
                    
                    Spacer()
                        .frame(width: 5)
                    
                    Image(systemName: "minus.square")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("Subtract")
                        .foregroundStyle(Color("SideBarText"))
                    
                    Spacer()
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 120)
                .padding(5)
                .background(Color("MenuAccent"))
                .border(samModel.subtractFromMask ? Color("IconActive").opacity(0.8) : Color.gray, width: 1)
                
                Spacer()
                
            }
            .disabled(!viewModel.sam2MaskMode)
            .opacity(viewModel.sam2MaskMode ? 1 : 0.5)
            
            Spacer()
                .frame(height: 20)
            
            Divider().overlay(Color("MenuAccent"))
            
            Spacer()
                .frame(height: 20)
            
            // Make Collapseable
            MasksView(selectedMask: $selectedMask)
            
            Spacer()
                .frame(height: 20)
            
        }
        .sheet(isPresented: $showingNamePopup) {
            MaskNameView(name: $pendingMaskName) { newName in
                switch pendingMaskType {
                case .linear:
                    addLinearMask(named: newName)
                case .radial:
                    addRadialMask(named: newName)
                case .ai:
                    addAiMask(named: newName)
                }
                viewModel.drawingNewMask = false
                showingNamePopup = false
            }
        }
        .onAppear{
            getCount()
        }
        .onDisappear{
            samModel.showPoints = false
            samModel.showSamMask = false
            viewModel.sam2MaskMode = false
        }
    }
    
    
    // MARK: - Popover Row
    @ViewBuilder
    private func popoverMaskTypeRow(type: PendingMaskType, label: String, icon: String) -> some View {
        Button {
            pendingMaskType = type
            isMaskTypePopoverPresented = false
            handleNewMask(ofType: type)
        } label: {
            HStack {
                Text(label)
                    .foregroundColor(Color("SideBarText"))
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(Color("SideBarText"))
            }
            .padding(10)
            .background(Color("MenuAccentDark"))
        }
        .buttonStyle(.plain)
    }
    
    
    
    
    
    
    // MARK: - Action for creating mask
    private func handleNewMask(ofType type: PendingMaskType) {
        switch type {
        case .linear:
            createNewLinearMask()
        case .radial:
            createNewRadialMask()
        case .ai:
            createNewAiMask()
        }
    }
    
    
    private func maskType(for maskId: UUID?) -> String? {
        guard let maskId = maskId,
              let currentImgID = viewModel.currentImgID,
              let item = dataModel.items.first(where: { $0.id == currentImgID }) else {
            return nil
        }
        
        if item.maskSettings.linearGradients.contains(where: { $0.id == maskId }) {
            return "linear"
        } else if item.maskSettings.radialGradients.contains(where: { $0.id == maskId }) {
            return "radial"
        } else {
            return "ai"
        }
    }
    
    @State private var maskCount: Int = 0
    
    private func getCount() {
        guard let currentImgID = viewModel.currentImgID,
              let item = dataModel.items.first(where: { $0.id == currentImgID }) else {
            maskCount = 0
            return
        }
        
        let linearCount = item.maskSettings.linearGradients.count
        let radialCount = item.maskSettings.radialGradients.count
        let aiCount = item.maskSettings.aiMasks.count
        
        maskCount = linearCount + radialCount + aiCount
    }
    
    
    
    
    // MARK: - Create Masks
    
    private func createNewAiMask() {
        selectedMask = nil
        
        samModel.showPoints = true
        viewModel.showMask = false
        viewModel.selectedMask = nil
        samModel.selectedMask = nil
        samModel.currentMask = nil
        
        if viewModel.drawingRadialMask {
            viewModel.drawingRadialMask = false
        }
        if viewModel.drawingLinearMask {
            viewModel.drawingLinearMask = false
        }
        
        
        
        guard selectedMask == nil else { return }
        guard let id = viewModel.currentImgID,
              let item = dataModel.items.first(where: { $0.id == id }) else { return }
        let defaultName = "Ai Mask \(item.maskSettings.linearGradients.count + 1)"
        pendingMaskName = defaultName
        namingMaskId = nil // means we're creating a new mask
        pendingMaskType = .ai
        showingNamePopup = true
        selectedMask = nil
        samModel.currentMask = nil
        
        if !viewModel.sam2MaskMode {
            viewModel.sam2MaskMode = true
        } else {
            viewModel.sam2MaskMode = false
        }
        
        dataModel.updateItem(id: id) { updated in
            updated.maskSettings.selectedMaskID = nil
        }
        viewModel.showMask = false
        viewModel.drawingNewMask = false
        samModel.showSamMask = true
    }
    
    private func createNewLinearMask() {
        selectedMask = nil
        viewModel.showMask = false
        viewModel.selectedMask = nil
        
        viewModel.drawingLinearMask = true
        
        if viewModel.drawingRadialMask {
            viewModel.drawingRadialMask = false
        }
        if viewModel.sam2MaskMode {
            viewModel.sam2MaskMode = false
        }
        
        
        guard selectedMask == nil else { return }
        viewModel.initialMaskDrawn = false
        guard let id = viewModel.currentImgID,
              let item = dataModel.items.first(where: { $0.id == id }) else { return }
        
        let defaultName = "Linear Mask \(item.maskSettings.linearGradients.count + 1)"
        pendingMaskName = defaultName
        namingMaskId = nil // means we're creating a new mask
        pendingMaskType = .linear
        showingNamePopup = true
        selectedMask = nil
        dataModel.updateItem(id: id) { updated in
            updated.maskSettings.selectedMaskID = nil
        }
        viewModel.uiStartPoint = .zero
        viewModel.uiEndPoint = .zero
        viewModel.showMask = true
        viewModel.drawingNewMask = true
    }
    
    
    private func createNewRadialMask() {
        selectedMask = nil
        viewModel.showMask = false
        viewModel.selectedMask = nil
        
        viewModel.radialUiStart = .zero
        viewModel.radialUiEnd = .zero
        viewModel.radialUiWidth = 0
        viewModel.radialUiHeight = 0
        viewModel.radialUiFeather = 50.0
        
        
        viewModel.drawingRadialMask = true
        
        if viewModel.drawingLinearMask {
            viewModel.drawingLinearMask = false
        }
        if viewModel.sam2MaskMode {
            viewModel.sam2MaskMode = false
        }
        
        
        guard selectedMask == nil else { return }
        viewModel.initialMaskDrawn = false
        guard let id = viewModel.currentImgID,
              let item = dataModel.items.first(where: { $0.id == id }) else { return }
        
        let defaultName = "Radial Mask \(item.maskSettings.radialGradients.count + 1)"
        pendingMaskName = defaultName
        namingMaskId = nil // means we're creating a new mask
        
        pendingMaskType = .radial
        showingNamePopup = true
        selectedMask = nil
        dataModel.updateItem(id: id) { updated in
            updated.maskSettings.selectedMaskID = nil
        }
        viewModel.uiStartPoint = .zero
        viewModel.uiEndPoint = .zero
        viewModel.showMask = true
        viewModel.drawingNewMask = true
    }
    
    
    // MARK: - Add Masks
    
    
    private func addAiMask(named name: String) {
        guard let id = viewModel.currentImgID else {
            print("Current Image ID is nil")
            return
        }
        
        
        let newMask = AiMask(
            maskUrl: nil,
            maskImageLoaded: false,
            name: name,
            feather: 5.0,
            invert: false,
            opacity: 100.0,
            maskImage: nil
        )
        
        
        
        // Generate id
        DispatchQueue.main.async {
            dataModel.updateItem(id: id) { updated in
                updated.maskSettings.aiMasks.append(newMask)
                updated.maskSettings.selectedMaskID = newMask.id
                updated.maskSettings.settingsByMaskID[newMask.id] = MaskParameterSet()
            }
            
            
            
            selectedMask = newMask.id
            viewModel.selectedMask = newMask.id
            samModel.selectedMask = newMask.id
        }
    }
    
    
    
    private func addLinearMask(named name: String) {
        guard let id = viewModel.currentImgID else { return }
        
        let newMask = LinearGradientMask(
            name: name,
            startPoint: LinearStartPointBinding,
            endPoint: LinearEndPointBinding
        )
        
        dataModel.updateItem(id: id) { updated in
            updated.maskSettings.linearGradients.append(newMask)
            updated.maskSettings.selectedMaskID = newMask.id
        }
        
        selectedMask = newMask.id
        viewModel.selectedMask = newMask.id
        
        
    }
    
    private func addRadialMask(named name: String) {
        guard let id = viewModel.currentImgID else { return }
        
        let newMask = RadialGradientMask(
            name: name,
            startPoint: .zero,
            endPoint: .zero,
            feather: 50.0,
            width: 0,
            height: 0,
            opacity: 100.0
        )
        
        dataModel.updateItem(id: id) { updated in
            var updatedSettings = updated.maskSettings
            updatedSettings.radialGradients.append(newMask)
            updatedSettings.selectedMaskID = newMask.id
            updatedSettings.selectedMaskType = .radial
            updated.maskSettings = updatedSettings
        }
        
        selectedMask = newMask.id
        viewModel.selectedMask = newMask.id
        
    }
    
    
    
    
    
}


struct MasksView: View {
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var viewModel: ImageViewModel
    
    @Binding var selectedMask: UUID?
    
    // Local display model to unify the three mask types for listing
    private struct MaskListItem: Identifiable {
        enum Kind { case linear, radial, ai }
        let id: UUID
        let name: String
        let kind: Kind
    }
    
    private func maskItems(_ id: UUID) -> [MaskListItem] {
        guard let item = dataModel.items.first(where: { $0.id == id }) else {
            return []
        }
        
        var items: [MaskListItem] = []
        // Order: Linear, Radial, AI
        items += item.maskSettings.linearGradients.map { .init(id: $0.id, name: $0.name, kind: .linear) }
        items += item.maskSettings.radialGradients.map { .init(id: $0.id, name: $0.name, kind: .radial) }
        items += item.maskSettings.aiMasks.map { .init(id: $0.id, name: $0.name, kind: .ai) }
        return items
    }
    
    var body: some View {
        VStack() {
            if let id = viewModel.currentImgID {
                
                let items = maskItems(id)
                
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, mask in
                    maskView(selectedMask: $selectedMask, label: mask.name, maskid: mask.id)
                        .background(idx.isMultiple(of: 2) ? Color("MenuAccentDark")
                                    : Color("MenuAccentLight"))
                }
                
            } else {
                // Fallback when no current image is selected
                Text("No masks")
                    .foregroundStyle(Color("SideBarText"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color("MenuAccentDark"))
            }
        }
        .frame(width: 300)
        .cornerRadius(10)
    }
}

struct maskView: View {
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var viewModel: ImageViewModel
    @EnvironmentObject var samModel: SamModel
    @EnvironmentObject var pipeline: FilterPipeline
    
    @Binding var selectedMask: UUID?
    
    let label: String
    let maskid: UUID

    
    var body: some View {
        
        HStack {
            
            Button(action: {
                viewModel.selectedMask = maskid
                selectedMask = maskid
            }) {
                Text(label)
                    .foregroundStyle(viewModel.selectedMask == maskid ?  Color("IconActive") : Color("SideBarText"))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
            
            Button(action: {
                viewModel.selectedMask = maskid
                selectedMask = maskid
                showSelected(maskid)
            }) {
                Image(systemName: "eye")
                    .foregroundStyle(viewModel.selectedMask == maskid && viewModel.showMask ?  Color("IconActive") : Color("SideBarText"))
            }
            .buttonStyle(PlainButtonStyle())
            
            
            
            Button(action: {
                    deleteSelected(maskid)
            }) {
                Image(systemName: "trash")
                    .foregroundStyle(Color("SideBarText"))
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
                .frame(width: 20)
            
            ZStack {
                Rectangle()
                    .fill(Color .gray)
                    .frame(width: 35, height: 35)
                
                
                Image("mask")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(10)
        
        
    }
    
    
    // MARK: Delete / Rename:
    
    private func showSelected( _ maskId: UUID) {
        print("Attempting to show mask with id: \(maskId)")
        

        
        guard let id = viewModel.currentImgID else {
            return
        }
        guard let item = dataModel.items.first(where: { $0.id == id }) else {
            print("Couldnt get item")
            return
        }
        
        // Check if the selected mask is a linear or radial gradient
        if item.maskSettings.linearGradients.contains(where: { $0.id == maskId }) {
            if viewModel.sam2MaskMode == true {
                viewModel.sam2MaskMode = false
            }
            
            

            DispatchQueue.main.async {
                dataModel.updateItem(id: id) { updated in
                    updated.maskSettings.selectedMaskID = maskId
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.showMask.toggle()
                }
            }

            
            
        } else if item.maskSettings.radialGradients.contains(where: { $0.id == maskId }) {
            if viewModel.sam2MaskMode == true {
                viewModel.sam2MaskMode = false
            }
            

            
            DispatchQueue.main.async {
                dataModel.updateItem(id: id) { updated in
                    updated.maskSettings.selectedMaskID = maskId
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.showMask.toggle()
                }
            }
            
            


            
        } else if item.maskSettings.aiMasks.contains(where: { $0.id == maskId }) {
            if viewModel.sam2MaskMode == false {
                viewModel.sam2MaskMode = true
            }
            
            
            dataModel.updateItem(id: id) { updated in
                updated.maskSettings.selectedMaskID = maskId
            }
            
            samModel.showSamMask.toggle()
            
        }
        
    }
    
    private func deleteSelected(_ maskId: UUID) {
        print("Attempting to delete mask with id: \(maskId)")
        
        guard let id = viewModel.currentImgID else {
            return
        }
        guard let item = dataModel.items.first(where: { $0.id == id }) else {
            print("Couldnt get item")
            return
        }
        
        // Check if the selected mask is a linear or radial gradient
        if item.maskSettings.linearGradients.contains(where: { $0.id == maskId }) {
            
            deleteLinearMask(maskId: maskId)
        } else if item.maskSettings.radialGradients.contains(where: { $0.id == maskId }) {
            deleteRadialMask(maskId: maskId)
        } else if item.maskSettings.aiMasks.contains(where: { $0.id == maskId }) {
            deleteAiMask(maskId: maskId)
        }
    }
    
    
    private func deleteAiMask(maskId: UUID) {
        print("Attempting to delete mask: \(maskId)")
        samModel.showPoints = false
        
        guard let id = viewModel.currentImgID else {
            print("Current Image ID is nil")
            return }
        
        dataModel.updateItem(id: id) { updated in
            // Step 1: Remove the parameter set entirely
            updated.maskSettings.settingsByMaskID.removeValue(forKey: maskId)
            
            // Step 2: Remove the mask itself
            updated.maskSettings.aiMasks.removeAll { $0.id == maskId }
            
            // Step 3: Clear selection
            updated.maskSettings.selectedMaskID = nil
        }
        
        // Update any viewModel-level state tracking
        if selectedMask == maskId {
            selectedMask = nil
        }
        if viewModel.selectedMask == maskId {
            viewModel.selectedMask = nil
        }
        
        
        samModel.currentMask = nil
        samModel.currentMaskCG = nil
        
        // Delay pipeline application slightly so `updateItem` has committed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            pipeline.applyPipelineV2Sync(id, dataModel)
        }
    }
    
    
    private func deleteLinearMask(maskId: UUID) {
        guard let id = viewModel.currentImgID else { return }
        
        dataModel.updateItem(id: id) { updated in
            // Step 1: Remove the parameter set entirely
            updated.maskSettings.settingsByMaskID.removeValue(forKey: maskId)
            
            // Step 2: Remove the mask itself
            updated.maskSettings.linearGradients.removeAll { $0.id == maskId }
            
            // Step 3: Clear selection
            updated.maskSettings.selectedMaskID = nil
        }
        
        // Update any viewModel-level state tracking
        if selectedMask == maskId {
            selectedMask = nil
        }
        if viewModel.selectedMask == maskId {
            viewModel.selectedMask = nil
        }
        
        // Delay pipeline application slightly so `updateItem` has committed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            pipeline.applyPipelineV2Sync(id, dataModel)
        }
    }
    
    private func deleteRadialMask(maskId: UUID) {
        guard let id = viewModel.currentImgID else { return }
        
        dataModel.updateItem(id: id) { updated in
            updated.maskSettings.settingsByMaskID[maskId] = nil
            updated.maskSettings.radialGradients.removeAll { $0.id == maskId }
            updated.maskSettings.selectedMaskID = nil
        }
        
        if selectedMask == maskId {
            selectedMask = nil
        }
        
        if viewModel.selectedMask == maskId {
            viewModel.selectedMask = nil
        }
        
        pipeline.applyPipelineV2Sync(id, dataModel)
        
        // Delay pipeline application slightly so `updateItem` has committed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            pipeline.applyPipelineV2Sync(id, dataModel)
        }
        
    }
    
    private func renameMask(maskId: UUID, newName: String) {
        guard let id = viewModel.currentImgID,
              let imageIndex = dataModel.itemIndexMap[id],
              let maskIndex = dataModel.items[imageIndex].maskSettings.linearGradients.firstIndex(where: { $0.id == maskId }) else {
            return
        }
        
        dataModel.updateItem(id: id) { updated in
            updated.maskSettings.linearGradients[maskIndex].name = newName
        }
    }
    
    
}
