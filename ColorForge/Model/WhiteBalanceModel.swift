//
//  WhiteBalanceModel.swift
//  ColorForge
//
//  Created by admin on 02/06/2025.
//

import Foundation
import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import CoreVideo
import SwiftUI
import AppKit
import simd




class WhiteBalanceModel {
	static let shared = WhiteBalanceModel()
	
	public var X: Float = 0.3
	public var Y: Float = 0.3
	
	public var sourceTemp: Float = 6500
	public var sourceTint: Float = 0.0
	
//	func updateFromNeutralChromaticity(_ neutralChromaticity: CGPoint) {
//		let sourceSIMDXY = SIMD2<Float>(Float(neutralChromaticity.x), Float(neutralChromaticity.y))
//		
//		DispatchQueue.global(qos: .userInitiated).async {
//			let tempTint = self.toTemperatureTint(xy: sourceSIMDXY)
//			
//			DispatchQueue.main.async {
//				self.X = sourceSIMDXY.x
//				self.Y = sourceSIMDXY.y
//				self.sourceTemp = tempTint.x
//				self.sourceTint = tempTint.y
//				
//				// Optional: Update FilterPipeline.shared or notify observers
//				FilterPipeline.shared.temp = tempTint.x
//				FilterPipeline.shared.tint = tempTint.y
//				FilterPipeline.shared.initTemp = tempTint.x
//				FilterPipeline.shared.initTint = tempTint.y
//			}
//		}
//	}
	
	// MARK: - Constants
	
	struct RUVT {
		let r: Float
		let u: Float
		let v: Float
		let t: Float
	}
	
	let kTempTable: [RUVT] = [
		RUVT(r:    0, u: 0.18006, v: 0.26352, t: -0.24341),
		RUVT(r:   10, u: 0.18066, v: 0.26589, t: -0.25479),
		RUVT(r:   20, u: 0.18133, v: 0.26846, t: -0.26876),
		RUVT(r:   30, u: 0.18208, v: 0.27119, t: -0.28539),
		RUVT(r:   40, u: 0.18293, v: 0.27407, t: -0.30470),
		RUVT(r:   50, u: 0.18388, v: 0.27709, t: -0.32675),
		RUVT(r:   60, u: 0.18494, v: 0.28021, t: -0.35156),
		RUVT(r:   70, u: 0.18611, v: 0.28342, t: -0.37915),
		RUVT(r:   80, u: 0.18740, v: 0.28668, t: -0.40955),
		RUVT(r:   90, u: 0.18880, v: 0.28997, t: -0.44278),
		RUVT(r:  100, u: 0.19032, v: 0.29326, t: -0.47888),
		RUVT(r:  125, u: 0.19462, v: 0.30141, t: -0.58204),
		RUVT(r:  150, u: 0.19962, v: 0.30921, t: -0.70471),
		RUVT(r:  175, u: 0.20525, v: 0.31647, t: -0.84901),
		RUVT(r:  200, u: 0.21142, v: 0.32312, t: -1.0182),
		RUVT(r:  225, u: 0.21807, v: 0.32909, t: -1.2168),
		RUVT(r:  250, u: 0.22511, v: 0.33439, t: -1.4512),
		RUVT(r:  275, u: 0.23247, v: 0.33904, t: -1.7298),
		RUVT(r:  300, u: 0.24010, v: 0.34308, t: -2.0637),
		RUVT(r:  325, u: 0.24702, v: 0.34655, t: -2.4681),
		RUVT(r:  350, u: 0.25591, v: 0.34951, t: -2.9641),
		RUVT(r:  375, u: 0.26400, v: 0.35200, t: -3.5814),
		RUVT(r:  400, u: 0.27218, v: 0.35407, t: -4.3633),
		RUVT(r:  425, u: 0.28039, v: 0.35577, t: -5.3762),
		RUVT(r:  450, u: 0.28863, v: 0.35714, t: -6.7262),
		RUVT(r:  475, u: 0.29685, v: 0.35823, t: -8.5955),
		RUVT(r:  500, u: 0.30505, v: 0.35907, t: -11.324),
		RUVT(r:  525, u: 0.31320, v: 0.35968, t: -15.628),
		RUVT(r:  550, u: 0.32129, v: 0.36011, t: -23.325),
		RUVT(r:  575, u: 0.32931, v: 0.36038, t: -40.770),
		RUVT(r:  600, u: 0.33724, v: 0.36051, t: -116.45)
	]
	
	
	
	// Martices
	private let displayP3ToXYZ = float3x3([
		SIMD3(0.4865709, 0.2656676, 0.1982173),
		SIMD3(0.2289746, 0.6917385, 0.0792869),
		SIMD3(0.0000000, 0.0451134, 1.0439443)
	])
	
	private let xyzToDisplayP3 = float3x3([
		SIMD3( 2.4934969, -0.9313836, -0.4027108),
		SIMD3(-0.8294889,  1.7626641,  0.0236247),
		SIMD3( 0.0358458, -0.0761724,  0.9568845)
	])
	
	// Bradford CAT matrices
	public let bradford: float3x3 = float3x3([
		SIMD3( 0.8951,  0.2664, -0.1614),
		SIMD3(-0.7502,  1.7135,  0.0367),
		SIMD3( 0.0389, -0.0685,  1.0296)
	])
	
