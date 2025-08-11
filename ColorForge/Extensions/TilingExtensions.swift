//
//  TilingExtensions.swift
//  ColorForge
//
//  Created by Ben Quinton on 22/07/2025.
//

import Foundation
import CoreImage
import CoreGraphics
import CoreImage.CIFilterBuiltins
import SwiftUI

extension CIImage {
    
    func evenOutTileExposure() -> CIImage {
//        
//        func evenOut(_ tile: CIImage, _ inverted: CIImage) -> CIImage {
//            let kernel = CIColorKernelCache.shared.evenTile
//            guard let result = kernel.apply(
//                extent: self.extent,
//                roiCallback: { _, rect in rect },
//                arguments: [self, inverted]
//            ) else {
//                print("Failed to convert image to capture one")
//                return self}
//            
//            return result
//        }
//        
//
//        let blurVal = self.extent.width / 2.0
//        
//        var tileInverted = self.invertColor()
//        tileInverted = tileInverted.clampedToExtent()
//        tileInverted = tileInverted.gaussianBlur(blurVal)
//        
//        var result = evenOut(self, tileInverted)
//    
//        return result.cropped(to: self.extent)
        
        return self
    }
    
    
    func tileAndRotateFull(_ tile: CIImage) async -> CIImage {
        let targetSize2 = CGSize(width: 4096.0, height: 4096.0)
        let finalTarget = self.extent.size

        // If the tile is already bigger than the image, just crop it
        if tile.extent.width > self.extent.width && tile.extent.height > self.extent.height {
            return tile.cropped(to: self.extent)
        }
        
        if targetSize2.width > max(self.extent.width, self.extent.height) {
            
            let finalTile = await tile.tileAndRotateAsCGImage(finalTarget)
            return finalTile
        }

        // For very small tiles, do two tiling passes sequentially (both async)
        if tile.extent.width < max(self.extent.width, self.extent.height) / 4.0 {
            // First tiling pass
            let intermediate = await tile.tileAndRotateAsCGImage(targetSize2)
            
//            debugSave(intermediate, "intermediate")
            // Second tiling pass (depends on the first)
            let finalTile = await intermediate.tileAndRotateAsCGImage(finalTarget)
            return finalTile
        } else {
            // For larger tiles, only one tiling pass is needed
            let finalTile = await tile.tileAndRotateAsCGImage(finalTarget)

            return finalTile
        }
    }
    
//    // Input tile now 2048x2048
//    func tileAndRotateFull(_ tile: CIImage) -> CIImage {
//
//        let targetSize2 = CGSize(width: 4096.0, height: 4096.0)
//        let finalTarget = self.extent.size
//        
//        
//        var tile1 = tile
//        var finalTile = tile
//        
//        if tile.extent.width > self.extent.width && tile.extent.height > self.extent.height {
//            return tile.cropped(to: self.extent)
//        }
//
//        if tile.extent.width < max(self.extent.width, self.extent.height) / 4.0 {
//            tile1 = tile.tileAndRotateAsCGImage(targetSize2)
//            finalTile = tile1.tileAndRotateAsCGImage(finalTarget)
//            return finalTile
//        } else {
//            finalTile = tile.tileAndRotateAsCGImage(finalTarget)
//            return finalTile
//        }
//    }
    
