//
//  PrintFlashView.swift
//  ColorForge
//
//  Created by Ben Quinton on 10/07/2025.
//


import SwiftUI

struct PrintFlashView: View {
    @Binding var applyPrintMode: Bool
    @Binding var applyFlash: Bool
    @Binding var previewFlash: Bool
    @Binding var flashEV: Float
    @Binding var flashFStop: Float
    @Binding var flashCyan: Float
    @Binding var flashMagenta: Float
    @Binding var flashYellow: Float

    
    @FocusState private var focusedField: String?
    
    
    
    // Add view name
    @State private var isCollapsed: Bool = true
    

    let thirdStopFStops: [Float] = [
        2.8, 3.2, 3.5, 4.0,
        4.5, 5.0, 5.6,
        6.3, 7.1, 8.0,
        9.0, 10.0, 11.0,
        13.0, 14.0, 16.0,
        18.0, 20.0, 22.0
    ]
    
    
    var body: some View {
        
        CollapsibleSectionView(
            title: "Print Flash:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Apply:")
                            .foregroundStyle(Color("SideBarText"))
                        Spacer()
                        
                        
                        // Apply PrintMode
                        Toggle("", isOn: $applyFlash)
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                            .padding(.trailing, 0)
                    }
                    
                    HStack {
                        Text("Preview:")
                            .foregroundStyle(Color("SideBarText"))
                        Spacer()
                        
                        
                        // Apply PrintMode
                        Toggle("", isOn: $previewFlash)
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                            .padding(.trailing, 0)
                    }
                    
                    
                        
                        SliderView(
                            label: "Time:",
                            binding: $flashEV,
                            defaultValue: 16.0,
                            range: 0.0...30.0,
                            step: 0.1,
                            formatter: twoDecimal
                        )

                        SliderView(
                            label: "Lens Aperture:",
                            binding: $flashFStop,
                            defaultValue: 11,
                            range: thirdStopFStops.first!...thirdStopFStops.last!,
                            step: 0.1,
                            formatter: twoDecimal
                        )
                        .onChange(of: flashFStop) { newValue in
                            let closest = thirdStopFStops.min(by: { abs($0 - newValue) < abs($1 - newValue) }) ?? 11.0
                            flashFStop = closest
                        }

                        SliderView(
                            label: "Cyan:",
                            binding: $flashCyan,
                            defaultValue: 0,
                            range: 0.0...200.0,
                            step: 0.1,
                            formatter: wholeNumber
                        )

                        SliderView(
                            label: "Magenta:",
                            binding: $flashMagenta,
                            defaultValue: 48,
                            range: 0.0...200.0,
                            step: 0.1,
                            formatter: wholeNumber
                        )

                        SliderView(
                            label: "Yellow:",
                            binding: $flashYellow,
                            defaultValue: 87,
                            range: 0.0...200.0,
                            step: 0.1,
                            formatter: wholeNumber
                        )
                    
                    
                    
                    
                }
                .disabled(!applyPrintMode)
                .opacity(applyPrintMode ? 1.0 : 0.5)
                .onAppear {
                    focusedField = nil
                }
                .onChange(of: isCollapsed) { newValue in
                    AppDataManager.shared.setCollapsed(newValue, for: "EnlargerView")
                }

            },
            resetAction: {
                applyFlash = false
                previewFlash = false
                flashEV = 16.0
                flashFStop = 11.0
                flashCyan = 0.0
                flashMagenta = 46.0
                flashYellow = 87.0
            }
        )
    }
}
