//
//  MaskIcons.swift
//  ColorForge
//
//  Created by admin on 05/07/2025.
//

import SwiftUI

struct MaskIcons: View {
    @EnvironmentObject var pipeline: FilterPipeline
    @EnvironmentObject var viewModel: ImageViewModel
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var samModel: SamModel
    
    @State private var showingNamePopup = false
    @State private var namingMaskId: UUID? = nil
    @State private var pendingMaskName: String = ""
    
    
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
    
    
    @State private var pendingMaskType: PendingMaskType = .linear
    private enum PendingMaskType {
        case linear
        case radial
        case ai
    }
    
   
    
    var body: some View {
        HStack{
            
            Spacer()
            
            // Linear Mask
            VStack {
                Button(action: {
                    selectedMask = nil
                    viewModel.showMask = false
                    viewModel.selectedMask = nil
//                    viewModel.maskingActive = false
                    
                    
                    createNewLinearMask()
                    viewModel.drawingLinearMask = true
                    
                    if viewModel.drawingRadialMask {
                        viewModel.drawingRadialMask = false
                    }
                    if viewModel.sam2MaskMode {
                        viewModel.sam2MaskMode = false
                    }
                    
                    print("""
                        
                        
                        DrawingLinearMask = \(viewModel.drawingLinearMask)
                        DrawingRadialMask = \(viewModel.drawingRadialMask)
                        
                        
                        """)
                }) {
                    Image(systemName: "square.bottomhalf.filled")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(viewModel.drawingLinearMask ? Color("IconActive") : Color("SideBarText"))
                        .padding(5)
                        .frame(width: 40, height: 40)
                        .help("Draw Linear Mask")
                }
                .buttonStyle(PlainButtonStyle())
				.keyboardShortcut("g", modifiers: [])
                
                Text("Linear")
                    .font(.caption)
                    .foregroundColor(Color("SideBarText"))
                
            }
            .padding(10)
            
            
            Spacer()
            
            
            // Radial Mask
            VStack{
                Button(action: {
                    selectedMask = nil
                    viewModel.showMask = false
                    viewModel.selectedMask = nil
                    
                    viewModel.radialUiStart = .zero
                    viewModel.radialUiEnd = .zero
                    viewModel.radialUiWidth = 0
                    viewModel.radialUiHeight = 0
                    viewModel.radialUiFeather = 50.0
                    
                    
                    createNewRadialMask()
                    
                    viewModel.drawingRadialMask = true
                    
                    if viewModel.drawingLinearMask {
                        viewModel.drawingLinearMask = false
                    }
                    if viewModel.sam2MaskMode {
                        viewModel.sam2MaskMode = false
                    }
                    
                    
                }) {
                    Image(systemName: "circle.bottomhalf.filled")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(viewModel.drawingRadialMask ? Color("IconActive") : Color("SideBarText"))
                        .padding(5)
                        .frame(width: 40, height: 40)
                        .help("Draw Linear Mask")
                }
                .buttonStyle(PlainButtonStyle())
				.keyboardShortcut("j", modifiers: [])
				
                Text("Radial")
                    .font(.caption)
                
            }
            .padding(10)
            
            
            Spacer()
            
            // AI Mask
            VStack {
                Button(action: {
                    selectedMask = nil
                    viewModel.showMask = false
                    viewModel.selectedMask = nil
                    samModel.selectedMask = nil
                    samModel.currentMask = nil
                    
                    
                    createNewAiMask()
                    

                    
                    if viewModel.drawingRadialMask {
                        viewModel.drawingRadialMask = false
                    }
                    if viewModel.drawingLinearMask {
                        viewModel.drawingLinearMask = false
                    }
				}) {
                    Image(systemName: "wand.and.stars.inverse")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(viewModel.sam2MaskMode ? Color("IconActive") : Color("SideBarText"))
                        .padding(5)
                        .frame(width: 40, height: 40)
                        .help("Draw Linear Mask")
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("AI")
                    .font(.caption)
                
            }
            .padding(10)
            
            Spacer()
            
            // Sky Mask
            VStack {
                Button(action: {}) {
                    Image(systemName: "cloud.sun.circle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color("SideBarText"))
                        .padding(5)
                        .frame(width: 40, height: 40)
                        .help("Sky")
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("Linear")
                    .font(.caption)
                
            }
            .padding(10)
            
            
            Spacer()
            
            
        } // End of Icons
        .background(Color("MenuBackground"))
        .padding(0)
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
    }
    
    
    private func createNewAiMask() {
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
    
    
    private func createNewLinearMask() {
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
        

//        Task {
//            await pipeline.applyPipelineV2(id, dataModel)
//        }
    }
    
}