    func tileAndRotate(_ targetSize: CGSize) -> CIImage {
        let targetRect = CGRect(origin: .zero, size: targetSize)
        
        let tileScaleUp = self.extent.insetBy(dx: -self.extent.width * 0.4,
                                                         dy: -self.extent.height * 0.4) // add 10% margin
        let tileCanvas = CIImage(color: .clear).cropped(to: tileScaleUp)
        
        // Add padding
        let tile = self.composited(over: tileCanvas)

        
        let mainCanvasRect = CGRect(
            x: 0.0, y: 0.0,
            width: targetSize.width * 1.6,
            height: targetSize.height * 1.6
            )
        
        let mainCanvas = CIImage(color: .clear).cropped(to: mainCanvasRect)
        
        let baseTileSize = self.extent.width * 0.5
        
        let colsForLargeTile = Int(ceil(mainCanvas.extent.width / baseTileSize)) + 1
        let rowsForLargeTile = Int(ceil(mainCanvas.extent.height / baseTileSize)) + 1
        
        func tilePlate (_ inputTile: CIImage) -> CIImage {
            var canvas = CIImage(color: .clear).cropped(to: mainCanvasRect)
            
            for row in 0..<rowsForLargeTile {
                for col in 0..<colsForLargeTile {
                    let angle = CGFloat.random(in: -0.025...0.025)
                    let center = CGPoint(x: tile.extent.midX, y: tile.extent.midY)
                    let rotation = CGAffineTransform(translationX: -center.x, y: -center.y)
                        .rotated(by: angle)
                        .translatedBy(x: center.x, y: center.y)
                    
                    let xPos = CGFloat(col) * baseTileSize
                    let yPos = CGFloat(row) * baseTileSize
                    let translation = CGAffineTransform(translationX: xPos, y: yPos)
                    
                    let transformedTile = tile.transformed(by: rotation.concatenating(translation))
                    canvas = transformedTile.composited(over: canvas)
                }
            }
            
            let offsetX = -((canvas.extent.width - targetSize.width) / 2.0)
            let offsetY = -((canvas.extent.height - targetSize.height) / 2.0)
            
            let translated = canvas.transformed(by: CGAffineTransform(translationX: offsetX, y: offsetY))
            
            
            let tileCropped = translated.cropped(to: targetRect)
            
            
            return tileCropped
        }
        
        
        // Concurrent blur creation
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .utility)
        
        var plate1 = tile
        var plate2 = tile
        var plate3 = tile
        
        group.enter()
        queue.async {
            plate1 = tilePlate(tile)
            group.leave()
        }
        group.enter()
        queue.async {
            plate2 = tilePlate(tile)
            group.leave()
        }
        group.enter()
        queue.async {
            plate3 = tilePlate(tile)
            group.leave()
        }
        
        group.wait()
        
        let grey = CIImage(color: .gray).cropped(to: targetRect)
        var finalTile = plate2.composited(over: plate1)
        finalTile = plate3.composited(over: finalTile)
        finalTile = finalTile.composited(over: grey)
        
        let cached = finalTile.convertToCGImageAndCache()
        
