//
//  PaperExtensions.swift
//  ColorForge
//
//  Created by Ben Quinton on 10/07/2025.
//


import CoreImage

extension CIImage {
    
    
    func scalePaperBlack() -> CIImage {
        let model = PaperModel.shared
        var paper = model.blackPaper

        let targetExtent = self.extent
        let targetAspect = targetExtent.width / targetExtent.height
        let paperAspect = paper.extent.width / paper.extent.height

        // Rotate if orientations mismatch (e.g. one is portrait, one is landscape)
        let targetIsPortrait = targetAspect < 1.0
        let paperIsPortrait = paperAspect < 1.0

        if targetIsPortrait != paperIsPortrait {
            // Rotate 90 degrees around the origin, then translate to keep it positive
            paper = paper
                .oriented(forExifOrientation: 6) // 90° CW
        }

        // Recalculate after potential rotation
        let updatedExtent = paper.extent
        let updatedAspect = updatedExtent.width / updatedExtent.height

        // Determine scale factor to fill the target extent (aspect fill)
        let scaleFactor: CGFloat
        if updatedAspect < targetAspect {
            scaleFactor = targetExtent.width / updatedExtent.width
        } else {
            scaleFactor = targetExtent.height / updatedExtent.height
        }

        // Scale uniformly
        let scaled = paper.transformed(by: .init(scaleX: scaleFactor, y: scaleFactor))

        // Center the result on the target extent
        let offsetX = targetExtent.midX - scaled.extent.midX
        let offsetY = targetExtent.midY - scaled.extent.midY
        let black = scaled.transformed(by: .init(translationX: offsetX, y: offsetY))

        // Crop to match final extent
        return black.cropped(to: targetExtent)
    }
    
    
    
    func scaleAndReturnPaperBorders() -> (CIImage, CIImage) {
        let model = PaperModel.shared
        var borders = model.paperEdge
        let borderWidth: CGFloat = 64.0
        
        let targetExtent = self.extent
        let targetAspect = targetExtent.width / targetExtent.height
        let paperAspect = borders.extent.width / borders.extent.height

        // Rotate if orientations mismatch (e.g. one is portrait, one is landscape)
        let targetIsPortrait = targetAspect < 1.0
        let paperIsPortrait = paperAspect < 1.0

        if targetIsPortrait != paperIsPortrait {
            // Rotate 90 degrees around the origin, then translate to keep it positive
            borders = borders
                .oriented(forExifOrientation: 6) // 90° CW
        }
        
        let borderScaleX = self.extent.width / borders.extent.width
        let borderScaleY = self.extent.height / borders.extent.height
        
        let borderWidthScaledX = borderWidth * borderScaleX
        let borderWidthScaledY = borderWidth * borderScaleY
        
        borders = borders.transformed(by: CGAffineTransform(scaleX: borderScaleX, y: borderScaleY))
        
        // Now subtract the borders from the current image
        let newWidth = targetExtent.width - borderWidthScaledX
        let scale = newWidth / targetExtent.width
        
        print("""
            Calculate shrink scale = \(scale)
            """)

        
        
        let scaledUp = self.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let shifted = scaledUp.transformed(by: CGAffineTransform(translationX: borderWidthScaledX, y: borderScaleY))
        
        return (shifted, borders)
    }

    
    
    
}
