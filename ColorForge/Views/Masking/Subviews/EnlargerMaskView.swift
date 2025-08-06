//
//  EnlargerMaskView.swift
//  ColorForge
//
//  Created by admin on 05/07/2025.
//

import SwiftUI

struct EnlargerMaskView: View {
	@Binding var applyPrintMode: Bool
	@Binding var enlargerExp: Float
	@Binding var enlargerFStop: Float
	@Binding var bwMode: Bool
	@Binding var cyan: Float
	@Binding var magenta: Float
	@Binding var yellow: Float
	@Binding var applyFlash: Bool
	@Binding var useLegacy: Bool
    
    
    @Binding var mainApplyPrint: Bool
	
	@FocusState private var focusedField: String?
	
	@EnvironmentObject var viewModel: ImageViewModel
	
	// Add view name
	@State private var isCollapsed: Bool = false
	

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
			title: "Enlarger:",
			isCollapsed: $isCollapsed,
			content: {
				VStack(alignment: .leading, spacing: 10) {
                    
                    
                    
						// MARK: - Legacy
						SliderView(
							label: "Exposure:",
							binding: $enlargerExp,
							defaultValue: 0,
                            range: -2.0...2.0,
							step: 0.1,
							formatter: twoDecimal
						)

						SliderView(
							label: "Cyan:",
							binding: $cyan,
							defaultValue: 0,
							range: -50.0...50.0,
							step: 0.1,
							formatter: wholeNumber
						)

						SliderView(
							label: "Magenta:",
							binding: $magenta,
							defaultValue: 0,
							range: -50.0...50.0,
							step: 0.1,
							formatter: wholeNumber
						)

						SliderView(
							label: "Yellow:",
							binding: $yellow,
							defaultValue: 0,
							range: -50.0...50.0,
							step: 0.1,
							formatter: wholeNumber
						)

					
				}
				.onAppear {
					focusedField = nil
                    applyPrintMode = mainApplyPrint
				}
                .onChange(of: mainApplyPrint) {
                    applyPrintMode = mainApplyPrint
                }
				.onChange(of: viewModel.drawingNewMask) {
                    
					guard viewModel.drawingNewMask, let _ = viewModel.selectedMask else { return }
					
					DispatchQueue.main.async {
						enlargerExp = 0.0
						enlargerFStop = 11.0
						cyan = 0.0
                        magenta = 0.0
                        yellow = 0.0
					}
				}
			},
			resetAction: {
				enlargerExp = 0.0
				enlargerFStop = 11.0
				cyan = 0.0
				magenta = 0.0
				yellow = 0.0
			}
		)
	}
}