        return finalTile
    }
    

    func tileAndRotateAsCGImage(_ targetSize: CGSize) async -> CIImage {
        let targetRect = CGRect(origin: .zero, size: targetSize)
        let context = RenderingManager.shared.exportContext
        
        let paddingX = self.extent.width * 0.6
        let paddingY = self.extent.height * 0.6

        let tileScaleUp = self.extent.insetBy(dx: -paddingX, dy: -paddingY)
        let tileCanvas = CIImage(color: .clear).cropped(to: tileScaleUp)
        let tile = self.composited(over: tileCanvas)
        
//        debugSave(tile, "SoftenedTile")
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Canvas for big tiling
        let mainCanvasRect = CGRect(
            x: 0.0, y: 0.0,
            width: targetSize.width * 1.6,
            height: targetSize.height * 1.6
        )
        
        let baseTileSize = self.extent.width * 0.5
        let colsForLargeTile = Int(ceil(mainCanvasRect.width / baseTileSize)) + 1
        let rowsForLargeTile = Int(ceil(mainCanvasRect.height / baseTileSize)) + 1
        
        
        func makePlateCGImage(_ inputTile: CIImage) -> CGImage? {
            guard let plateContext = CGContext(data: nil,
                                               width: Int(mainCanvasRect.width),
                                               height: Int(mainCanvasRect.height),
                                               bitsPerComponent: 8,
                                               bytesPerRow: 0,
                                               space: colorSpace,
                                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return nil }
            
            plateContext.translateBy(x: 0, y: mainCanvasRect.height)
            plateContext.scaleBy(x: 1.0, y: -1.0)
            
            guard let tileCG = context.createCGImage(inputTile, from: inputTile.extent) else { return nil }
            let tileCenter = CGPoint(x: CGFloat(tileCG.width) / 2, y: CGFloat(tileCG.height) / 2)
            
            // Slight random offset for the whole plate (each plate is nudged differently)
            let plateOffsetX = CGFloat.random(in: -baseTileSize * 0.25...baseTileSize * 0.25)
            let plateOffsetY = CGFloat.random(in: -baseTileSize * 0.25...baseTileSize * 0.25)
            
            // Slightly reduce tile size so they overlap (avoiding visible seams)
            let adjustedTileSize = baseTileSize * 0.95
            
            for row in 0..<rowsForLargeTile {
                for col in 0..<colsForLargeTile {
                    // Base grid-aligned position
                    var xPos = plateOffsetX + CGFloat(col) * adjustedTileSize
                    var yPos = plateOffsetY + CGFloat(row) * adjustedTileSize

                    // Add random jitter to break perfect alignment
                    xPos += CGFloat.random(in: -adjustedTileSize * 0.1...adjustedTileSize * 0.1)
                    yPos += CGFloat.random(in: -adjustedTileSize * 0.1...adjustedTileSize * 0.1)

                    // Random rotation per tile (±3°)
                    let angle = CGFloat.random(in: -0.1...0.1)

                    plateContext.saveGState()

                    // Translate to tile center for rotation
                    plateContext.translateBy(x: xPos + tileCenter.x, y: yPos + tileCenter.y)

                    // Apply rotation (no scaling)
                    plateContext.rotate(by: angle)

                    // Translate back and draw
                    plateContext.translateBy(x: -tileCenter.x, y: -tileCenter.y)
                    plateContext.draw(tileCG, in: CGRect(origin: .zero,
                                                         size: CGSize(width: tileCG.width,
                                                                      height: tileCG.height)))

                    plateContext.restoreGState()
                }
            }
            
            return plateContext.makeImage()
        }
  
        
        // Generate plates concurrently using TaskGroup
        let plates: [CGImage] = await withTaskGroup(of: CGImage?.self) { group in
            for _ in 0..<3 {
                group.addTask {
                    return makePlateCGImage(tile)
                }
            }
            
            var results: [CGImage] = []
            for await plate in group {
                if let plate = plate {
                    results.append(plate)
                }
            }
            return results
        }
        
        // Composite plates into final CGImage
        guard let finalContext = CGContext(data: nil,
                                           width: Int(targetSize.width),
                                           height: Int(targetSize.height),
                                           bitsPerComponent: 8,
                                           bytesPerRow: 0,
                                           space: colorSpace,
                                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return self }
        
        finalContext.translateBy(x: 0, y: targetSize.height)
        finalContext.scaleBy(x: 1.0, y: -1.0)
        
        let offsetX = -((mainCanvasRect.width - targetSize.width) / 2.0)
        let offsetY = -((mainCanvasRect.height - targetSize.height) / 2.0)
        
        finalContext.setFillColor(NSColor.gray.cgColor)
        finalContext.fill(CGRect(origin: .zero, size: targetSize))
        
        for plate in plates {
            finalContext.draw(plate, in: CGRect(origin: CGPoint(x: offsetX, y: offsetY),
                                                size: mainCanvasRect.size))
        }
        
        guard let finalCGImage = finalContext.makeImage() else { return self }
        return CIImage(cgImage: finalCGImage)
    }
    
