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
    @State private var hsdPopoverPresented = false


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
    
/*
 */

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 15)
            
            HStack {
                Image(systemName: "camera.on.rectangle")
                    .foregroundStyle(Color("SideBarText"))
                
                
                Text("HSD Color")
                    .font(.title3)
                    .foregroundStyle(Color("SideBarText"))

                Spacer()



                Spacer()

                Button(action: {
                    for (_, binding) in hsdRows {
                        binding.reset(to: 0)
                    }
                }) {
                    Image(systemName: "arrow.uturn.left")
                        .foregroundColor(Color("SideBarText"))  // Modify color for SideBarText
                        .font(.title3)
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
            
            Spacer()
                .frame(height: 15)

            
            
            if !isCollapsed {
                
                HStack {
                    
                    Button {
                        hsdPopoverPresented.toggle()
                    } label: {
                        
                        Text(hsdType.title)
                            .foregroundColor(Color("SideBarText"))
                        
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                    .popover(isPresented: $hsdPopoverPresented, arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 0) {
                            popoverOption(index: 0, type: .hue, title: "Hue")
                            popoverOption(index: 1, type: .sat, title: "Saturation")
                            popoverOption(index: 2, type: .den, title: "Density")
                        }
                        .background(Color("MenuAccent"))
                        .frame(width: 100)
                    }
                    
                    Spacer()
                        .frame(width: 10)
                    Image(systemName: hsdPopoverPresented ? "chevron.down" : "chevron.right")
                        .foregroundColor(Color("SideBarText").opacity(0.7))
                    Spacer()
                    
                    
                }

                Spacer()
                    .frame(height: 15)
                
                
                
                
                VStack {
                    ForEach(hsdRows, id: \.0) { (label, binding) in
                        
                        SliderView(
                            label: ("\(label):"),
                            binding: binding,
                            defaultValue: 0,
                            range: -100.0...100.0,
                            step: 1,
                            formatter: wholeNumber
                        )
                        
                    }
                }
            }
            
            Spacer()
                .frame(height: 15)
        }
        .onAppear { focusedField = nil }
        .onChange(of: isCollapsed) { newValue in
            AppDataManager.shared.setCollapsed(newValue, for: "HSDview")
        }
        .background(Color.clear)
        .padding(.horizontal, 20)
    }
    
    private func popoverOption(index: Int, type: HSDSelection, title: String) -> some View {
        Button {
            hsdType = type
            hsdPopoverPresented = false
        } label: {
            HStack {
                Text(title)
                    .foregroundColor(Color("SideBarText"))
                Spacer()
            }
            .padding(10)
            .background(index % 2 == 0 ? Color("MenuAccentDark") : Color("MenuAccentLight"))
        }
        .buttonStyle(.plain)
    }
}


private extension HSDSelection {
    var title: String {
        switch self {
        case .hue: return "Hue"
        case .sat: return "Saturation"
        case .den: return "Density"
        }
    }
}
