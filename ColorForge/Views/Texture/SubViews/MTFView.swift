//
//  MTFView.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import SwiftUI

struct MTFView: View {
	@EnvironmentObject var sidebarViewModel: SidebarViewModel
	@EnvironmentObject var viewModel: ImageViewModel
	
	
    @Binding var applyMTF: Bool
    @Binding var mtfBlend: Float
    @Binding var selectedGateWidth: Int // Supplied to both grain and mtf view

	
	@FocusState private var focusedField: String?

	@State private var isCollapsed: Bool = AppDataManager.shared.isCollapsed(for: "MTFView")
	
	@State private var apply: Bool = false
	
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
        case largeFormat54 = 9              // 127 mm
    }

	var body: some View {
		
		CollapsableSectionViewInfo(
			title: "MTF Curve:",
			isCollapsed: $isCollapsed,
//			isCollapsed: $sidebarViewModel.grainCollapsed,
			content: {
				VStack(alignment: .leading, spacing: 10) {

					// Format
					HStack {
						Text("Format:")
							.foregroundStyle(Color("SideBarText"))
						Spacer()
						
						// Select Format / Gate Width
						
						Picker(selection: gateWidthBinding, label: EmptyView()) {
                            Text("5x4").tag(GateWidth.largeFormat54)
							Text("Medium Format").tag(GateWidth.mediumFormat)
							Text("Crop Medium Format").tag(GateWidth.cropMedium)
							Text("35mm Stil").tag(GateWidth.thirtyFive)
							Text("Half Frame").tag(GateWidth.halfFrame)
							Text("35mm Std").tag(GateWidth.motion35Standard)
							Text("35mm Super").tag(GateWidth.motion35Super)
							Text("16mm").tag(GateWidth.motion16)
							Text("8mm").tag(GateWidth.motion8)
							Text("Super 8").tag(GateWidth.motionSuper8)
						}
						.pickerStyle(MenuPickerStyle())
						.labelsHidden()
						.frame(width: 130)
						
						Spacer()
						
						
						// Apply MTF
						Toggle("", isOn: $apply)
							.toggleStyle(SwitchToggleStyle())
							.labelsHidden()
							.padding(.trailing, 0)
							.onChange(of: apply) {
								applyMTF = apply
							}
							.onChange(of: viewModel.currentImgID) {
								apply = applyMTF
							}
						
						
					}
					.padding(5)
					
                    SliderView(
                        label: "Amount:",
                        binding: $mtfBlend,
                        defaultValue: 0,
                        range: 0...100,
                        step: 1,
                        formatter: wholeNumber
                    )

				


				}
//				.onAppear {
//					if let current = bindings.selectedGateWidth?.wrappedValue {
//						gateWidth = GateWidth(rawValue: current) ?? .mediumFormat
//					}
//				}
				.onAppear {
					focusedField = nil
				}
				.onChange(of: isCollapsed) { newValue in
					AppDataManager.shared.setCollapsed(newValue, for: "MTFView")
				}
			},
			resetAction: {
					selectedGateWidth = 0
					mtfBlend = 50
					applyMTF = false
				},
				infoTitle: "MTF Curve",
				infoText: """
			This filter emulates the Modulation Transfer Function (MTF) of film negatives — a curve that describes how well fine detail is preserved from scene to negative. Rather than artificially sharpening or blurring the image, the MTF curve models the natural sharpness falloff found in analog film, where fine textures lose detail more quickly than coarse ones.

			Applying the MTF curve restores the characteristic soft roll-off of real film negatives.

			The Format setting changes the curve shape to match the resolving power of different film formats:
			• Larger formats (like Medium Format or 35mm still) maintain contrast in finer detail,
			• Smaller formats (like 8mm or Super 8) fall off more rapidly, producing a softer, more organic look.
			""",
			infoBackgroundImage: "mtfGrad" // or nil if you don't want a background
		)
	}
}
