//
//  PrintHalationView.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import SwiftUI

struct PrintHalationView: View {
    @EnvironmentObject var viewModel: ImageViewModel
    
    @Binding var printHalation_size: Float
    @Binding var printHalation_amount: Float
    @Binding var printHalation_darkenMode: Bool
    @Binding var printHalation_apply: Bool
    
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = false
    
    @State private var apply: Bool = false
    @State private var apply2: Bool = false
    
    var body: some View {
        SubSection(
            title: "Print Halation",
            icon: "drop.triangle",
            checkBoxBinding: $apply,
            isCollapsed: $isCollapsed,
            resetAction: {
                printHalation_apply = false
                printHalation_darkenMode = false
                printHalation_size = 10
                printHalation_amount = 50
            },
            content: {
                VStack() {
                    
                    
                    
                    
                    // Radius
                    SliderView(
                        label: "Size:",
                        binding: $printHalation_size,
                        defaultValue: 10,
                        range: 1...100,
                        step: 1,
                        formatter: twoDecimal
                    )
                    .focused($focusedField, equals: "radiusMultiplier")
                    
                    // Fade
                    SliderView(
                        label: "Amount:",
                        binding: $printHalation_amount,
                        defaultValue: 50,
                        range: 0...100,
                        step: 1,
                        formatter: wholeNumber)
                    .focused($focusedField, equals: "opacityMultiplier")
                    
                    
                    Spacer()
                        .frame(height: 20)
                    
                    HStack {
                        Text("Allow darkening:")
                            .foregroundStyle(Color("SideBarText"))
                        Spacer()
                            .frame(width: 10)
                        
                        CheckBox(isOn: $apply2)
                        
                        Spacer()
                        
                        
                        
                    }
                    
                    
                }
                .onChange(of: apply) {
                    printHalation_apply = apply
                }
                .onChange(of: viewModel.currentImgID) {
                    apply = printHalation_apply
                }
                .onAppear {
                    focusedField = nil
                    apply = printHalation_apply
                    apply2 = printHalation_darkenMode
                }
                
                .onChange(of: apply2) {
                    printHalation_darkenMode = apply2
                }
                .onChange(of: viewModel.currentImgID) {
                    apply2 = printHalation_darkenMode
                }
            }
            
        )
    }
}
