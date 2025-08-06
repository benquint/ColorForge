//
//  TomView.swift
//  ColorForge
//
//  Created by Ben Quinton on 26/07/2025.
//

import SwiftUI

struct TomView: View {
        @EnvironmentObject var viewModel: ImageViewModel
        
    @Binding var applyTom: Bool


        @FocusState private var focusedField: String?
        @State private var isCollapsed: Bool = false
        
        @State private var apply: Bool = false

        var body: some View {
            CollapsibleSectionView(
                title: "Tom Jamieson Filter:",
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
                                    applyTom = newValue
                                }
                                .onChange(of: viewModel.currentImgID) {
                                    apply = applyTom
                                }
                            
                        }

                    }
                    .onAppear {
                        focusedField = nil
                    }
                    .onChange(of: isCollapsed) { newValue in
                        AppDataManager.shared.setCollapsed(newValue, for: "EnlargerView")
                    }
                },
                resetAction: {
                }
            )
        }
    }
