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
        CollapsibleSectionView(
            title: "Print Halation:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Apply:")
                            .foregroundStyle(Color("SideBarText"))
                        Spacer()
                        Toggle("", isOn: $apply)
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                            .padding(.trailing, 0)
							.onChange(of: apply) { newValue in
                                printHalation_apply = newValue
							}
							.onChange(of: viewModel.currentImgID) {
								apply = printHalation_apply
							}
						
                    }
                    
                    HStack {
                        Text("Allow darkening:")
                            .foregroundStyle(Color("SideBarText"))
                        Spacer()
                        Toggle("", isOn: $apply2)
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                            .padding(.trailing, 0)
                            .onChange(of: apply2) { newValue in
                                printHalation_darkenMode = newValue
                            }
                            .onChange(of: viewModel.currentImgID) {
                                apply2 = printHalation_darkenMode
                            }
                        
                    }

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
                        formatter: wholeNumber
                    )
                    .focused($focusedField, equals: "opacityMultiplier")
                }
                .onAppear {
                    focusedField = nil
                    apply2 = printHalation_darkenMode
                }
                .onChange(of: isCollapsed) { newValue in
                    AppDataManager.shared.setCollapsed(newValue, for: "EnlargerView")
                }
            },
            resetAction: {
                printHalation_apply = false
                printHalation_darkenMode = true
                printHalation_size = 10
                printHalation_amount = 50
            }
        )
    }
}
