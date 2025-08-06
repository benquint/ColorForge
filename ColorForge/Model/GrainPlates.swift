//
//  GrainPlates.swift
//  ColorForge
//
//  Created by admin on 06/06/2025.
//

import Foundation
import CoreImage

class GrainPlates {
	static let shared = GrainPlates()
	
	// Full Size Variables
	public var fullsize_grainHighLargeCropMediumSensorWidth: CIImage?
	public var fullsize_grainHighLargeHalfFrameWidth: CIImage?
	public var fullsize_grainHighLargeMediumFormatWidth: CIImage?
	public var fullsize_grainHighLargeMotion8mm: CIImage?
	public var fullsize_grainHighLargeMotion16mm: CIImage?
	public var fullsize_grainHighLargeMotionStandard35mm: CIImage?
	public var fullsize_grainHighLargeMotionSuper8: CIImage?
	public var fullsize_grainHighLargeMotionSuper35: CIImage?
	public var fullsize_grainHighLargeThirtyFiveWidth: CIImage?

	public var fullsize_grainLowLargeCropMediumSensorWidth: CIImage?
	public var fullsize_grainLowLargeHalfFrameWidth: CIImage?
	public var fullsize_grainLowLargeMediumFormatWidth: CIImage?
	public var fullsize_grainLowLargeMotion8mm: CIImage?
	public var fullsize_grainLowLargeMotion16mm: CIImage?
	public var fullsize_grainLowLargeMotionStandard35mm: CIImage?
	public var fullsize_grainLowLargeMotionSuper8: CIImage?
	public var fullsize_grainLowLargeMotionSuper35: CIImage?
	public var fullsize_grainLowLargeThirtyFiveWidth: CIImage?
	
	public let grainHighLargeCropMediumSensorWidth = Bundle.main.url(forResource: "GrainHigh_Large_cropMediumSensorWidth", withExtension: "png")
	public var display_grainHighLargeCropMediumSensorWidth: CIImage?

	public let grainHighLargeHalfFrameWidth = Bundle.main.url(forResource: "GrainHigh_Large_halfFrameWidth", withExtension: "png")
	public var display_grainHighLargeHalfFrameWidth: CIImage?

	public let grainHighLargeMediumFormatWidth = Bundle.main.url(forResource: "GrainHigh_Large_mediumFormatWidth", withExtension: "png")
	public var display_grainHighLargeMediumFormatWidth: CIImage?

	public let grainHighLargeMotion8mm = Bundle.main.url(forResource: "GrainHigh_Large_motion8mm", withExtension: "png")
	public var display_grainHighLargeMotion8mm: CIImage?

	public let grainHighLargeMotion16mm = Bundle.main.url(forResource: "GrainHigh_Large_motion16mm", withExtension: "png")
	public var display_grainHighLargeMotion16mm: CIImage?

	public let grainHighLargeMotionStandard35mm = Bundle.main.url(forResource: "GrainHigh_Large_motionStandard35mm", withExtension: "png")
	public var display_grainHighLargeMotionStandard35mm: CIImage?

	public let grainHighLargeMotionSuper8 = Bundle.main.url(forResource: "GrainHigh_Large_motionSuper8", withExtension: "png")
	public var display_grainHighLargeMotionSuper8: CIImage?

	public let grainHighLargeMotionSuper35 = Bundle.main.url(forResource: "GrainHigh_Large_motionSuper35", withExtension: "png")
	public var display_grainHighLargeMotionSuper35: CIImage?

	public let grainHighLargeThirtyFiveWidth = Bundle.main.url(forResource: "GrainHigh_Large_thirtyFiveWidth", withExtension: "png")
	public var display_grainHighLargeThirtyFiveWidth: CIImage?

	public let grainLowLargeCropMediumSensorWidth = Bundle.main.url(forResource: "GrainLow_Large_cropMediumSensorWidth", withExtension: "png")
	public var display_grainLowLargeCropMediumSensorWidth: CIImage?

	public let grainLowLargeHalfFrameWidth = Bundle.main.url(forResource: "GrainLow_Large_halfFrameWidth", withExtension: "png")
	public var display_grainLowLargeHalfFrameWidth: CIImage?

	public let grainLowLargeMediumFormatWidth = Bundle.main.url(forResource: "GrainLow_Large_mediumFormatWidth", withExtension: "png")
	public var display_grainLowLargeMediumFormatWidth: CIImage?

	public let grainLowLargeMotion8mm = Bundle.main.url(forResource: "GrainLow_Large_motion8mm", withExtension: "png")
	public var display_grainLowLargeMotion8mm: CIImage?

	public let grainLowLargeMotion16mm = Bundle.main.url(forResource: "GrainLow_Large_motion16mm", withExtension: "png")
	public var display_grainLowLargeMotion16mm: CIImage?

	public let grainLowLargeMotionStandard35mm = Bundle.main.url(forResource: "GrainLow_Large_motionStandard35mm", withExtension: "png")
	public var display_grainLowLargeMotionStandard35mm: CIImage?

	public let grainLowLargeMotionSuper8 = Bundle.main.url(forResource: "GrainLow_Large_motionSuper8", withExtension: "png")
	public var display_grainLowLargeMotionSuper8: CIImage?

	public let grainLowLargeMotionSuper35 = Bundle.main.url(forResource: "GrainLow_Large_motionSuper35", withExtension: "png")
	public var display_grainLowLargeMotionSuper35: CIImage?

	public let grainLowLargeThirtyFiveWidth = Bundle.main.url(forResource: "GrainLow_Large_thirtyFiveWidth", withExtension: "png")
	public var display_grainLowLargeThirtyFiveWidth: CIImage?

	var allURLs: [URL] {
		return [
			grainHighLargeCropMediumSensorWidth,
			grainHighLargeHalfFrameWidth,
			grainHighLargeMediumFormatWidth,
			grainHighLargeMotion8mm,
			grainHighLargeMotion16mm,
			grainHighLargeMotionStandard35mm,
			grainHighLargeMotionSuper8,
			grainHighLargeMotionSuper35,
			grainHighLargeThirtyFiveWidth,
			grainLowLargeCropMediumSensorWidth,
			grainLowLargeHalfFrameWidth,
			grainLowLargeMediumFormatWidth,
			grainLowLargeMotion8mm,
			grainLowLargeMotion16mm,
			grainLowLargeMotionStandard35mm,
			grainLowLargeMotionSuper8,
			grainLowLargeMotionSuper35,
			grainLowLargeThirtyFiveWidth
		].compactMap { $0 }
	}
}
