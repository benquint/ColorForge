//
//  ThogView.swift
//  ColorForge
//
//  Created by Ben Quinton on 24/07/2025.
//

import Foundation
import SwiftUI

struct ThogView: View {
    @EnvironmentObject var pipeline: FilterPipeline
    @EnvironmentObject var viewModel: ImageViewModel
    @FocusState private var focusedField: String?
    
    
    // Add view name
    @State private var isCollapsed: Bool = false

    @Binding var applyTHOG: Bool
    @Binding var blend: Float
    @Binding var variance: Float
    @Binding var scale: Float

    var body: some View {
        
        CollapsibleSectionView(
            title: "THOG:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {

                    // MARK: - Select Stock
                    HStack {
                        Text("Apply:")
                            .foregroundStyle(Color("SideBarText"))
                        Spacer()
                        
                        
                        // MARK: - Apply Grain
                        Toggle("", isOn: $applyTHOG)
                            .toggleStyle(SwitchToggleStyle())
                            .labelsHidden()
                            .padding(.trailing, 0)

                        
                    }
                    .padding(5)
       
                    SliderView(
                        label: "Blend:",
                        binding: $blend,
                        defaultValue: 100.0,
                        range: 0.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )
                    
                    SliderView(
                        label: "Variance:",
                        binding: $variance,
                        defaultValue: 50.0,
                        range: 0.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )
                    
                    
                    SliderView(
                        label: "Scale:",
                        binding: $scale,
                        defaultValue: 30.0,
                        range: 0.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )

                    
                    
                    
                }
                .onAppear {
                    focusedField = nil
                }

            },
            resetAction: {

            }
        )
    }
}