// 
//        func tileAndRotateAsCGImage(_ targetSize: CGSize) -> CIImage {
//            let targetRect = CGRect(origin: .zero, size: targetSize)
//            let context = RenderingManager.shared.exportContext
//            
//            // Prepare tile with padding
//            let tileScaleUp = self.extent.insetBy(dx: -self.extent.width * 0.4,
//                                                  dy: -self.extent.height * 0.4)
//            let tileCanvas = CIImage(color: .clear).cropped(to: tileScaleUp)
//            let tile = self.composited(over: tileCanvas)
//            
//            let colorSpace = CGColorSpaceCreateDeviceRGB()
//            
//            // Canvas for big tiling
//            let mainCanvasRect = CGRect(
//                x: 0.0, y: 0.0,
//                width: targetSize.width * 1.6,
//                height: targetSize.height * 1.6
//            )
//            
//            let baseTileSize = self.extent.width * 0.5
//            let colsForLargeTile = Int(ceil(mainCanvasRect.width / baseTileSize)) + 1
//            let rowsForLargeTile = Int(ceil(mainCanvasRect.height / baseTileSize)) + 1
//            
//            func makePlateCGImage(_ inputTile: CIImage) -> CGImage? {
//                guard let cgColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
//                guard let plateContext = CGContext(data: nil,
//                                                   width: Int(mainCanvasRect.width),
//                                                   height: Int(mainCanvasRect.height),
//                                                   bitsPerComponent: 8,
//                                                   bytesPerRow: 0,
//                                                   space: colorSpace,
//                                                   bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
//                else { return nil }
//                
//                plateContext.translateBy(x: 0, y: mainCanvasRect.height)
//                plateContext.scaleBy(x: 1.0, y: -1.0)
//                
//                guard let tileCG = context.createCGImage(inputTile, from: inputTile.extent) else { return nil }
//                let tileCenter = CGPoint(x: CGFloat(tileCG.width) / 2, y: CGFloat(tileCG.height) / 2)
//                
//                for row in 0..<rowsForLargeTile {
//                    for col in 0..<colsForLargeTile {
//                        let xPos = CGFloat(col) * baseTileSize
//                        let yPos = CGFloat(row) * baseTileSize
//                        let angle = CGFloat.random(in: -0.025...0.025)
//                        
//                        plateContext.saveGState()
//                        plateContext.translateBy(x: xPos + tileCenter.x, y: yPos + tileCenter.y)
//                        plateContext.rotate(by: angle)
//                        plateContext.translateBy(x: -tileCenter.x, y: -tileCenter.y)
//                        plateContext.draw(tileCG, in: CGRect(origin: .zero,
//                                                             size: CGSize(width: tileCG.width,
//                                                                          height: tileCG.height)))
//                        plateContext.restoreGState()
//                    }
//                }
//                
//                return plateContext.makeImage()
//            }
//            
//            // Generate plates concurrently
//            let group = DispatchGroup()
//            let queue = DispatchQueue.global(qos: .userInitiated)
//            var plate1: CGImage?
//            var plate2: CGImage?
//            var plate3: CGImage?
//            
//            group.enter()
//            queue.async {
//                plate1 = makePlateCGImage(tile)
//                group.leave()
//            }
//            group.enter()
//            queue.async {
//                plate2 = makePlateCGImage(tile)
//                group.leave()
//            }
//            group.enter()
//            queue.async {
//                plate3 = makePlateCGImage(tile)
//                group.leave()
//            }
//            
//            group.wait()
//            
//            // Composite plates into final CGImage
//            guard let cgColorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return self }
//            guard let finalContext = CGContext(data: nil,
//                                               width: Int(targetSize.width),
//                                               height: Int(targetSize.height),
//                                               bitsPerComponent: 8,
//                                               bytesPerRow: 0,
//                                               space: colorSpace,
//                                               bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
//            else { return self }
//            
//            finalContext.translateBy(x: 0, y: targetSize.height)
//            finalContext.scaleBy(x: 1.0, y: -1.0)
//            
//            let offsetX = -((mainCanvasRect.width - targetSize.width) / 2.0)
//            let offsetY = -((mainCanvasRect.height - targetSize.height) / 2.0)
//            
//            finalContext.setFillColor(NSColor.gray.cgColor)
//            finalContext.fill(CGRect(origin: .zero, size: targetSize))
//            
//            for plate in [plate1, plate2, plate3] {
//                if let plate = plate {
//                    finalContext.draw(plate, in: CGRect(origin: CGPoint(x: offsetX, y: offsetY),
//                                                        size: mainCanvasRect.size))
//                }
//            }
//            
//            guard let finalCGImage = finalContext.makeImage() else { return self }
//            return CIImage(cgImage: finalCGImage)
//        }
//    
    
}
