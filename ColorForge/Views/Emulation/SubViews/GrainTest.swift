//
//  GrainTest.swift
//  ColorForge
//
//  Created by Ben Quinton on 09/08/2025.
//


import SwiftUI

struct GrainTest: View {
    @EnvironmentObject var viewModel: ImageViewModel
    
    @FocusState private var focusedField: String?

    // Add view name
    @State private var isCollapsed: Bool = false

    var body: some View {
        SubSection(
            title: "Grain Test",
            icon: "film",
            isCollapsed: $isCollapsed,
            resetAction: {
                
            },
            content: {
                VStack {
                    
                    // Need binding to viewModel.downAndUpScale
                    TextField(
                        "Down & Up Scale",
                        text: Binding(
                            get: { "\(viewModel.downAndUpScale)" },
                            set: { newValue in
                                if let value = Double(newValue) {
                                    viewModel.downAndUpScale = CGFloat(value)
                                }
                            }
                        )
                    )
                    .focused($focusedField, equals: "downAndUpScale")
                }
            }
        )
    }
}
