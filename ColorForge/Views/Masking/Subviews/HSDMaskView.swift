//
//  HSDMaskView.swift
//  ColorForge
//
//  Created by admin on 05/07/2025.
//


import SwiftUI

struct HSDMaskView: View {
	@Binding var redHue: Float
	@Binding var redSat: Float
	@Binding var redDen: Float

	@Binding var greenHue: Float
	@Binding var greenSat: Float
	@Binding var greenDen: Float

	@Binding var blueHue: Float
	@Binding var blueSat: Float
	@Binding var blueDen: Float

	@Binding var cyanHue: Float
	@Binding var cyanSat: Float
	@Binding var cyanDen: Float

	@Binding var magentaHue: Float
	@Binding var magentaSat: Float
	@Binding var magentaDen: Float

	@Binding var yellowHue: Float
	@Binding var yellowSat: Float
	@Binding var yellowDen: Float

	@FocusState private var focusedField: String?
	
	@State private var isCollapsed: Bool = true
	@State private var hsdType: HSDSelection = .hue


	var hsdRows: [(String, Binding<Float>)] {
		switch hsdType {
		case .hue:
			return [("Red", $redHue),
					("Green", $greenHue),
					("Blue", $blueHue),
					("Cyan", $cyanHue),
					("Magenta", $magentaHue),
					("Yellow", $yellowHue)]
		case .sat:
			return [("Red", $redSat),
					("Green", $greenSat),
					("Blue", $blueSat),
					("Cyan", $cyanSat),
					("Magenta", $magentaSat),
					("Yellow", $yellowSat)]
		case .den:
			return [("Red", $redDen),
					("Green", $greenDen),
					("Blue", $blueDen),
					("Cyan", $cyanDen),
					("Magenta", $magentaDen),
					("Yellow", $yellowDen)]
		}
	}

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Text("HSD:")
					.foregroundStyle(Color("SideBarText"))
					.padding(.leading, 25)

				Spacer()

				Picker(selection: $hsdType, label: EmptyView()) {
					Text("Hue").tag(HSDSelection.hue)
					Text("Saturation").tag(HSDSelection.sat)
					Text("Density").tag(HSDSelection.den)
				}
				.pickerStyle(MenuPickerStyle())
				.labelsHidden()
				.frame(width: 100)

				Spacer()

				Button(action: {
					for (_, binding) in hsdRows {
						binding.reset(to: 0)
					}
				}) {
					Image(systemName: "arrow.circlepath")
						.foregroundColor(Color("SideBarText"))
						.padding(.trailing, 5)
				}
				.buttonStyle(PlainButtonStyle())

				Button(action: {
					isCollapsed.toggle()
				}) {
					Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
						.foregroundColor(Color("SideBarText"))
						.padding(.trailing, 0)
				}
				.buttonStyle(PlainButtonStyle())
			}
			.padding(.vertical, 10)

			if !isCollapsed {
				VStack {
					ForEach(hsdRows, id: \.0) { (label, binding) in
						
						HSDSliderView(label: label, binding: binding, type: hsdType, defaultValue: 0)
						
					}
				}
				.padding(.horizontal, 25)
				.padding(.bottom, 10)
			}
		}
		.onAppear { focusedField = nil }
		.onChange(of: isCollapsed) { newValue in
			AppDataManager.shared.setCollapsed(newValue, for: "HSDview")
		}
		.background(Color.clear)
	}
}
