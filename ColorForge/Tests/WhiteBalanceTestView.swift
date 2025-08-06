//
//  WhiteBalanceView.swift
//  ColorForge
//
//  Created by admin on 24/06/2025.
//

import Foundation
import SwiftUI


struct WhiteBalanceTestView: View {

    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = false
    
    
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
        //		let _ = Self._printChanges()
        
        
        VStack(alignment: .leading, spacing: 10) {
            
            //					// MARK: - White balance drop down
            //					HStack {
            //						Text("Preset:")
            //							.foregroundStyle(Color("SideBarText"))
            //
            //						Spacer()
            //
            //						Picker("", selection: whiteBalancePresetBinding) {
            //							ForEach(WhiteBalancePreset.allCases, id: \.self) { preset in
            //								Text(preset.rawValue).tag(preset.rawValue)
            //							}
            //						}
            //						.pickerStyle(MenuPickerStyle())
            //						.frame(width: 125)
            //
            //						Spacer()
            //
            //
            //						// White balance picker
            //						ZStack {
            //							// Background Circle
            //							Circle()
            //								.frame(width: 28, height: 28) // Slightly increased for better visibility
            //								.foregroundColor(Color("MenuAccent"))
            //								.zIndex(1)
            //
            //							// Pick White Balance Button (Placed on Top)
            //							Button(action: {
            ////								maskingModel.clearWhiteBalanceRectangle()
            ////								maskingModel.pickingWhiteBalance.toggle()
            //							}) {
            //								Image(systemName: "eyedropper")
            //									.resizable()
            //									.scaledToFit()
            //									.frame(width: 16, height: 16) // Ensure it's smaller than the circle
            //									.foregroundColor(/*maskingModel.pickingWhiteBalance ? Color("IconActive") : */Color("SideBarText")) // Change color when active
            //							}
            //							.buttonStyle(PlainButtonStyle())
            ////							.disabled(imageProcessingModel.pickingTarget || imageProcessingModel.pickingSource)
            //							.zIndex(2) // Force it to be on top
            //
            //						}
            //						.frame(width: 30, height: 30) // Ensures enough space for both elements
            //
            //
            //
            //					}
            //					.padding(5)
            
//            // MARK: - Debug Toggle
//
//            Toggle("Use Debug Temp", isOn: Binding(
//                get: { temp == toggleTemp },
//                set: { useDebug in
//                    temp = useDebug ? toggleTemp : initTemp
//                }
//            ))
//            Toggle("Use Debug Tint", isOn: Binding(
//                get: { tint == toggleTint },
//                set: { useDebug in
//                    tint = useDebug ? toggleTint : initTint
//                }
//            ))
            // MARK: - White balance
            
            SliderView(
                label: "Tint:",
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
        //				.onAppear {
        //					focusedField = nil
        //				}
        
        
    }
}


