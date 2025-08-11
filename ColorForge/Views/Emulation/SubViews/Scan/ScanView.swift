//
//  ScanView.swift
//  ColorForge
//
//  Created by Ben Quinton on 04/08/2025.
//

import SwiftUI

struct ScanView: View {
    @EnvironmentObject var viewModel: ImageViewModel
    
    @Binding var applyPrintMode: Bool
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
    
    @FocusState private var focusedField: String?
    
    
    
    // Add view name
    @State private var isCollapsed: Bool = AppDataManager.shared.isCollapsed(for: "EnlargerView")
    

    
    @State private var apply: Bool = false
    @State private var applyLUT: Bool = false
    
    @State private var isCineon = false
    @State private var isLut = false
    @State private var isImacon = false
    @State private var isMiniLab = false
    
    
    @State private var lutType: LutSelection = .kodak
    @State private var lutPopoverPresented = false
    
    enum LutSelection: Int, CaseIterable {
        case kodak
        case fuji
        case custom

        var title: String {
            switch self {
            case .kodak: return "Kodak 2383"
            case .fuji: return "Fujifilm 3513"
            case .custom: return "Load custom..."
            }
        }
    }
    

    
    var body: some View {
        
        SubSection(
            title: "Scan",
            icon: "film",
            checkBoxBinding: $apply,
            isCollapsed: $isCollapsed,
            resetAction: {
                apply = false
                applyLUT = false
                offsetRGB = 0.0
                lutBlend = 100.0
                scanContrast = 0.0
                offsetRed = 0.0
                offsetGreen = 0.0
                offsetBlue = 0.0
            },
            content: {
                VStack() {
                    

                    ScanChoiceView(isOn: $apply, isCineon: $isCineon, isLut: $isLut, isImacon: $isImacon, isMiniLab: $isMiniLab)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    if isLut {
                        VStack {
                            HStack {
                                Button {
                                    lutPopoverPresented.toggle()
                                } label: {
                                    HStack {
                                        Image(systemName: "cube")
                                        
                                        Text(lutType.title)
                                            .foregroundColor(Color("SideBarText"))
                                    }
                                }
                                .contentShape(Rectangle())
                                .buttonStyle(.plain)
                                .popover(isPresented: $lutPopoverPresented, arrowEdge: .bottom) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        ForEach(LutSelection.allCases.indices, id: \.self) { index in
                                            popoverOption(index: index,
                                                          type: LutSelection.allCases[index],
                                                          title: LutSelection.allCases[index].title)
                                        }
                                    }
                                    .background(Color("MenuAccent"))
                                    .frame(width: 180)
                                }
                                
                                Spacer().frame(width: 10)
                                Image(systemName: lutPopoverPresented ? "chevron.down" : "chevron.right")
                                    .foregroundColor(Color("SideBarText").opacity(0.7))
                                
                                Spacer()
                            }
                            
                            
                            Spacer().frame(height: 15)
                            
                            
                            
                            SliderView(
                                label: "LUT Blend:",
                                binding: $lutBlend,
                                defaultValue: 100.0,
                                range: 0...100.0,
                                step: 1,
                                formatter: wholeNumber
                            )
                            
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                    }
                    
                    
                    SliderView(
                        label: "Exposure:",
                        binding: $offsetRGB,
                        defaultValue: 0.0,
                        range: -100.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )
                    
                    SliderView(
                        label: "Contrast:",
                        binding: $scanContrast,
                        defaultValue: 0.0,
                        range: -100.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )
                    
                    SliderView(
                        label: "Red:",
                        binding: $offsetRed,
                        defaultValue: 0.0,
                        range: -100.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )
                    
                    SliderView(
                        label: "Green:",
                        binding: $offsetGreen,
                        defaultValue: 0.0,
                        range: -100.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )
                    
                    SliderView(
                        label: "Blue:",
                        binding: $offsetBlue,
                        defaultValue: 0.0,
                        range: -100.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )

                    
                    
                    
                    
                }
                .onChange(of: apply) { newValue in
                    applyScanMode = newValue
                    if apply == true {
                        applyPrintMode = false
                    }
                }
                .onChange(of: viewModel.currentImgID) {
                    apply = applyScanMode
                }
                .onChange(of: applyPrintMode) {
                    if applyPrintMode == true {
                        apply = false
                    }
                }
                
                .onChange(of: applyPFE) {
                    isLut = applyPFE
                }
                .onAppear{
                    isLut = applyPFE
                }
                
                .onChange(of: isLut) {
                    applyPFE = isLut
                }
                
                
                
                .onAppear{
                    apply = applyScanMode
                    applyLUT = applyPFE
                    focusedField = nil
                }
                .onChange(of: isCollapsed) { newValue in
                    AppDataManager.shared.setCollapsed(newValue, for: "EnlargerView")
                }
                .onChange(of: applyLUT) { newValue in
                    applyPFE = newValue

                }
                .onChange(of: viewModel.currentImgID) {
                    applyLUT = applyPFE
                }
            }

        )
    }
    
    private func popoverOption(index: Int, type: LutSelection, title: String) -> some View {
        Button {
            lutType = type
            lutPopoverPresented = false

            
            // Set based on selection (ignore custom)
            switch type {
            case .kodak:
                apply2383 = true
                apply3513 = false
            case .fuji:
                apply2383 = false
                apply3513 = true
            case .custom:
                apply2383 = false
                apply3513 = false
            }
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(Color("SideBarText"))
                Spacer()
            }
            .padding(10)
            .background(index.isMultiple(of: 2) ? Color("MenuAccentDark") : Color("MenuAccentLight"))
        }
        .buttonStyle(.plain)
    }
    
}
