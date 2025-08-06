//
//  SliderView.swift
//  ColorForge
//
//  Created by admin on 02/07/2025.
//

import SwiftUI

struct SliderView<T: BinaryFloatingPoint>: View where T.Stride: BinaryFloatingPoint {
    let label: String
    let binding: Binding<T>
    let defaultValue: T?
    let range: ClosedRange<T>
    let step: T
    let formatter: NumberFormatter
    


    private let menuAccent = Color(red: 0.169, green: 0.169, blue: 0.169) // #2B2B2B
    private let sideBarText = Color(red: 0.882, green: 0.894, blue: 0.894) // #E1E4E4

    @FocusState private var isFocused: Bool
    @State private var dragValue: CGFloat?
    @State private var thumbPos: CGFloat = 0
    
    @State private var dragStartX: CGFloat?
    @State private var dragStartValue: T?

    @State private var resetToggle: Bool = false
    @State private var width: CGFloat = 100

    var body: some View {
        HStack {
            Text(label)
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
                                 let shiftMultiplier: CGFloat = NSEvent.modifierFlags.contains(.shift) ? 0.1 : 1.0

                                 if dragStartX == nil {
                                     dragStartX = gesture.startLocation.x
                                     dragStartValue = binding.wrappedValue
                                 }

                                 guard let startX = dragStartX,
                                       let startValue = dragStartValue else { return }

                                 let deltaX = (gesture.location.x - startX) * shiftMultiplier
                                 let deltaFraction = deltaX / width
                                 let deltaValue = T(deltaFraction) * (range.upperBound - range.lowerBound)

                                 let newValue = startValue + deltaValue
                                 let stepped = round(newValue / step) * step
                                 binding.wrappedValue = min(max(stepped, range.lowerBound), range.upperBound)

                                 thumbPos = position(for: binding.wrappedValue, in: width)
                             }
                             .onEnded { _ in
                                 dragStartX = nil
                                 dragStartValue = nil
                                 dragValue = nil
                             }
                     )
             }
             .frame(width: width, height: 12)
             .onAppear {
                 thumbPos = position(for: binding.wrappedValue, in: width)
             }
             .onChange(of: binding.wrappedValue) { newVal in
                 if dragValue == nil {
                     thumbPos = position(for: newVal, in: width)
                 }
             }
            

            TextField("", value: binding, formatter: formatter)
                .id(binding.wrappedValue) // Forces redraw when value changes
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


            if let defaultValue {
                Button(action: {
                    binding.reset(to: defaultValue)
                    print("Default Value = \(defaultValue)")
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
        }
        .padding(5)
//        .onChange(of: binding.wrappedValue) { newVal in
//            dragValue = position(for: newVal, in: width)
//        }
    }

    private func position(for value: T, in width: CGFloat) -> CGFloat {
        let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return fraction * width
    }

    private func value(for x: CGFloat, in width: CGFloat) -> T {
        let fraction = min(max(x / width, 0), 1)
        return range.lowerBound + T(fraction) * (range.upperBound - range.lowerBound)
    }
}
