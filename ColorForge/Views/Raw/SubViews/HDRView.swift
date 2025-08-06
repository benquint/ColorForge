//
//  HDRView.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import Foundation
import SwiftUI



struct HDRView: View {
    @Binding var hdrWhite: Float
    @Binding var hdrHighlight: Float
    @Binding var hdrShadow: Float
    @Binding var hdrBlack: Float

	@FocusState private var focusedField: String?

	// Add view name
	@State private var isCollapsed: Bool = false

	var body: some View {
		
		CollapsibleSectionView(
			title: "HDR:",
			isCollapsed: $isCollapsed,
			content: {
				VStack(alignment: .leading, spacing: 10) {

					
                    SliderView(
                        label: "Whites:",
                        binding: $hdrWhite,
                        defaultValue: 0,
                        range: -100.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )

                    SliderView(
                        label: "Highlights:",
                        binding: $hdrHighlight,
                        defaultValue: 0,
                        range: -100.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )

                    SliderView(
                        label: "Shadows:",
                        binding: $hdrShadow,
                        defaultValue: 0,
                        range: -100.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )

                    SliderView(
                        label: "Blacks:",
                        binding: $hdrBlack,
                        defaultValue: 0,
                        range: -100.0...100.0,
                        step: 1,
                        formatter: wholeNumber
                    )


				}
				.onAppear {
					focusedField = nil
				}
				.onChange(of: isCollapsed) { newValue in
					AppDataManager.shared.setCollapsed(newValue, for: "HDRView")
				}
			},
			resetAction: {
                hdrWhite = 0
                hdrHighlight = 0
                hdrShadow = 0
                hdrBlack = 0
			}
		)
	}
}

