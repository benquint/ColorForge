////
////  ImageItemOld.swift
////  ColorForge
////
////  Created by admin on 02/07/2025.
////
//
//import Foundation
//import CoreImage
//import CoreGraphics
//import SwiftUI
//
//// MARK: - Main Image struct
////struct ImageItem: Identifiable, Equatable {
//struct ImageItem: Identifiable, Equatable {
//	let id: UUID
//	let url: URL
//	
//	
//	
//	init(
//		id: UUID = UUID(),
//		url: URL
//	) {
//		self.id = id
//		self.url = url
//	}
//	
//	static func ==(lhs: ImageItem, rhs: ImageItem) -> Bool {
//		return lhs.id == rhs.id
//	}
//}
//
//
//
//// Images
//struct ImageObject {
//	
//
//	
//	var debayeredInit: CIImage? = nil {
//		didSet{
//			print("Debayered init set")
//		}
//	}
//	var processImage: CIImage? = nil
//	var thumbnailImage: NSImage? = nil
//	var fullResCiImage: CIImage? = nil
//	
//}
//
//extension NSImage {
//	static let clearThumbnail: NSImage = {
//		let size = CGSize(width: 30, height: 30)
//		let image = NSImage(size: size)
//		image.lockFocus()
//		NSColor.clear.set()
//		NSBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
//		image.unlockFocus()
//		return image
//	}()
//}
//
//
//// MARK: - Settings Structs
//
//struct ImageObjectData: Codable {
//	var thumbLoaded: Bool = false
//	
//	// Dates
//	let importDate: Date
//	let captureDate: Date
//	
//	var nativeWidth: Int = 0
//	var nativeHeight: Int = 0
//	var nativeRotation: Int = 1
//	
//	
//}
//
//
//// MARK: - Masking
//
//struct MaskSettings: Codable, Equatable {
//	var linearGradients: [LinearGradientMask] = []
//	// Future: var radialMasks: [RadialMask] = []
//	// Future: var brushStrokes: [BrushStroke] = []
//}
//
//
//struct LinearGradientMask: Identifiable, Codable, Equatable, Hashable {
//	let id: UUID
//	var startPoint: CGPoint
//	var endPoint: CGPoint
//	var invert: Bool
//	var strength: Float
//	
//	init(
//		id: UUID = UUID(),
//		startPoint: CGPoint,
//		endPoint: CGPoint,
//		invert: Bool = false,
//		strength: Float = 1.0
//	) {
//		self.id = id
//		self.startPoint = startPoint
//		self.endPoint = endPoint
//		self.invert = invert
//		self.strength = strength
//	}
//}
//
//
//
//
//// MARK: - Raw Adjust
//
//struct WhiteBalanceSettings: Codable, Equatable {
//	// Temperature
//	var xyChromaticity: CGPoint = CGPoint(x: 0.3, y: 0.3)
//	var temp: Float = 5500.0
//	var tint: Float = 0.0
//	var initTemp: Float = 5500.0
//	var initTint: Float = 0.0
//}
//
//struct RawAdjustSettings: Codable, Equatable {
//	var baselineExposure: Float = 0.0
//	var exposure: Float = 0.0
//	var contrast: Float = 0.0
//	var saturation: Float = 0.0
//}
//
//struct HDRSettings: Codable {
//	var hdrWhite: Float = 0.0
//	var hdrHighlight: Float = 0.0
//	var hdrShadow: Float = 0.0
//	var hdrBlack: Float = 0.0
//}
//
//
//struct HSDSettings: Codable {
//	// Preview HSD
//	var previewRed: Bool = false
//	var previewGreen: Bool = false
//	var previewBlue: Bool = false
//	var previewCyan: Bool = false
//	var previewMagenta: Bool = false
//	var previewYellow: Bool = false
//	
//	var redHue: Float = 0.0
//	var redSat: Float = 0.0
//	var redDen: Float = 0.0
//	
//	var greenHue: Float = 0.0
//	var greenSat: Float = 0.0
//	var greenDen: Float = 0.0
//	
//	var blueHue: Float = 0.0
//	var blueSat: Float = 0.0
//	var blueDen: Float = 0.0
//	
//	var cyanHue: Float = 0.0
//	var cyanSat: Float = 0.0
//	var cyanDen: Float = 0.0
//	
//	var magentaHue: Float = 0.0
//	var magentaSat: Float = 0.0
//	var magentaDen: Float = 0.0
//	
//	var yellowHue: Float = 0.0
//	var yellowSat: Float = 0.0
//	var yellowDen: Float = 0.0
//}
//
//
////struct RawAdjustSettings: Codable {
////
////	// Temperature
////	var xyChromaticity: CGPoint = CGPoint(x: 0.3, y: 0.3)
////	var temp: Float = 5500.0
////	var tint: Float = 0.0
////	var initTemp: Float = 5500.0
////	var initTint: Float = 0.0
////
////	// Basic
////	var baselineExposure: Float = 0.0
////	var exposure: Float = 0.0
////	var contrast: Float = 0.0
////	var saturation: Float = 0.0
////
////
////	// HDR
////	var hdrWhite: Float = 0.0
////	var hdrHighlight: Float = 0.0
////	var hdrShadow: Float = 0.0
////	var hdrBlack: Float = 0.0
////
////
////	// Preview HSD
////	var previewRed: Bool = false
////	var previewGreen: Bool = false
////	var previewBlue: Bool = false
////	var previewCyan: Bool = false
////	var previewMagenta: Bool = false
////	var previewYellow: Bool = false
////
////
////	// HSD
////	var redHue: Float = 0.0
////	var redSat: Float = 0.0
////	var redDen: Float = 0.0
////
////	var greenHue: Float = 0.0
////	var greenSat: Float = 0.0
////	var greenDen: Float = 0.0
////
////	var blueHue: Float = 0.0
////	var blueSat: Float = 0.0
////	var blueDen: Float = 0.0
////
////	var cyanHue: Float = 0.0
////	var cyanSat: Float = 0.0
////	var cyanDen: Float = 0.0
////
////	var magentaHue: Float = 0.0
////	var magentaSat: Float = 0.0
////	var magentaDen: Float = 0.0
////
////	var yellowHue: Float = 0.0
////	var yellowSat: Float = 0.0
////	var yellowDen: Float = 0.0
////}
//
//
//// MARK: - Texture
//
//
//struct TextureSettings: Codable {
//	
//	// MTF Curve
//	var applyMTF: Bool = false
//	var mtfBlend: Float = 50.0
//	
//	
//	// Grain
//	var applyGrain: Bool = false
//	var grainAmount: Float = 50.0
//	var selectedGateWidth: Int = 0
//	var scaleGrainToFormat: Bool = false
//	
//	// Print halation
//	var radiusMultiplier: CGFloat = 50.0
//	var radiusExponent: CGFloat = 0.0
//	var opacityMultiplier: Float = 50.0
//	var applyPrintHalation: Bool = false
//	
//}
//
//
//
//// MARK: - Neg Conversion
//
//struct NegConvertSettings: Codable {
//	
//	var convertToNeg: Bool = false
//	var stockChoice: Int = 0 {
//		didSet {
//			print("\n\nStock choice changed to: \(stockChoice)\n\n")
//		}
//	}
//
//	
//}
//
//
//// MARK: - Enlarger Settings
//
//struct EnlargerSettings: Codable {
//	var applyPrintMode: Bool = false
//
////	var enlargerExp: Float = 12.0
//	var enlargerExp: Float = 0.0
//	
//	var enlargerFStop: Float = 11.0
//	
//	var bwMode: Bool = false
//	
//	var cyan: Float = 0.0
//	
////	var magenta: Float = 46.0
//	var magenta: Float = 0.0
//	
////	var yellow: Float = 87.0
//	var yellow: Float = 0.0
//
//	
//	var applyFlash: Bool = false
//	
//	var useLegacy: Bool = true
//}
//
//
//// MARK: - Scan Settings
//
//struct ScanSettings: Codable {
//	
//	var applyScanMode: Bool = false
//	
//	var applyPFE: Bool = false
//	
//	var offsetRGB: Float = 0.0
//	
//	
//	var offsetRed: Float = 0.0
//	
//	
//	var offsetGreen: Float = 0.0
//	
//	
//	var offsetBlue: Float = 0.0
//	
//	var scanContrast: Float = 0.0
//	
//	var lutBlend: Float = 100.0
//	
//}
//
