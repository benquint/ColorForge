//
//  SliderViewNoBinding.swift
//  ColorForge
//
//  Created by admin on 13/07/2025.
//

import Foundation
import SwiftUI

struct SliderViewNoBinding: View {
	let label: String
	@Binding var value: CGFloat
	let defaultValue: CGFloat?
	let range: ClosedRange<CGFloat>
	let step: CGFloat
	let formatter: NumberFormatter
	


	private let menuAccent = Color(red: 0.169, green: 0.169, blue: 0.169) // #2B2B2B
	private let sideBarText = Color(red: 0.882, green: 0.894, blue: 0.894) // #E1E4E4

	@FocusState private var isFocused: Bool
	@State private var dragValue: CGFloat?
	@State private var thumbPos: CGFloat = 0
	
	@State private var dragStartX: CGFloat?
	@State private var dragStartValue: CGFloat?

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
									dragStartValue = value
								}

								guard let startX = dragStartX,
									  let startValue = dragStartValue else { return }

								let deltaX = (gesture.location.x - startX) * shiftMultiplier
								let deltaFraction = deltaX / width
								let deltaValue = deltaFraction * (range.upperBound - range.lowerBound)

								let newValue = startValue + deltaValue
								let stepped = round(newValue / step) * step
								value = min(max(stepped, range.lowerBound), range.upperBound)

								thumbPos = position(for: value, in: width)
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
				thumbPos = position(for: value, in: width)
			}
			.onChange(of: value) { newVal in
				if dragValue == nil {
					thumbPos = position(for: newVal, in: width)
				}
			}

			TextField("", value: $value, formatter: formatter)
				.id(value)
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
					value = defaultValue
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
	}

	private func position(for value: CGFloat, in width: CGFloat) -> CGFloat {
		let fraction = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
		return fraction * width
	}
}
