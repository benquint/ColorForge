//
//  FeatherSlider.swift
//  ColorForge
//
//  Created by Ben Quinton on 09/07/2025.
//


import SwiftUI

struct FeatherSlider: View {
    @EnvironmentObject var samModel: SamModel
    @EnvironmentObject var viewModel: ImageViewModel

    @Binding var feather: Float
    


    private let menuAccent = Color(red: 0.169, green: 0.169, blue: 0.169) // #2B2B2B
    private let sideBarText = Color(red: 0.882, green: 0.894, blue: 0.894) // #E1E4E4

    @FocusState private var isFocused: Bool
    @State private var dragValue: CGFloat?
    @State private var thumbPos: CGFloat = 0
    


    @State private var resetToggle: Bool = false
    @State private var width: CGFloat = 100

    var body: some View {
        HStack {
            Text("Feather:")
                .foregroundStyle(sideBarText)

            Spacer()
            
            let width: CGFloat = 100

             ZStack(alignment: .leading) {
                 RoundedRectangle(cornerRadius: 2)
                     .fill(Color.gray.opacity(0.3))
                     .frame(width: width, height: 4)

                 RoundedRectangle(cornerRadius: 2)
                     .fill(menuAccent)
                     .frame(width: thumbPos, height: 4)

                 RoundedRectangle(cornerRadius: 3)
                     .fill(sideBarText)
                     .frame(width: 9, height: 15)
                     .offset(x: max(0, thumbPos - 6))
                     .gesture(
                         DragGesture(minimumDistance: 0)
                             .onChanged { gesture in
                                 let clampedX = min(max(0, gesture.location.x), width)
                                 let newValue = value(for: clampedX, in: width)
                                 let stepped = round(newValue / 1) * 1
                                 $feather.wrappedValue = min(max(stepped, 0), 100)
                                 dragValue = clampedX
                                 thumbPos = clampedX
                             }
                             .onEnded { _ in
                                 dragValue = nil
                             }
                     )
             }
             .frame(width: width, height: 12)
             .onAppear {
                 thumbPos = position(for: $feather.wrappedValue, in: width)
             }
             .onChange(of: $feather.wrappedValue) { newVal in
                 if dragValue == nil {
                     thumbPos = position(for: newVal, in: width)
                 }
                 viewModel.radialUiFeather = CGFloat(newVal)
             }
            

            TextField("", value: $feather, formatter: wholeNumber)
                .id($feather.wrappedValue) // Forces redraw when value changes
                .textFieldStyle(PlainTextFieldStyle())
                .frame(width: 35)
                .background(menuAccent)
                .foregroundColor(sideBarText)
                .multilineTextAlignment(.center)
                .font(.system(.caption, weight: .light))
                .border(Color.black)
                .padding(3)
                .focused($isFocused)
                .onSubmit { isFocused = false }

                Button(action: {
                    feather = 0.0
                }) {
                    Image(systemName: "arrow.circlepath")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 10, height: 10)
                        .foregroundColor(sideBarText)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 12, height: 12)
            
        }
        .padding(5)
//        .onChange(of: feather) {
//            viewModel.radialUiFeather = CGFloat(feather)
//        }

    }

    private func position(for value: Float, in width: CGFloat) -> CGFloat {
        let fraction = CGFloat((value - 0) / (100 - 0))
        return fraction * width
    }

    private func value(for x: CGFloat, in width: CGFloat) -> Float {
        let fraction = min(max(x / CGFloat(width), 0), 1)
        return Float(fraction * 100)
    }
}
