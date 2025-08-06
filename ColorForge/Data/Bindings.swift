//
//  Bindings.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import Foundation
import SwiftUI

// Undo extension
extension Binding where Value: Equatable {

	/*
	 Usage:
	 
	 bindings.variable?.undoable(using: dataModel)
	 
	 This makes the binding support undo via the shared undoManager stored in the DataModel.
	 The previous value is restored when the user triggers undo (⌘Z).
	 */

	func undoable(using dataModel: DataModel, label: String = "Change") -> Binding<Value> {
		Binding(
			get: { self.wrappedValue },
			set: { newValue in
				let oldValue = self.wrappedValue
				guard newValue != oldValue else { return }
				
				self.wrappedValue = newValue
				
				dataModel.undoManager?.registerUndo(withTarget: dataModel) { _ in
					self.wrappedValue = oldValue
				}
				dataModel.undoManager?.setActionName(label)
			}
		)
	}

	/*
	 Usage:
	 
	 bindings.variable?.setUndoable(to: 0, using: dataModel, label: "Reset Value")
	 
	 This sets a value with undo support. Use it for discrete resets or toggles,
	 not continuous bindings (like sliders).
	 */

	func setUndoable(to newValue: Value, using dataModel: DataModel, label: String = "Change") {
		let oldValue = self.wrappedValue
		guard newValue != oldValue else { return }

		self.wrappedValue = newValue

		dataModel.undoManager?.registerUndo(withTarget: dataModel) { _ in
			self.wrappedValue = oldValue
		}
		dataModel.undoManager?.setActionName(label)
	}
}

struct UndoableBinding<Value: Equatable> {
	let binding: Binding<Value>
	let setUndoable: (_ newValue: Value, _ label: String) -> Void
}




final class Bindings {
	let dataModel: DataModel
	let pipeline: FilterPipeline
//	let url: URL?

	init(dataModel: DataModel, pipeline: FilterPipeline) {
		self.dataModel = dataModel
		self.pipeline = pipeline
	}

	// Helper to resolve URL once
	private var url: URL? {
		pipeline.currentURL ?? dataModel.items.first?.url
	}
	
	// MARK: - Image data
	


	// MARK: - Temp / Tint

//	func temp(default defaultValue: Float = 5500.0) -> UndoableBinding<Float> {
//		guard let url = url,
//			  let binding = dataModel.binding(for: url, settingsPath: \.rawAdjustSettings.temp)
//		else {
//			return .constant(defaultValue)
//		}
//		return binding
//	}
//
//	func initTemp(default defaultValue: Float = 5500.0) -> UndoableBinding<Float> {
//		guard let url = url,
//			  let binding = dataModel.binding(for: url, settingsPath: \.rawAdjustSettings.initTemp)
//		else {
//			return .constant(defaultValue)
//		}
//		return binding
//	}
//
//	func tint(default defaultValue: Float = 0.0) -> UndoableBinding<Float> {
//		guard let url = url,
//			  let binding = dataModel.binding(for: url, settingsPath: \.rawAdjustSettings.tint)
//		else {
//			return .constant(defaultValue)
//		}
//		return binding
//	}
//
//	func initTint(default defaultValue: Float = 0.0) -> UndoableBinding<Float> {
//		guard let url = url,
//			  let binding = dataModel.binding(for: url, settingsPath: \.rawAdjustSettings.initTint)
//		else {
//			return .constant(defaultValue)
//		}
//		return binding
//	}
	
	// MARK: - Raw Exposure



//
//	// MARK: - HDR
//
//	var hdrWhite: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.hdrWhite) }
//	}
//	var hdrHighlight: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.hdrHighlight) }
//	}
//	var hdrShadow: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.hdrShadow) }
//	}
//	var hdrBlack: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.hdrBlack) }
//	}
//
//	// MARK: - HSD
//
//	var redHue: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.redHue) }
//	}
//	var redSat: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.redSat) }
//	}
//	var redDen: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.redDen) }
//	}
//
//	var greenHue: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.greenHue) }
//	}
//	var greenSat: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.greenSat) }
//	}
//	var greenDen: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.greenDen) }
//	}
//
//	var blueHue: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.blueHue) }
//	}
//	var blueSat: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.blueSat) }
//	}
//	var blueDen: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.blueDen) }
//	}
//
//	var cyanHue: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.cyanHue) }
//	}
//	var cyanSat: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.cyanSat) }
//	}
//	var cyanDen: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.cyanDen) }
//	}
//
//	var magentaHue: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.magentaHue) }
//	}
//	var magentaSat: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.magentaSat) }
//	}
//	var magentaDen: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.magentaDen) }
//	}
//
//	var yellowHue: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.yellowHue) }
//	}
//	var yellowSat: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.yellowSat) }
//	}
//	var yellowDen: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \.rawAdjustSettings.yellowDen) }
//	}
//	
//	
//	
//	// MARK: - Texture
//
//	var applyMTF: Binding<Bool>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.textureSettings.applyMTF) }
//	}
//	var mtfBlend: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.textureSettings.mtfBlend) }
//	}
//	var applyGrain: Binding<Bool>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.textureSettings.applyGrain) }
//	}
//	var grainAmount: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.textureSettings.grainAmount) }
//	}
//	var selectedGateWidth: Binding<Int>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.textureSettings.selectedGateWidth) }
//	}
//	
//	
//	// Print Halation
//	var radiusMultiplier: Binding<CGFloat>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.textureSettings.radiusMultiplier) }
//	}
//	var radiusExponent: Binding<CGFloat>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.textureSettings.radiusExponent) }
//	}
//	var opacityMultiplier: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.textureSettings.opacityMultiplier) }
//	}
//	var applyPrintHalation: Binding<Bool>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.textureSettings.applyPrintHalation) }
//	}
//	
//	
//	// MARK: - Film Stock
//	
//	var convertToNeg: Binding<Bool>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.negConvertSettings.convertToNeg) }
//	}
//	
//	var stockChoice: Binding<Int>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.negConvertSettings.stockChoice) }
//	}
//	
//	
//	// MARK: - Enlarger
//
//	var applyPrintMode: Binding<Bool>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.enlargerSettings.applyPrintMode) }
//	}
//
//	var enlargerExp: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.enlargerSettings.enlargerExp) }
//	}
//
//	var enlargerFStop: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.enlargerSettings.enlargerFStop) }
//	}
//
//	var cyan: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.enlargerSettings.cyan) }
//	}
//
//	var magenta: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.enlargerSettings.magenta) }
//	}
//
//	var yellow: Binding<Float>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.enlargerSettings.yellow) }
//	}
//
//	var applyFlash: Binding<Bool>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.enlargerSettings.applyFlash) }
//	}
//	
//	var bwMode: Binding<Bool>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.enlargerSettings.bwMode) }
//	}
//	
//	var useLegacy: Binding<Bool>? {
//		url.flatMap { dataModel.binding(for: $0, settingsPath: \ImageItem.enlargerSettings.useLegacy) }
//	}
	
}
