//
//  HSDview.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//


import SwiftUI

struct HSDview: View {
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
    
    @State private var isCollapsed: Bool = false
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

//import SwiftUI
//
//struct HSDview: View {
//    @Binding var redHue: Float
//    @Binding var redSat: Float
//    @Binding var redDen: Float
//
//    @Binding var greenHue: Float
//    @Binding var greenSat: Float
//    @Binding var greenDen: Float
//
//    @Binding var blueHue: Float
//    @Binding var blueSat: Float
//    @Binding var blueDen: Float
//
//    @Binding var cyanHue: Float
//    @Binding var cyanSat: Float
//    @Binding var cyanDen: Float
//
//    @Binding var magentaHue: Float
//    @Binding var magentaSat: Float
//    @Binding var magentaDen: Float
//
//    @Binding var yellowHue: Float
//    @Binding var yellowSat: Float
//    @Binding var yellowDen: Float
//    
//	@FocusState private var focusedField: String?
//	
//	@State private var isCollapsed: Bool = true
//	
//	@State private var hsdType: HSDSelection = .hue
//	
//	enum HSDSelection {
//		case hue
//		case sat
//		case den
//	}
//	
//
//	
//	var hsdRows: [(String, Binding<Float>?)] {
//		switch hsdType {
//		case .hue:
//			return [("Red", bindings.redHue),
//					("Green", bindings.greenHue),
//					("Blue", bindings.blueHue),
//					("Cyan", bindings.cyanHue),
//					("Magenta", bindings.magentaHue),
//					("Yellow", bindings.yellowHue)]
//		case .sat:
//			return [("Red", bindings.redSat),
//					("Green", bindings.greenSat),
//					("Blue", bindings.blueSat),
//					("Cyan", bindings.cyanSat),
//					("Magenta", bindings.magentaSat),
//					("Yellow", bindings.yellowSat)]
//		case .den:
//			return [("Red", bindings.redDen),
//					("Green", bindings.greenDen),
//					("Blue", bindings.blueDen),
//					("Cyan", bindings.cyanDen),
//					("Magenta", bindings.magentaDen),
//					("Yellow", bindings.yellowDen)]
//		}
//	}
//	
//	
//	var body: some View {
//		VStack(spacing: 0) {
//			HStack {
//				Text("HSD:")
//					.foregroundStyle(Color("SideBarText"))
//					.padding(.leading, 25)
//				
//				Spacer()
//				
//				Picker(selection: $hsdType, label: EmptyView()) {
//					Text("Hue").tag(HSDSelection.hue)
//					Text("Saturation").tag(HSDSelection.sat)
//					Text("Density").tag(HSDSelection.den)
//				}
//				.pickerStyle(MenuPickerStyle())
//				.labelsHidden()
//				.frame(width: 100)
//				
//				Spacer()
//				
//				Button(action: {
//					for (label, binding) in hsdRows {
//						let suffix: String
//						switch hsdType {
//						case .hue:    suffix = "Hue"
//						case .sat:    suffix = "Sat"
//						case .den:    suffix = "Density"
//						}
//						binding?.setUndoable(to: 0, using: dataModel, label: "Reset \(label) \(suffix)")
//					}
//				}) {
//					Image(systemName: "arrow.circlepath")
//						.foregroundColor(Color("SideBarText"))
//						.padding(.trailing, 5)
//				}
//				.buttonStyle(PlainButtonStyle())
//				
//				Button(action: {
//					isCollapsed.toggle()
//				}) {
//					Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
//						.foregroundColor(Color("SideBarText"))
//						.padding(.trailing, 0)
//				}
//				.buttonStyle(PlainButtonStyle())
//			}
//			.padding(.vertical, 10)
//			
//			if !isCollapsed {
//				VStack {
//					ForEach(hsdRows, id: \.0) { (label, binding) in
//						sliderRow(label: label, binding: binding)
//					}
//				}
//				.padding(.leading, 25)
//				.padding(.trailing, 25)
//				.padding(.bottom, 10)
//				
//				
//			}
//		}
//		.onAppear { focusedField = nil }
//		.onChange(of: isCollapsed) { newValue in
//			AppDataManager.shared.setCollapsed(newValue, for: "HSDview")
//		}
//		.background(Color.clear)
//	}
//	
//	private func sliderRow(label: String, binding: Binding<Float>?) -> some View {
//		let range: ClosedRange<Float>
//		let step: Float
//		let suffix: String
//
//		switch hsdType {
//		case .hue:    range = -100...100; step = 1; suffix = "Hue"
//		case .sat:    range = -100...100; step = 1; suffix = "Sat"
//		case .den:    range = -100...100; step = 1; suffix = "Density"
//		}
//		
//		// Base HSB values
//		let baseHSB: (h: Double, s: Double, b: Double) = {
//			switch label.lowercased() {
//			case "red":     return (356/360.0, 0.5, 0.5)
//			case "yellow":  return (46/360.0, 0.5, 0.5)
//			case "green":   return (96/360.0, 0.5, 0.5)
//			case "cyan":    return (193/360.0, 0.5, 0.5)
//			case "blue":    return (208/360.0, 0.5, 0.5)
//			case "magenta": return (294/360.0, 0.5, 0.5)
//			default:        return (0, 0, 0.5)
//			}
//		}()
//
//		
//		let currentValue = binding?.wrappedValue ?? 0
//		
//		// Adjusted HSB values
//		let adjustedColor: Color = {
//			switch hsdType {
//			case .hue:
//				// Hue shift: scale range from -100...100 to -180...180 degrees
//				let hueShift = (Double(currentValue) / 3) / 360.0
//				let newHue = (baseHSB.h + hueShift).truncatingRemainder(dividingBy: 1)
//				return Color(hue: newHue < 0 ? newHue + 1 : newHue, saturation: baseHSB.s, brightness: baseHSB.b)
//			case .sat:
//				// Scale saturation from 0 to 2.0
//				let scale = 1 + Double(currentValue) / 200
//				return Color(hue: baseHSB.h, saturation: min(max(baseHSB.s * scale, 0), 1), brightness: baseHSB.b)
//			case .den:
//				// Scale brightness from 0 to 2.0
//				let scale = 1 + Double(currentValue) / 200
//				return Color(hue: baseHSB.h, saturation: baseHSB.s, brightness: min(max(baseHSB.b * scale, 0), 1))
//			}
//		}()
//		
//		return HStack {
//			
//
//
//			Circle()
//				.fill(adjustedColor)
//				.stroke(Color("SideBarText"), lineWidth: 1)
//				.frame(width: 16, height: 16)
//
//			Spacer()
//			
//			Slider(value: binding?.undoable(using: dataModel) ?? .constant(0), in: range, step: step)
//				.tint(Color("MenuAccent"))
//				.controlSize(.mini)
//				.frame(width: 100)
//			
//			TextField("", value: binding?.undoable(using: dataModel) ?? .constant(0), formatter: wholeNumber)
//				.textFieldStyle(PlainTextFieldStyle())
//				.frame(width: 35)
//				.background(Color("MenuAccent"))
//				.foregroundColor(Color("SideBarText"))
//				.multilineTextAlignment(.center)
//				.font(.system(.caption, weight: .light))
//				.border(Color.black)
//				.padding(3)
//				.focused($focusedField, equals: label.lowercased() + suffix)
//				.onSubmit { focusedField = nil }
//			
//			Button(action: {
//				binding?.setUndoable(to: 0, using: dataModel, label: "Reset \(label) \(suffix)")
//			}) {
//				Image(systemName: "arrow.circlepath")
//					.resizable()
//					.scaledToFit()
//					.frame(width: 10, height: 10)
//					.foregroundColor(Color("SideBarText"))
//			}
//			.buttonStyle(PlainButtonStyle())
//			.frame(width: 12, height: 12)
//		}
//		.padding(5)
//	}
//	
//	
//}

