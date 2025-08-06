//
//  HSDSliderView.swift
//  ColorForge
//
//  Created by Ben Quinton on 02/07/2025.
//

import Foundation
import SwiftUI

struct HSDSliderView: View {
    let label: String
    let binding: Binding<Float>
	let type: HSDSelection
    let defaultValue: Float?

    private let menuAccent = Color(red: 0.169, green: 0.169, blue: 0.169) // #2B2B2B
    private let sideBarText = Color(red: 0.882, green: 0.894, blue: 0.894) // #E1E4E4

    @FocusState private var isFocused: Bool
    @State private var dragValue: CGFloat?
    @State private var thumbPos: CGFloat = 0

    private let width: CGFloat = 100
    private let step: Float = 1
    private let range: ClosedRange<Float> = -100...100
    private let formatter = wholeNumber

    var body: some View {
        HStack {
            Circle()
                .fill(adjustedColor)
                .stroke(sideBarText, lineWidth: 1)
                .frame(width: 16, height: 16)

            Spacer()

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
                                let stepped = round(newValue / step) * step
                                binding.wrappedValue = min(max(stepped, range.lowerBound), range.upperBound)
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
                thumbPos = position(for: binding.wrappedValue, in: width)
            }
            .onChange(of: binding.wrappedValue) { newVal in
                if dragValue == nil {
                    thumbPos = position(for: newVal, in: width)
                }
            }

            TextField("", value: binding, formatter: formatter)
                .id(binding.wrappedValue)
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
    }

    private var adjustedColor: Color {
        let value = Double(binding.wrappedValue)
        let baseHSB: (h: Double, s: Double, b: Double) = {
            switch label.lowercased() {
            case "red": return (356/360.0, 0.5, 0.5)
            case "yellow": return (46/360.0, 0.5, 0.5)
            case "green": return (96/360.0, 0.5, 0.5)
            case "cyan": return (193/360.0, 0.5, 0.5)
            case "blue": return (208/360.0, 0.5, 0.5)
            case "magenta": return (294/360.0, 0.5, 0.5)
            default: return (0, 0, 0.5)
            }
        }()

        switch type {
        case .hue:
            let hueShift = (value / 3) / 360.0
            let newHue = (baseHSB.h + hueShift).truncatingRemainder(dividingBy: 1)
            return Color(hue: newHue < 0 ? newHue + 1 : newHue, saturation: baseHSB.s, brightness: baseHSB.b)
        case .sat:
            let scale = 1 + value / 200
            return Color(hue: baseHSB.h, saturation: min(max(baseHSB.s * scale, 0), 1), brightness: baseHSB.b)
        case .den:
            let scale = 1 + value / 200
            return Color(hue: baseHSB.h, saturation: baseHSB.s, brightness: min(max(baseHSB.b * scale, 0), 1))
        }
    }

    private func position(for value: Float, in width: CGFloat) -> CGFloat {
        let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
        return fraction * width
    }

    private func value(for x: CGFloat, in width: CGFloat) -> Float {
        let fraction = min(max(x / width, 0), 1)
        return range.lowerBound + Float(fraction) * (range.upperBound - range.lowerBound)
    }
}
