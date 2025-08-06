//
//  WhiteBalanceView.swift
//  ColorForge
//
//  Created by admin on 24/06/2025.
//

import Foundation
import SwiftUI


struct WhiteBalanceView: View {
	@EnvironmentObject var viewModel: ImageViewModel
	@FocusState private var focusedField: String?
	@State private var isCollapsed: Bool = false

	@Binding var temp: Float
	@Binding var tint: Float
	@Binding var initTemp: Float
	@Binding var initTint: Float

	// Local state to keep Picker in sync immediately
	@State private var selectedPreset: WhiteBalancePreset = .asShot

	enum WhiteBalancePreset: String, CaseIterable {
		case asShot = "As Shot"
		case tungsten = "Tungsten"
		case daylight = "Daylight"
		case cloudy = "Cloudy"
		case shade = "Shade"
		case custom = "Custom"

		var temperature: Float? {
			switch self {
			case .asShot: return nil
			case .tungsten: return 3200.0
			case .daylight: return 5500.0
			case .cloudy: return 6500.0
			case .shade: return 7500.0
			case .custom: return nil
			}
		}
	}

	var body: some View {
		CollapsibleSectionView(
			title: "White balance:",
			isCollapsed: $isCollapsed,
			content: {
				VStack(alignment: .leading, spacing: 10) {
					HStack {
						Text("Preset:")
							.foregroundStyle(Color("SideBarText"))
						Spacer()

						Picker("", selection: $selectedPreset) {
							ForEach(WhiteBalancePreset.allCases, id: \.self) { preset in
								Text(preset.rawValue).tag(preset)
							}
						}
						.pickerStyle(MenuPickerStyle())
						.frame(width: 125)
						.onChange(of: selectedPreset) { newPreset in
							// Apply preset changes to temp/tint
							switch newPreset {
							case .asShot:
								temp = initTemp
								tint = initTint
							case .tungsten, .daylight, .cloudy, .shade:
								if let t = newPreset.temperature { temp = t }
							case .custom:
								break
							}
						}
						.onChange(of: viewModel.currentImgID) {
							// Sync Picker state to the new image
							updateSelectedPreset()
						}
						Spacer()

						ZStack {
							Circle()
								.frame(width: 28, height: 28)
								.foregroundColor(Color("MenuAccent"))
								.zIndex(1)
							Button(action: {
								// eyedropper action
							}) {
								Image(systemName: "eyedropper")
									.resizable()
									.scaledToFit()
									.frame(width: 16, height: 16)
									.foregroundColor(Color("SideBarText"))
							}
							.buttonStyle(PlainButtonStyle())
							.zIndex(2)
						}
						.frame(width: 30, height: 30)
					}
					.padding(5)

					SliderView(
						label: "Temp:",
						binding: $temp,
						defaultValue: 0.0,
						range: 2000.0...10000.0,
						step: 1,
						formatter: wholeNumber
					)

					SliderView(
						label: "Tint:",
						binding: $tint,
						defaultValue: 0.0,
						range: -150.0...150.0,
						step: 1,
						formatter: wholeNumber
					)
				}
				.onAppear {
					focusedField = nil
					// Keep Picker state in sync when view appears
					updateSelectedPreset()
				}
				.onChange(of: temp) { _ in updateSelectedPreset() }
				.onChange(of: tint) { _ in updateSelectedPreset() }
			},
			resetAction: {
				temp = initTemp
				tint = initTint
				selectedPreset = .asShot
			}
		)
	}

	private func updateSelectedPreset() {
		if temp == initTemp {
			selectedPreset = .asShot
		} else if let preset = WhiteBalancePreset.allCases.first(where: { $0.temperature == temp }) {
			selectedPreset = preset
		} else {
			selectedPreset = .custom
		}
	}
}

