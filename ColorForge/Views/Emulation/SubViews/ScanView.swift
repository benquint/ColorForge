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
    @Binding var offsetRGB: Float
    @Binding var offsetRed: Float
    @Binding var offsetGreen: Float
    @Binding var offsetBlue: Float
    @Binding var scanContrast: Float
    @Binding var lutBlend: Float
    
    @FocusState private var focusedField: String?
    
    
    
    // Add view name
    @State private var isCollapsed: Bool = AppDataManager.shared.isCollapsed(for: "EnlargerView")
    
    
    let thirdStopFStops: [Float] = [
        2.8, 3.2, 3.5, 4.0,
        4.5, 5.0, 5.6,
        6.3, 7.1, 8.0,
        9.0, 10.0, 11.0,
        13.0, 14.0, 16.0,
        18.0, 20.0, 22.0]
    
    @State private var apply: Bool = false
    @State private var applyLUT: Bool = false
    
    
    
    var body: some View {
        
        CollapsibleSectionView(
            title: "Scan:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Apply:")
                            .foregroundStyle(Color("SideBarText"))
                        Spacer()
                        
                        
                        // Apply PrintMode
                        Toggle("", isOn: $apply)
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                            .padding(.trailing, 0)
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
                            .onAppear{
                                apply = applyScanMode
                            }
                        
                    }
                    
                    
                    HStack {
                        Text("Apply LUT:")
                            .foregroundStyle(Color("SideBarText"))
                        Spacer()
                        
                        
                        // Apply PrintMode
                        Toggle("", isOn: $applyLUT)
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                            .padding(.trailing, 0)
                            .onChange(of: applyLUT) { newValue in
                                applyPFE = newValue
            
                            }
                            .onChange(of: viewModel.currentImgID) {
                                applyLUT = applyPFE
                            }
                            .onAppear{
                                applyLUT = applyPFE
                            }
                        
                    }
                    
                    SliderView(
                        label: "LUT Blend:",
                        binding: $lutBlend,
                        defaultValue: 100.0,
                        range: 0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )
                    
                    
                    
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
                .onAppear {
                    focusedField = nil
                }
                .onChange(of: isCollapsed) { newValue in
                    AppDataManager.shared.setCollapsed(newValue, for: "EnlargerView")
                }
                
            },
            resetAction: {
                apply = false
                applyLUT = false
                offsetRGB = 0.0
                lutBlend = 100.0
                scanContrast = 0.0
                offsetRed = 0.0
                offsetGreen = 0.0
                offsetBlue = 0.0
            }
        )
    }
}
