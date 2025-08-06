//
//  EnlargerView.swift
//  ColorForge
//
//  Created by admin on 27/06/2025.
//

import SwiftUI

struct EnlargerView: View {
	@EnvironmentObject var viewModel: ImageViewModel
    
    @Binding var applyPrintMode: Bool
    @Binding var enlargerExp: Float
    @Binding var enlargerFStop: Float
    @Binding var bwMode: Bool
    @Binding var cyan: Float
    @Binding var magenta: Float
    @Binding var yellow: Float
    @Binding var applyFlash: Bool
    @Binding var useLegacy: Bool
    
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
	
		@State private var printMode: Bool = false

	
	
	var body: some View {
		
		CollapsibleSectionView(
			title: "Enlarger:",
			isCollapsed: $isCollapsed,
			content: {
				VStack(alignment: .leading, spacing: 10) {
					HStack {
						Text("Apply:")
							.foregroundStyle(Color("SideBarText"))
						Spacer()
						
						
						// Apply PrintMode
						Toggle("", isOn: $printMode)
							.toggleStyle(SwitchToggleStyle())
							.labelsHidden()
							.padding(.trailing, 0)
							.onChange(of: printMode) { newValue in
								applyPrintMode = newValue
							}
							.onChange(of: viewModel.currentImgID) {
								printMode = applyPrintMode
							}
					}

                
                        
                        SliderView(
                            label: "Time:",
                            binding: $enlargerExp,
                            defaultValue: 16.0,
                            range: 0.0...30.0,
                            step: 0.1,
                            formatter: twoDecimal
                        )

                        SliderView(
                            label: "Lens Aperture:",
                            binding: $enlargerFStop,
                            defaultValue: 11,
                            range: thirdStopFStops.first!...thirdStopFStops.last!,
                            step: 0.1,
                            formatter: twoDecimal
                        )
                        .onChange(of: enlargerFStop) { newValue in
                            let closest = thirdStopFStops.min(by: { abs($0 - newValue) < abs($1 - newValue) }) ?? 11.0
                            enlargerFStop = closest
                        }

                        SliderView(
                            label: "Cyan:",
                            binding: $cyan,
                            defaultValue: 0,
                            range: 0.0...200.0,
                            step: 0.1,
                            formatter: wholeNumber
                        )

                        SliderView(
                            label: "Magenta:",
                            binding: $magenta,
                            defaultValue: 48,
                            range: 0.0...200.0,
                            step: 0.1,
                            formatter: wholeNumber
                        )

                        SliderView(
                            label: "Yellow:",
                            binding: $yellow,
                            defaultValue: 87,
                            range: 0.0...200.0,
                            step: 0.1,
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
                enlargerExp = 16.0
                enlargerFStop = 11.0
                cyan = 0.0
                magenta = 46.0
                yellow = 87.0
			}
		)
	}
}
