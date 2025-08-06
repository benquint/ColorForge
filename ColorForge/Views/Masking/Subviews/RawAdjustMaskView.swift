//
//  RawAdjustMaskView.swift
//  ColorForge
//
//  Created by admin on 05/07/2025.
//


import Foundation
import SwiftUI

struct RawAdjustMaskView: View {
	@EnvironmentObject var viewModel: ImageViewModel
	@FocusState private var focusedField: String?
	@State private var isCollapsed: Bool = true

	@Binding var exposure: Float
	@Binding var contrast: Float
	@Binding var saturation: Float

	var body: some View {
		CollapsibleSectionView(
			title: "Exposure :",
			isCollapsed: $isCollapsed,
			content: {
				VStack(alignment: .leading, spacing: 10) {

					SliderView(
						label: "Exposure:",
						binding: $exposure,
						defaultValue: 0,
						range: -4.0...4.0,
						step: 0.1,
						formatter: twoDecimal
					)

					SliderView(
						label: "Contrast:",
						binding: $contrast,
						defaultValue: 0,
						range: -100.0...100.0,
						step: 1,
						formatter: wholeNumber
					)

					SliderView(
						label: "Saturation:",
						binding: $saturation,
						defaultValue: 0,
						range: -100.0...100.0,
						step: 1,
						formatter: wholeNumber
					)
				}
				.onAppear {
					focusedField = nil
				}
//				onChange(of: viewModel.drawingNewMask) {
//					if viewModel.drawingNewMask {
//						$exposure.reset(to: 0)
//						$contrast.reset(to: 0)
//						$saturation.reset(to: 0)
//						
//					}
//				}
			},
			resetAction: {
				$exposure.reset(to: 0)
				$contrast.reset(to: 0)
				$saturation.reset(to: 0)
			}
		)
	}
}
