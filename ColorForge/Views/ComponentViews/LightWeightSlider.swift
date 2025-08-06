//
//  LightWeightSlider.swift
//  ColorForge
//
//  Created by Ben Quinton on 02/07/2025.
//

import Foundation
import SwiftUI

struct LightweightSlider<T: BinaryFloatingPoint>: View where T.Stride: BinaryFloatingPoint {
    @Binding var value: T
    let range: ClosedRange<T>
    let trackHeight: CGFloat = 4
    let thumbSize: CGFloat = 12

    @State private var dragOffset: CGFloat = 0
    @State private var startX: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let totalWidth = geo.size.width
            let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let currentWidth = fraction * totalWidth

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: trackHeight)

                // Fill
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.blue)
                    .frame(width: currentWidth, height: trackHeight)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .offset(x: max(0, currentWidth - thumbSize / 2))
//                    .gesture(
//                        DragGesture(minimumDistance: 0)
//                            .onChanged { gesture in
//                                let newX = startX + gesture.translation.width
//                                let clampedX = min(max(0, newX), totalWidth)
//                                let newFraction = clampedX / totalWidth
//                                let newValue = range.lowerBound + T(newFraction) * (range.upperBound - range.lowerBound)
//                                value = newValue
//                            }
//                            .onEnded { _ in
//                                startX = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * totalWidth
//                            }
//                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { gesture in
                                let isShiftDown = NSEvent.modifierFlags.contains(.shift)
                                let sensitivityMultiplier: CGFloat = isShiftDown ? 0.25 : 1.0

                                let adjustedTranslation = gesture.translation.width * sensitivityMultiplier
                                let newX = startX + adjustedTranslation
                                let clampedX = min(max(0, newX), totalWidth)
                                let newFraction = clampedX / totalWidth
                                let newValue = range.lowerBound + T(newFraction) * (range.upperBound - range.lowerBound)
                                value = newValue
                            }
                            .onEnded { _ in
                                startX = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * totalWidth
                            }
                    )
            }
            .onAppear {
                startX = fraction * totalWidth
            }
        }
        .frame(height: thumbSize)
    }
}

//    private func position(for value: T, in width: CGFloat) -> CGFloat {
//        let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
//        return fraction * width
//    }
//
//    private func value(for x: CGFloat, in width: CGFloat) -> T {
//        let fraction = min(max(x / width, 0), 1)
//        return range.lowerBound + T(fraction) * (range.upperBound - range.lowerBound)
//    }
//}