	public let bradfordInv: float3x3 = float3x3([
		SIMD3( 0.9869929, -0.1470543, 0.1599627),
		SIMD3( 0.4323053,  0.5183603, 0.0492912),
		SIMD3(-0.0085287,  0.0400428, 0.9684867)
	])
	
	
	// MARK: - Helper functions
	private func xyToXYZ(_ xy: SIMD2<Float>) -> SIMD3<Float> {
		let x = xy.x
		let y = xy.y
		let Y: Float = 1.0
		let X = x * (Y / y)
		let Z = (1.0 - x - y) * (Y / y)
		return SIMD3<Float>(X, Y, Z)
	}
	
	func chromaticAdaptationMatrix(tempAndTint: SIMD2<Float>, sourceWhiteXY: SIMD2<Float>) -> (matrix: float3x3, xy: SIMD2<Float>) {
		let destWhiteXY = xyFromTemperatureTint(tempAndTint)
		let sourceXYZ = xyToXYZ(sourceWhiteXY)
		let destXYZ = xyToXYZ(destWhiteXY)

		let sourceLMS = bradford * sourceXYZ
		let destLMS = bradford * destXYZ

		let scale = SIMD3<Float>(
			destLMS.x / sourceLMS.x,
			destLMS.y / sourceLMS.y,
			destLMS.z / sourceLMS.z
		)

		let diag = float3x3(diagonal: scale)
		let adaptationXYZ = bradfordInv * diag * bradford

		// Wrap CAT in Display P3 working space
		let adaptationP3 = xyzToDisplayP3 * adaptationXYZ * displayP3ToXYZ

		return (matrix: adaptationP3, xy: destWhiteXY)
	}
	
	
	// MARK: - Temp and Tint to XY
	
	private func xyFromTemperatureTint(_ tempTint: SIMD2<Float>) -> SIMD2<Float> {
		let temp = tempTint.x
		let tint = tempTint.y
		let recip = 1.0e6 / temp

		var u: Float = 0
		var v: Float = 0

		for i in 1..<kTempTable.count {
			if recip > kTempTable[i].r || i == kTempTable.count - 1 {
				let r0 = kTempTable[i - 1].r
				let r1 = kTempTable[i].r
				let f = simd_clamp((recip - r1) / (r0 - r1), 0.0, 1.0)

				let baseU = kTempTable[i - 1].u * f + kTempTable[i].u * (1 - f)
				let baseV = kTempTable[i - 1].v * f + kTempTable[i].v * (1 - f)

				let slope0 = kTempTable[i - 1].t
				let slope1 = kTempTable[i].t
				let slope = slope0 * f + slope1 * (1 - f)

				let kTintScale: Float = -3000.0
				let du: Float = 1.0 / sqrt(1 + slope * slope)
				let dv: Float = slope * du

				let scale = tint / kTintScale

				u = baseU + du * scale
				v = baseV + dv * scale

				break
			}
		}

		// Convert uv → xy (CIE 1960 to CIE 1931)
		let denom = (6 * u) - (16 * v) + 12
		let x = (9 * u) / denom
		let y = (4 * v) / denom
		return SIMD2<Float>(x, y)
	}
	
	
	// MARK: - XY To Temp and Tint
	
	func toTemperatureTint(xy: SIMD2<Float>) -> SIMD2<Float> {
		let kTintScale: Float = -3000.0
		let x = xy.x
		let y = xy.y
		
		let u = 2.0 * x / (1.5 - x + 6.0 * y)
		let v = 3.0 * y / (1.5 - x + 6.0 * y)
		
		var last_dt: Float = 0
		var last_du: Float = 0
		var last_dv: Float = 0
		
		for i in 1..<kTempTable.count {
			let du: Float = 1.0
			let dv: Float = kTempTable[i].t
			let len = sqrt(du * du + dv * dv)
			let norm_du = du / len
			let norm_dv = dv / len
			
			let uu = u - kTempTable[i].u
			let vv = v - kTempTable[i].v
			
			let dt = -uu * norm_dv + vv * norm_du
			
			if dt <= 0.0 || i == kTempTable.count - 1 {
				let f: Float = (i == 1 || dt == 0) ? 0.0 : dt / (last_dt + dt)
				
				let recipTemp = kTempTable[i - 1].r * f + kTempTable[i].r * (1.0 - f)
				let temperature = 1.0e6 / recipTemp
				
				let interpU = kTempTable[i - 1].u * f + kTempTable[i].u * (1.0 - f)
				let interpV = kTempTable[i - 1].v * f + kTempTable[i].v * (1.0 - f)
				
				let uu2 = u - interpU
				let vv2 = v - interpV
				
				let final_du = norm_du * (1.0 - f) + last_du * f
				let final_dv = norm_dv * (1.0 - f) + last_dv * f
				let final_len = sqrt(final_du * final_du + final_dv * final_dv)
				
				let tint = ((uu2 * final_du + vv2 * final_dv) / final_len) * kTintScale
				
				return SIMD2<Float>(temperature, tint)
			}
			
			last_dt = dt
			last_du = norm_du
			last_dv = norm_dv
		}
		
		return SIMD2<Float>(6500.0, 0.0) // fallback
	}
	
	
	
	
}
