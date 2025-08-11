//
//  MaskInfoView.swift
//  ColorForge
//
//  Created by admin on 05/07/2025.
//

import SwiftUI

struct MaskInfoViewOld: View {
    
    @EnvironmentObject var pipeline: FilterPipeline
    @EnvironmentObject var viewModel: ImageViewModel
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var samModel: SamModel
    
    @FocusState private var focusedField: String?
    
    @State private var radialMaskIcon = "circle.righthalf.filled"
    @State private var linearGradientIcon = "square.bottomhalf.filled"
    
    
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
    
    //	@Binding var currentMask: UUID?
    
    var body: some View {
        // Outer VStack
        VStack  {
            

            
            HStack {
                Text("Invert Mask:")
                Spacer()
                
                Toggle("", isOn: viewModel.sam2MaskMode ? $aiInvert : $radialInvertBinding)
                    .toggleStyle(SwitchToggleStyle())
                    .labelsHidden()
                    .padding(.trailing, 0)
                    .onChange(of: aiInvert) {
                        aiInvertBinding = aiInvert
                        samModel.updateMask(dataModel)
                    }
                    .onChange(of: aiInvertBinding) {
                        aiInvert = aiInvertBinding
                    }
                    .onAppear{
                        aiInvert = aiInvertBinding
                    }
            }
			
			
			// Delete mask hidden
			Button(action: {
				deleteSelected()
			}) {
				Image(systemName: "trash")
					.resizable()
					.foregroundColor(Color("SideBarText"))
					.frame(width: 1, height: 1)
					.padding(0)
					
			}
			.opacity(0)
			.padding(0)
			.buttonStyle(PlainButtonStyle())
			.keyboardShortcut(.delete, modifiers: [])
		
            if viewModel.sam2MaskMode {
                Spacer().frame(height: 20)
                
                // Tool selection
                HStack {
                    Text("Select Tool:")
                    Spacer()
                    Picker(selection: $selectedTool, content: {
                        ForEach(tools, id: \.self) { tool in
                            Label(tool.name, systemImage: tool.iconName)
                                .tag(tool)
                                .labelStyle(.titleAndIcon)
                        }
                    }, label: {
                    })
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }
                
                Spacer().frame(height: 20)
                
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
                        Text("Add to mask")
                            .foregroundStyle(samModel.addToMask ? Color("IconActive") : Color("SideBarText"))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: {
                        if samModel.subtractFromMask {
                            samModel.subtractFromMask = false
                        } else {
                            samModel.subtractFromMask = true
                            samModel.addToMask = false
                        }
                    }) {
                        Text("Subtract from mask")
                            .foregroundStyle(samModel.subtractFromMask ? Color("IconActive") : Color("SideBarText"))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        samModel.showSamMask.toggle()
                    }) {
                        Image(systemName: "eye")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(Color("SideBarText"))
                            .frame(width: 30)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                
                Spacer().frame(height: 20)
            }
			
            
            
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
            
            // Scroll content depends on whether we found the current item
            if let id = viewModel.currentImgID,
               let item = dataModel.items.first(where: { $0.id == id }) {
                
                ScrollView {
                    ForEach(item.maskSettings.linearGradients, id: \.id) { mask in
                        HStack {
                            Text(mask.name)
                                .font(.system(.caption, weight: .light))
                                .foregroundColor(viewModel.selectedMask == mask.id ? Color("IconActive") : Color("SideBarText"))
                                .onTapGesture(count: 1) {
                                    viewModel.selectedMask = mask.id
                                    selectedMask = mask.id
                                    dataModel.updateItem(id: id) { updated in
                                        updated.maskSettings.selectedMaskID = mask.id
                                    }
                                }
                                .onTapGesture(count: 2) {
                                    pendingMaskName = mask.name
                                    namingMaskId = mask.id
                                    selectedMask = mask.id
                                    dataModel.updateItem(id: id) { updated in
                                        updated.maskSettings.selectedMaskID = mask.id
                                    }
                                    viewModel.selectedMask = mask.id
                                    showingNamePopup = true
                                }
                            
                            
                            
                            Image(systemName: linearGradientIcon)
                                .foregroundColor(viewModel.selectedMask == mask.id ? Color("IconActive") : Color("SideBarText"))
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.selectedMask = mask.id
                                viewModel.showMask.toggle()
                            }) {
                                Image(systemName: "eye")
                                    .foregroundColor(viewModel.selectedMask == mask.id && viewModel.showMask ? Color("IconActive") : Color("SideBarText"))
                            }
                            
                            Button(action: {
                                deleteLinearMask(maskId: mask.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(Color("SideBarText"))
                            }
                        }
                        .padding(5)
                        .frame(width: 260)
                    }
                    
                    ForEach(item.maskSettings.radialGradients, id: \.id) { mask in
                        HStack {
                            Text(mask.name)
                                .font(.system(.caption, weight: .light))
                                .foregroundColor(viewModel.selectedMask == mask.id ? Color("IconActive") : Color("SideBarText"))
                                .onTapGesture(count: 1) {
                                    viewModel.selectedMask = mask.id
                                    selectedMask = mask.id
                                    dataModel.updateItem(id: id) { updated in
                                        updated.maskSettings.selectedMaskID = mask.id
                                    }
                                }
                                .onTapGesture(count: 2) {
                                    pendingMaskName = mask.name
                                    namingMaskId = mask.id
                                    selectedMask = mask.id
                                    dataModel.updateItem(id: id) { updated in
                                        updated.maskSettings.selectedMaskID = mask.id
                                    }
                                    viewModel.selectedMask = mask.id
                                    showingNamePopup = true
                                }
                            
                            
                            
                            Image(systemName: radialMaskIcon)
                                .foregroundColor(viewModel.selectedMask == mask.id ? Color("IconActive") : Color("SideBarText"))
                            
                            Spacer()
                            
                            Button(action: {
                                viewModel.selectedMask = mask.id
                                viewModel.showMask.toggle()
                            }) {
                                Image(systemName: "eye")
                                    .foregroundColor(viewModel.selectedMask == mask.id && viewModel.showMask ? Color("IconActive") : Color("SideBarText"))
                            }
                            
                            Button(action: {
                                deleteRadialMask(maskId: mask.id)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(Color("SideBarText"))
                            }
                        }
                        .padding(5)
                        .frame(width: 260)
                    }
                    
                    
                }
                .frame(maxHeight: 200)
                .background(Color("MenuAccent"))
            }
                
            
        }
        .padding(10)
        .background(Color("MenuBackground"))
//        .frame(width: 300, height: 300)

    }
    
    
    // MARK: - Add / Delete Masks
    
    private func addLinearMask(named name: String) {
        guard let id = viewModel.currentImgID else { return }
        
        let newMask = LinearGradientMask(
            name: name,
            startPoint: .zero,
            endPoint: .zero
        )
        
        dataModel.updateItem(id: id) { updated in
            var updatedSettings = updated.maskSettings
            updatedSettings.linearGradients.append(newMask)
            updatedSettings.selectedMaskID = newMask.id
            updatedSettings.selectedMaskType = .linear
            updated.maskSettings = updatedSettings
        }
        
        selectedMask = newMask.id
        viewModel.selectedMask = newMask.id
        

      pipeline.applyPipelineV2Sync(id, dataModel)
        
    }
	
	private func deleteSelected() {
		guard let maskId = viewModel.selectedMask,
			  let id = viewModel.currentImgID,
			  let item = dataModel.items.first(where: { $0.id == id }) else {
			return
		}
		
		// Check if the selected mask is a linear or radial gradient
		if item.maskSettings.linearGradients.contains(where: { $0.id == maskId }) {
			deleteLinearMask(maskId: maskId)
		} else if item.maskSettings.radialGradients.contains(where: { $0.id == maskId }) {
			deleteRadialMask(maskId: maskId)
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


// Mask name view

