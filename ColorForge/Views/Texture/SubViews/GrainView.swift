//
//  GrainView.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import SwiftUI

struct GrainView: View {
    @EnvironmentObject var viewModel: ImageViewModel
    
    @Binding var applyGrain: Bool
    @Binding var grainAmount: Float
    @Binding var selectedGateWidth: Int // Supplied to both grain and mtf view
    @Binding var scaleGrainToFormat: Bool
    
	@FocusState private var focusedField: String?

	// Add view name
	@State private var isCollapsed: Bool = AppDataManager.shared.isCollapsed(for: "GrainView")
	

    private var gateWidthBinding: Binding<GateWidth> {
        Binding<GateWidth>(
            get: {
                GateWidth(rawValue: selectedGateWidth) ?? .largeFormat54
            },
            set: { newValue in
                selectedGateWidth = newValue.rawValue
            }
        )
    }
	
	enum GateWidth: Int {
		case mediumFormat = 0               // 60.0 mm
		case cropMedium = 1                 // 43.8 mm
		case thirtyFive = 2                 // 36.0 mm
		case halfFrame = 3                  // 18.0 mm
		case motion35Standard = 4           // 21.95 mm
		case motion35Super = 5              // 24.89 mm
		case motion16 = 6                   // 10.26 mm
		case motion8 = 7                    // 4.8 mm
		case motionSuper8 = 8               // 5.79 mm
        case largeFormat54 = 9
	}

	@State private var apply: Bool = false

	var body: some View {
		
		SubSection(
			title: "Grain",
			icon: "film",
			checkBoxBinding: $apply,
			isCollapsed: $isCollapsed,
			resetAction: {
				applyGrain = false
//				selectedGateWidth = 0
//				grainAmount = 0
			},
			content: {
				VStack() {

//					// Exposure Slider
//					HStack {
//						Text("Format:")
//							.foregroundStyle(Color("SideBarText"))
//						Spacer()
//						
//						
//						// Select Format / Gate Width
//						Picker(selection: gateWidthBinding, label: EmptyView()) {
//                            Text("5x4").tag(GateWidth.largeFormat54)
//							Text("Medium Format").tag(GateWidth.mediumFormat)
//							Text("Crop Medium Format").tag(GateWidth.cropMedium)
//							Text("35mm Stil").tag(GateWidth.thirtyFive)
//							Text("Half Frame").tag(GateWidth.halfFrame)
//							Text("35mm Std").tag(GateWidth.motion35Standard)
//							Text("35mm Super").tag(GateWidth.motion35Super)
//							Text("16mm").tag(GateWidth.motion16)
//							Text("8mm").tag(GateWidth.motion8)
//							Text("Super 8").tag(GateWidth.motionSuper8)
//						}
//						.pickerStyle(MenuPickerStyle())
//						.labelsHidden()
//						.frame(width: 130)
//						
//						
//						Spacer()
//						
//						
//						// Apply Grain
//                        Toggle("", isOn: $applyGrain)
//                            .toggleStyle(SwitchToggleStyle())
//                            .labelsHidden()
//                            .padding(.trailing, 0)
//						
//					}
//					.padding(5)

                    
//                    SliderView(
//                        label: "Amount:",
//                        binding: $grainAmount,
//                        defaultValue: 50,
//                        range: 0...100,
//                        step: 1,
//                        formatter: wholeNumber
//                    )


				}
				.onAppear {
					focusedField = nil
				}
				.onChange(of: isCollapsed) { newValue in
					AppDataManager.shared.setCollapsed(newValue, for: "GrainView")
				}
				.onChange(of: apply) {
					applyGrain = apply
				}
				.onChange(of: applyGrain) {
					apply = applyGrain
				}
				.onAppear {
					apply = applyGrain
				}
			}
		)
	}
}
