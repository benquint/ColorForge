//
//  WhiteBalanceMaskView.swift
//  ColorForge
//
//  Created by admin on 05/07/2025.
//


import Foundation
import SwiftUI


struct WhiteBalanceMaskView: View {
	@EnvironmentObject var viewModel: ImageViewModel
	@FocusState private var focusedField: String?
	@State private var isCollapsed: Bool = true
    @State private var wbPopoverPresented = false
	
	@Binding var temp: Float
	@Binding var tint: Float
	@Binding var initTemp: Float
	@Binding var initTint: Float
	
	
	enum WhiteBalancePreset: String, CaseIterable {
		case asShot = "As Shot"
		case tungsten = "Tungsten"
		case daylight = "Daylight"
		case cloudy = "Cloudy"
		case shade = "Shade"
		case custom = "Custom" // Will be set when temperature does not match presets
		
		var temperature: Float? {
			switch self {
			case .asShot: return nil // Assigned dynamically from `initRawTemp`
			case .tungsten: return 3200.0
			case .daylight: return 5500.0
			case .cloudy: return 6500.0
			case .shade: return 7500.0
			case .custom: return nil // No specific value
			}
		}
	}
	
	
	
	private var whiteBalancePresetBinding: Binding<String> {
		Binding<String>(
			get: {
				if temp == initTemp {
					return WhiteBalancePreset.asShot.rawValue
				}
				
				return WhiteBalancePreset.allCases.first(where: {
					$0.temperature == temp
				})?.rawValue ?? WhiteBalancePreset.custom.rawValue
			},
			set: { newValue in
				guard let preset = WhiteBalancePreset(rawValue: newValue) else { return }
				
				switch preset {
				case .asShot:
					temp = initTemp
					tint = initTint
					
				case .tungsten, .daylight, .cloudy, .shade:
					if let t = preset.temperature {
						temp = t
					}
					
				case .custom:
					break
				}
			}
		)
	}
	
	var body: some View {
		
		SubSection(
			title: "White balance:",
            icon: "camera.on.rectangle",
			isCollapsed: $isCollapsed,
            resetAction: {
                
            },
			content: {
				VStack() {
					
					
					// MARK: - White balance drop down
                    HStack {
                        Text("Preset:")
                            .foregroundStyle(Color("SideBarText"))

                        Spacer()

                        Button {
                            wbPopoverPresented.toggle()
                        } label: {
                            HStack {
                                Text(whiteBalancePresetBinding.wrappedValue)
                                    .foregroundColor(Color("SideBarText"))
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color("SideBarText").opacity(0.7))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .frame(width: 120)
                            .background(Color("MenuAccent"))
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $wbPopoverPresented, arrowEdge: .bottom) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(WhiteBalancePreset.allCases.indices, id: \.self) { i in
                                    let p = WhiteBalancePreset.allCases[i]
                                    wbPopoverOption(index: i, preset: p)
                                }
                            }
                            .background(Color("MenuAccent"))
                            .frame(width: 150)
                        }

                        Spacer()
						
						// White balance picker - DO NOT CHANGE THIS
						ZStack {
							// Background Circle
							Circle()
								.frame(width: 28, height: 28) // Slightly increased for better visibility
								.foregroundColor(Color("MenuAccent"))
								.zIndex(1)
							
							// Pick White Balance Button (Placed on Top)
							Button(action: {
								//                                maskingModel.clearWhiteBalanceRectangle()
								//                                maskingModel.pickingWhiteBalance.toggle()
							}) {
								Image(systemName: "eyedropper")
									.resizable()
									.scaledToFit()
									.frame(width: 16, height: 16) // Ensure it's smaller than the circle
									.foregroundColor(/*maskingModel.pickingWhiteBalance ? Color("IconActive") : */Color("SideBarText")) // Change color when active
							}
							.buttonStyle(PlainButtonStyle())
							//                            .disabled(imageProcessingModel.pickingTarget || imageProcessingModel.pickingSource)
							.zIndex(2) // Force it to be on top
							
						}
						.frame(width: 30, height: 30) // Ensures enough space for both elements
						
						
						
					}
					.padding(5)
					
					
					// MARK: - White balance
					
					SliderView(
						label: "Temperature:",
						binding: $temp,
						defaultValue: initTemp,
						range: 2000.0...10000.0,
						step: 1,
						formatter: wholeNumber
					)
					
					
					
					SliderView(
						label: "Tint:",
						binding: $tint,
						defaultValue: initTint,
						range: -150.0...150.0,
						step: 1,
						formatter: wholeNumber
					)
					
					
					
				}
				.onAppear {
					focusedField = nil
				}

			}

		)
	}
    
    @ViewBuilder
    private func wbPopoverOption(index: Int, preset: WhiteBalancePreset) -> some View {
        Button {
            whiteBalancePresetBinding.wrappedValue = preset.rawValue
            wbPopoverPresented = false
        } label: {
            HStack {
                Text(preset.rawValue)
                    .foregroundColor(Color("SideBarText"))
                Spacer()
                Image(systemName: iconName(for: preset))
                    .foregroundStyle(Color("SideBarText"))
            }
            .padding(10)
            .background(index % 2 == 0 ? Color("MenuAccentDark") : Color("MenuAccentLight"))
        }
        .buttonStyle(.plain)
    }

    private func iconName(for preset: WhiteBalancePreset) -> String {
        switch preset {
        case .tungsten: return "lightbulb"
        case .daylight: return "sun.max"
        case .cloudy:   return "cloud"
        case .shade:    return "tree.fill"
        case .custom:   return "person"
        case .asShot:   return "camera"
        }
    }
}

