//
//  RawAdjustTestView.swift
//  ColorForge
//
//  Created by admin on 01/07/2025.
//


import Foundation
import SwiftUI



struct RawAdjustTestView: View {
	// Your existing properties and body here


	@FocusState private var focusedField: String?
	@State private var isCollapsed: Bool = false
	
	@Binding var exposure: Float
	@Binding var contrast: Float
	@Binding var saturation: Float
	


	var body: some View {
//		let _ = Self._printChanges()
//		let exposure = dataModel.bindingToItem(keyPath: \.exposure, defaultValue: 0)
//		let contrast = dataModel.bindingToItem(keyPath: \.contrast, defaultValue: 0)
//		let saturation = dataModel.bindingToItem(keyPath: \.saturation, defaultValue: 0)
		
	
				VStack(alignment: .leading, spacing: 10) {

					// Exposure Slider
					HStack {
						Text("Exposure:")
							.foregroundStyle(Color("SideBarText"))
						Spacer()
						Slider(value: $exposure, in: -4.0...4.0, step: 0.1)
							.tint(Color("MenuAccent"))
							.controlSize(.mini)
							.frame(width: 100)

						TextField("", value: $exposure, formatter: twoDecimal)
							.textFieldStyle(PlainTextFieldStyle())
							.frame(width: 35)
							.background(Color("MenuAccent"))
							.foregroundColor(Color("SideBarText"))
							.multilineTextAlignment(.center)
							.font(.system(.caption, weight: .light))
							.border(Color.black)
							.padding(3)
							.focused($focusedField, equals: "exposure")
							.onSubmit { focusedField = nil }

						Button(action: {
//							dataModel.exposure().setUndoable(0, "Reset Exposure")
						}) {
							Image(systemName: "arrow.circlepath")
								.resizable()
								.scaledToFit()
								.frame(width: 10, height: 10)
								.foregroundColor(Color("SideBarText"))
						}
						.buttonStyle(PlainButtonStyle())
						.frame(width: 12, height: 12)
					}
					.padding(5)

					HStack {
						Text("Contrast:")
							.foregroundStyle(Color("SideBarText"))
						Spacer()
						Slider(value: $contrast, in: -100.0...100.0, step: 1)
							.tint(Color("MenuAccent"))
							.controlSize(.mini)
							.frame(width: 100)

						TextField("", value: $contrast, formatter: wholeNumber)
							.textFieldStyle(PlainTextFieldStyle())
							.frame(width: 35)
							.background(Color("MenuAccent"))
							.foregroundColor(Color("SideBarText"))
							.multilineTextAlignment(.center)
							.font(.system(.caption, weight: .light))
							.border(Color.black)
							.padding(3)
							.focused($focusedField, equals: "contrast")
							.onSubmit { focusedField = nil }

						Button(action: {
//							dataModel.contrast().setUndoable(to: 0, using: dataModel, label: "Reset Contrast")
						}) {
							Image(systemName: "arrow.circlepath")
								.resizable()
								.scaledToFit()
								.frame(width: 10, height: 10)
								.foregroundColor(Color("SideBarText"))
						}
						.buttonStyle(PlainButtonStyle())
						.frame(width: 12, height: 12)
					}
					.padding(5)

					HStack {
						Text("Saturation:")
							.foregroundStyle(Color("SideBarText"))
						Spacer()
						Slider(value: $saturation, in: -100.0...100.0, step: 1)
							.tint(Color("MenuAccent"))
							.controlSize(.mini)
							.frame(width: 100)

						TextField("", value: $saturation, formatter: wholeNumber)
							.textFieldStyle(PlainTextFieldStyle())
							.frame(width: 35)
							.background(Color("MenuAccent"))
							.foregroundColor(Color("SideBarText"))
							.multilineTextAlignment(.center)
							.font(.system(.caption, weight: .light))
							.border(Color.black)
							.padding(3)
							.focused($focusedField, equals: "saturation")
							.onSubmit { focusedField = nil }

						Button(action: {
//							dataModel.saturation().setUndoable(to: 0, using: dataModel, label: "Reset Saturation")
						}) {
							Image(systemName: "arrow.circlepath")
								.resizable()
								.scaledToFit()
								.frame(width: 10, height: 10)
								.foregroundColor(Color("SideBarText"))
						}
						.buttonStyle(PlainButtonStyle())
						.frame(width: 12, height: 12)
					}
					.padding(5)

				}
//				.onAppear {
//					focusedField = nil
//				}

	}
}

