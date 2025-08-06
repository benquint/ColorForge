//
//  QuickFilters.swift
//  ColorForge
//
//  Created by Ben Quinton on 28/07/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import simd
import AppKit


extension CIImage {
    
    
    func colorCurves(_ curveData: Data) -> CIImage {
        let colorCurvesEffect = CIFilter.colorCurves()
        colorCurvesEffect.inputImage = self
        colorCurvesEffect.curvesDomain = CIVector(x: 0, y: 1)
        colorCurvesEffect.curvesData = curveData
        colorCurvesEffect.colorSpace = CGColorSpaceCreateDeviceRGB()
        return colorCurvesEffect.outputImage!
    }
}
