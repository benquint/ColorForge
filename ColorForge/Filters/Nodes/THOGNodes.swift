//
//  THOGNodes.swift
//  ColorForge
//
//  Created by Ben Quinton on 24/07/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics



//struct THOGNode: FilterNode {
//    let applyTHOG: Bool
//    let isExport: Bool
//    let blend: Float
//    let variance: Float
//    let scale: Float
//    
//    func apply(to input: CIImage) -> CIImage {
//        
//        // Step 1 = Apply the grain plate using overlay blend (arri ovelay)
//        // Step 2 = Convert to neg
//        // Step 3 = Apply a small amount of softening via MTF Node using 5x4 band
//        // Step 4 = Apply random Perlin Noise based brightening etc
//        // Step 4 = Apply Print Softening
//        // Step 5 = Apply Print Lut
//        // Step 6 = Normalise
//        // Step 7 = Add borders
//        
//        guard applyTHOG else {return input}
//        
//        let aspectRatio = input.extent.width / input.extent.height
//
//        var cropWidth = (input.extent.height / 3.25) * 4.25
//        var cropHeight = input.extent.height
//
//        if aspectRatio < 1.0 {
//            cropWidth = input.extent.width
//            cropHeight = (input.extent.width / 3.25) * 4.25
//        }
//
//
//        let cropped = input.applyingFilter("CICrop", parameters: [
//            "inputRectangle": CIVector(cgRect: CGRect(
//                x: 0, y: 0,
//                width: cropWidth,
//                height: cropHeight
//            ))
//        ])
//
//        var plate = isExport ? GrainModel.shared.fp100PlateLarge : GrainModel.shared.fp100PlateSmall
//
//        // Rotate if plate is landscape and cropped image is portrait
//        let plateIsLandscape = plate.extent.width >= plate.extent.height
//        let croppedIsPortrait = cropped.extent.height > cropped.extent.width
//
//        if plateIsLandscape && croppedIsPortrait {
//            let center = CGPoint(x: plate.extent.midX, y: plate.extent.midY)
//            plate = plate.transformed(
//                by: CGAffineTransform(translationX: -center.x, y: -center.y)
//                    .rotated(by: .pi / 2)
//                    .translatedBy(x: center.y, y: center.x)
//            )
//        }
//
//        // Scale plate so it matches cropped image’s shortest dimension
//        let plateScalar = max(cropped.extent.width, cropped.extent.height) / plate.extent.width
//        plate = plate.transformed(by: CGAffineTransform(scaleX: plateScalar, y: plateScalar))
//
//        // Align plate’s origin to match cropped image’s extent (usually starts at 0,0)
//        let plateAligned = plate.transformed(by: CGAffineTransform(
//            translationX: cropped.extent.origin.x - plate.extent.origin.x,
//            y: cropped.extent.origin.y - plate.extent.origin.y)
//        )
//
//        let grainApplied = cropped.arriSoftLight(plateAligned)
//        
//        let negApplied = grainApplied.applyLut("FPC2N")
//        
//        let mtf1 = MTFCurveNode(
//            applyMTF: true, mtfAmount: 50, format: 9, applyGrain: false, exportMode: isExport, nativeLongEdge: 8000, isExport: isExport
//        ).apply(to: negApplied)
//        
//        let print1 = mtf1.applyLut("FPN2P")
//        
//        let refined = print1.applyLut("FPRefineRGB")
//            
//        let lift = refined.applyLift(-0.11)
//        let gain = lift.multiplyByVal(1.2, 0)
//        
//        
//
//        let dithered2 = gain.dither(0.1)
//        
//        
//        let mtf2 = MTFCurveNode(
//            applyMTF: true, mtfAmount: 80, format: 10, applyGrain: false, exportMode: isExport, nativeLongEdge: 8000, isExport: isExport
//        ).apply(to: dithered2)
//
//
//
//        let perlin = mtf2.perlinColor(scale, variance, blend)
//        
//        let crop2 = perlin.applyingFilter("CICrop", parameters: [
//            "inputRectangle": CIVector(cgRect: cropped.extent)
//        ])
//        
//        return crop2
//    }
//
//}
//


struct TomJamiesonFilter: FilterNode {
    let applyTom: Bool
    
    func apply(to input: CIImage) -> CIImage {
        guard applyTom else {return input}
        
        let bodyColor = CIImage(color: CIColor(red: 0.816, green: 0.694, blue: 0.549)).cropped(to: input.extent)
        let headColor = CIImage(color: CIColor(red: 0.855, green: 0.604, blue: 0.682)).cropped(to: input.extent)
        let splurgeColor = CIImage(color: CIColor(red: 0.918, green: 0.910, blue: 0.835)).cropped(to: input.extent)
        
        guard let url_body = Bundle.main.url(forResource: "TomBody", withExtension: "png"),
              var body = CIImage(contentsOf: url_body) else {
            print("Couldnt get body mask")
            return input
        }
        
        guard let url_head = Bundle.main.url(forResource: "TomHead", withExtension: "png"),
              var head = CIImage(contentsOf: url_head) else {
            print("Couldnt get head mask")
            return input
        }
        
        guard let url_splurge = Bundle.main.url(forResource: "TomJuice", withExtension: "png"),
              var splurge = CIImage(contentsOf: url_splurge) else {
            print("Couldnt get splurge mask")
            return input
        }
        
        let scalar = min(input.extent.width, input.extent.height) / max(body.extent.width, body.extent.height)
        
        let inputCenterX = input.extent.midX
        let inputCenterY = input.extent.midY

        func centerMask(_ mask: CIImage, over target: CIImage) -> CIImage {
            let dx = inputCenterX - mask.extent.midX
            let dy = inputCenterY - mask.extent.midY
            return mask.transformed(by: CGAffineTransform(translationX: dx, y: dy))
        }

        // Scale first
        body = body.scaleToValue(scalar)
        head = head.scaleToValue(scalar)
        splurge = splurge.scaleToValue(scalar)

        // Center each over the input
        body = centerMask(body, over: input)
        head = centerMask(head, over: input)
        splurge = centerMask(splurge, over: input)
        
        let bodyImg = input.colorBlendMode(bodyColor)
        let headImg = input.colorBlendMode(headColor)
        let splurgeImg = input.colorBlendMode(splurgeColor)
        

        var final = CIImage(color: .black).cropped(to: input.extent)
        
        final = final.blendWithMask(body, bodyImg)
        final = final.blendWithMask(head, headImg)
        final = final.blendWithMask(splurge, splurgeImg)
        
        return final
    }
    
    
}
