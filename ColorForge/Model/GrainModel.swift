//
//  GrainModel.swift
//  ColorForge
//
//  Created by admin on 29/05/2025.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import CoreVideo
import SwiftUI
import AppKit


class GrainModel {
    static let shared = GrainModel()
    
    init() {
        //        loadGrainPlates()
        
//        self.tileInit54()
        
        
        
        let placeholder = CIImage(color: .clear).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
        fp100PlateLarge = placeholder
        fp100PlateSmall = placeholder

        guard let url = Bundle.main.url(forResource: "Grain_FullGate_8000", withExtension: "jpg"),
              let image = CIImage(contentsOf: url) else {
            return
        }

        fp100PlateLarge = image

        let scale = 3000 / image.extent.width
        let smallPlate = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let smallPlateCached = smallPlate.convertToCGImageAndCache()
        fp100PlateSmall = smallPlateCached
        
//        self.demosaic()
        
//        loadGrainIntoCache()
        
    }
    
    
    
    // MARK: - Generate grain
    
    private var lastGrainExtent: CGRect = .zero
    private var lastGrainSize: CGFloat = 0
    private var lastUiScale: Float = 0
    private var lastGrainPlate: CIImage?
    private var lastID: UUID? = nil
    
    
    func generateGrain(_ id: UUID, _ input: CIImage, _ grainSize: CGFloat, _ uiScale: Float, isExport: Bool) -> CIImage {
        var finalGrain = CIImage(color: .gray).cropped(to: input.extent)
        
        if let prevPlate = lastGrainPlate {
            finalGrain = prevPlate
        }
        
        guard lastID == nil || lastID != id else {
            return finalGrain
        }
        
        lastID = id
        
        // Guard against recalculating if variables havent changed.
        guard input.extent !=  lastGrainExtent else {
            return finalGrain
        }
        
        lastGrainExtent = input.extent
        
//        guard lastUiScale == uiScale else {
//            return finalGrain
//        }
//        
//        lastUiScale = uiScale
        
        

        
        func buildNoise(_ scalar: CGFloat, _ image: CIImage) -> (CIImage, CIImage) {
            
            let scalarMin = scalar - (scalar * 0.05)
            let scalarMax = scalar + (scalar * 0.05)
            let randScalar = CGFloat.random(in: scalarMin...scalarMax)
            
            
            let blur1: Float = 0.25 * Float(randScalar)
            let blur2: Float = 0.5 * Float(randScalar)
            let blur3: Float = 1.5 * Float(randScalar)
            

            
            var noise = image.semiNoise()

            // need to offset by + 0.134
            let offsetImage = CIImage(color: CIColor(red: 0.134, green: 0.134, blue: 0.134))
            
            noise = noise.add(offsetImage)

            print("Noise scalar \(scalar)")
            noise = noise.transformed(by: CGAffineTransform(scaleX: randScalar, y: randScalar))

            
            var blurNoise = blur(noise, blur1)
            noise = noise.mixGrain(blurNoise, 0.5)
            
            
            blurNoise = blur(noise, blur2)
            noise = noise.mixGrain(blurNoise, 0.6)
            
            
            blurNoise = blur(noise, blur3)
            noise = noise.mixGrain(blurNoise, 0.3)
            
            
            let perlin = image.smallPerlin()
            
            return (noise, perlin)
        }
        
        
        func blur(_ blurImage: CIImage, _ blurVal: Float) -> CIImage {
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = blurImage
            filter.radius = blurVal
            guard let outputImage = filter.outputImage else {
                print("Grain blur failed")
                return blurImage }
            return outputImage
        }
        
        
        
        
        
        let width = input.extent.width
        let height = input.extent.height
        
        let gray = CIImage(color: .gray)
        
        let grainSizeDefault: CGFloat = 5
        
        var noiseScalar = CGFloat(uiScale)
        
        if isExport {
            noiseScalar = 1.0
        }
        
        noiseScalar *= 0.4
        let zoomScale = ImageViewModel.shared.zoomScale
        print("ZoomScale = \(zoomScale)")
        
        var grain1 = gray
        var grain2 = gray
        var grain3 = gray
        
        
        var perlin1 = gray
        var perlin2 = gray
        var perlin3 = gray

        // Concurrent blur creation
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .utility)
        
        group.enter()
        queue.async {
            (grain1, perlin1) = buildNoise(noiseScalar, input)
            group.leave()
        }
        
        group.enter()
        queue.async {
            (grain2, perlin2) = buildNoise(noiseScalar, input)
            group.leave()
        }
        
        group.enter()
        queue.async {
            (grain3, perlin3) = buildNoise(noiseScalar, input)
            group.leave()
        }
    
        
        group.wait()
        
        finalGrain = grain1.maskGrain(grain2, grain3, perlin1, perlin2, perlin3)
        let cropped = finalGrain.cropped(to: input.extent)
        finalGrain = cropped
        
        if !isExport {
            let cgImage = finalGrain.convertToCGImageAndCache()
            finalGrain = cgImage
        }
        
        
        
        self.lastGrainPlate = finalGrain
        return finalGrain
    }
    
    
    // Initial load of grain plate
    public var initialGrainPlate: CIImage?
    public var initialGrainPlate2048: CGImage?
    
    // Once made, we render it to the CVPixelBuffer,
    // then load that back into a CIImage to avoid reprocessing each time
    public var grainPlateCIImage: CIImage?
    
    // Load the grain plate into a shared CIImage object
	func loadGrainIntoCache() {
        
        guard let grainURL = Bundle.main.url(forResource: "grainMedFormat_v2", withExtension: "jpg") else {
            print("Failed to load grainMedFormat_v2.jpg from bundle.")
            return
        }
        
        guard let grainImage = CIImage(contentsOf: grainURL) else {
            print("Failed to create CIImage from grain file.")
            return
        }
        
        let scale = 3000 / grainImage.extent.height
        let scaled = grainImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        let context = RenderingManager.shared.mainImageContext
        
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
			print("Failed to create CGImage from Grain Plate")
            return
        }
        
        // Scaled down for UI, to speed up grain plate creation
        initialGrainPlate = grainImage
        initialGrainPlate2048 = cgImage 
        
        print("Successfully Cached Grain Image")
    }
    
    let grainPlates = GrainPlates.shared
    
    private func demosaic() {
        let start = Date() // Start timer

        guard let url = Bundle.main.url(forResource: "Bayer4", withExtension: "tiff"),
              var image = CIImage(contentsOf: url) else {
            return
        }

        // Undo EXIF orientation: Rotate 270 CW = rotate -90° to restore original
        image = image.transformed(by: CGAffineTransform(rotationAngle: -.pi / 2))

        let rgb = image.demosaicBilinear()

        let duration = Date().timeIntervalSince(start) * 1000
        print("\n\n\nBilinear demosaic took \(duration) ms\n\n\n")

        debugSave(rgb, "BilinearTest")
    }
    
    private func loadGrainPlates() {
        
        
        let urls = grainPlates.allURLs  // Assuming 'grainPlates' is a property on your GrainModel
        
        DispatchQueue.global(qos: .utility).async {
            for url in urls {
                guard let grainCiImage = self.cacheGrainTiles(plateUrl: url) else { continue }
                
                
                switch url.lastPathComponent {
                case "GrainHigh_Large_cropMediumSensorWidth.png":
                    self.grainPlates.display_grainHighLargeCropMediumSensorWidth = grainCiImage
                case "GrainHigh_Large_halfFrameWidth.png":
                    self.grainPlates.display_grainHighLargeHalfFrameWidth = grainCiImage
                case "GrainHigh_Large_mediumFormatWidth.png":
                    self.grainPlates.display_grainHighLargeMediumFormatWidth = grainCiImage
                case "GrainHigh_Large_motion8mm.png":
                    self.grainPlates.display_grainHighLargeMotion8mm = grainCiImage
                case "GrainHigh_Large_motion16mm.png":
                    self.grainPlates.display_grainHighLargeMotion16mm = grainCiImage
                case "GrainHigh_Large_motionStandard35mm.png":
                    self.grainPlates.display_grainHighLargeMotionStandard35mm = grainCiImage
                case "GrainHigh_Large_motionSuper8.png":
                    self.grainPlates.display_grainHighLargeMotionSuper8 = grainCiImage
                case "GrainHigh_Large_motionSuper35.png":
                    self.grainPlates.display_grainHighLargeMotionSuper35 = grainCiImage
                case "GrainHigh_Large_thirtyFiveWidth.png":
                    self.grainPlates.display_grainHighLargeThirtyFiveWidth = grainCiImage
                    
                case "GrainLow_Large_cropMediumSensorWidth.png":
                    self.grainPlates.display_grainLowLargeCropMediumSensorWidth = grainCiImage
                case "GrainLow_Large_halfFrameWidth.png":
                    self.grainPlates.display_grainLowLargeHalfFrameWidth = grainCiImage
                case "GrainLow_Large_mediumFormatWidth.png":
                    self.grainPlates.display_grainLowLargeMediumFormatWidth = grainCiImage
                case "GrainLow_Large_motion8mm.png":
                    self.grainPlates.display_grainLowLargeMotion8mm = grainCiImage
                case "GrainLow_Large_motion16mm.png":
                    self.grainPlates.display_grainLowLargeMotion16mm = grainCiImage
                case "GrainLow_Large_motionStandard35mm.png":
                    self.grainPlates.display_grainLowLargeMotionStandard35mm = grainCiImage
                case "GrainLow_Large_motionSuper8.png":
                    self.grainPlates.display_grainLowLargeMotionSuper8 = grainCiImage
                case "GrainLow_Large_motionSuper35.png":
                    self.grainPlates.display_grainLowLargeMotionSuper35 = grainCiImage
                case "GrainLow_Large_thirtyFiveWidth.png":
                    self.grainPlates.display_grainLowLargeThirtyFiveWidth = grainCiImage
                    
                default:
                    print("Unknown grain plate filename: \(url.lastPathComponent)")
                }
            }
        }
    }
    
    // MARK: - FP100 Grain
    
    @Published var fp100PlateSmall: CIImage
    @Published var fp100PlateLarge: CIImage
    
    func loadFP100Plate() {
        guard let url = Bundle.main.url(forResource: "Grain_FullGate_8000", withExtension: "jpg"),
              let image = CIImage(contentsOf: url) else {
            return
        }
        
        fp100PlateLarge = image
        
        let scale = 3000 / image.extent.width
        let smallPlate = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let smallPlateCached = smallPlate.convertToCGImageAndCache()
        fp100PlateSmall = smallPlateCached
    }
    
    
    
    private func cacheGrainTiles(plateUrl: URL) -> CIImage? {
        guard let imageSource = CGImageSourceCreateWithURL(plateUrl as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("Failed to load CGImage from \(plateUrl).")
            return nil
        }
        
        return CIImage(cgImage: cgImage)
    }
    
    private func scaleAndCacheGrainPlates(plateUrl: URL, screenSize: NSSize) -> CIImage? {
        let screenLongEdge: CGFloat = max(screenSize.width, screenSize.height)
        
        // Load CGImage directly
        guard let imageSource = CGImageSourceCreateWithURL(plateUrl as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("Failed to load CGImage from \(plateUrl).")
            return nil
        }
        
        let grainWidth = CGFloat(cgImage.width)
        let scaleToScreenVal = screenLongEdge / grainWidth
        
        let finalCGImage: CGImage
        
        if scaleToScreenVal > 1.0 {
            print("Grain plate smaller than screen size, returning tiled plate")
            
            // Call the tiling function and return the result directly
            let tiled = tileGrainPlates(input: cgImage, screenSize: screenSize)
            print("Succesfully cached \(plateUrl)")
            return tiled
        } else {
            guard let scaled = scaledCGImage(from: cgImage, scale: scaleToScreenVal) else {
                print("Failed to scale CGImage from \(plateUrl).")
                return nil
            }
            finalCGImage = scaled
        }
        
        print("Succesfully cached \(plateUrl)")
        
        return CIImage(cgImage: finalCGImage)
    }
    
    
    func convertToCIImage(_ plateUrl: URL) -> CIImage? {
        // Load CGImage directly
        guard let imageSource = CGImageSourceCreateWithURL(plateUrl as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("Failed to load CGImage from \(plateUrl).")
            return nil
        }
        return CIImage(cgImage: cgImage)
    }
    
    
    // MARK: - Tile smaller grain plates
    
    func tileGrainPlates(input: CGImage, screenSize: NSSize) -> CIImage {
        let screenWidth: CGFloat = max(screenSize.width, screenSize.height)
        var grain = CIImage(cgImage: input)
        grain = grain.cropped(to: CGRect(
            x: 0,
            y: 0,
            width: min(grain.extent.width, grain.extent.height),
            height:  min(grain.extent.width, grain.extent.height)
        ))
        
        // Create the mask, with edges blurred
        // No need to scale blur, as all granules are the same size across plates
        let foregroundMask = CIImage(color: .white).cropped(to: grain.extent)
        let backgroundMask = CIImage(color: .black).cropped(to: grain.extent)
        let blurVal: CGFloat = 10.0
        let foregroundMaskBlurred = foregroundMask.gaussianBlur(blurVal)
        let mask = foregroundMaskBlurred.composited(over: backgroundMask).cropped(to: backgroundMask.extent)
        
        
        
        // Create a blank image for the new grains to tile into
        var newGrain = CIImage(color: .gray).cropped(to: CGRect(
            x: 0,
            y: 0,
            width: screenWidth,
            height: screenWidth
        ))
        
        let clear = CIImage(color: .clear).cropped(to: backgroundMask.extent)
        let maskedGrain = clear.blendWithMask(mask, grain)
        let xShift = backgroundMask.extent.width
        let yShift = backgroundMask.extent.height
        let finalCrop = newGrain.extent
        let tileAmountX = Int(ceil(newGrain.extent.width / grain.extent.width))
        let tileAmountY = Int(ceil(newGrain.extent.height / grain.extent.width))
        
        // Fill the new image.
        for row in 0..<tileAmountY {
            let yOffset = CGFloat(row) * yShift
            
            for col in 0..<tileAmountX {
                let xOffset = CGFloat(col) * xShift
                
                let transform = CGAffineTransform(translationX: xOffset, y: yOffset)
                let shiftedGrain = maskedGrain.transformed(by: transform)
                
                newGrain = shiftedGrain.composited(over: newGrain)
            }
        }
        
        newGrain = newGrain.cropped(to: finalCrop)
        
        return newGrain
    }
    
    func scaleFullSizeGrainPlates(_ nativeWidth: Int, _ nativeHeight: Int) {
        let longEdge: CGFloat = CGFloat(max(nativeWidth, nativeHeight))
        let size = NSSize(width: longEdge, height: longEdge)
        
        let urls = grainPlates.allURLs
        DispatchQueue.global(qos: .background).async {
            for url in urls {
                guard let fullsizeImage = self.scaleAndCacheGrainPlates(plateUrl: url, screenSize: size) else { continue }
                
                switch url.lastPathComponent {
                case "GrainHigh_Large_cropMediumSensorWidth.tiff":
                    self.grainPlates.fullsize_grainHighLargeCropMediumSensorWidth = fullsizeImage
                case "GrainHigh_Large_halfFrameWidth.tiff":
                    self.grainPlates.fullsize_grainHighLargeHalfFrameWidth = fullsizeImage
                case "GrainHigh_Large_mediumFormatWidth.tiff":
                    self.grainPlates.fullsize_grainHighLargeMediumFormatWidth = fullsizeImage
                case "GrainHigh_Large_motion8mm.tiff":
                    self.grainPlates.fullsize_grainHighLargeMotion8mm = fullsizeImage
                case "GrainHigh_Large_motion16mm.tiff":
                    self.grainPlates.fullsize_grainHighLargeMotion16mm = fullsizeImage
                case "GrainHigh_Large_motionStandard35mm.tiff":
                    self.grainPlates.fullsize_grainHighLargeMotionStandard35mm = fullsizeImage
                case "GrainHigh_Large_motionSuper8.tiff":
                    self.grainPlates.fullsize_grainHighLargeMotionSuper8 = fullsizeImage
                case "GrainHigh_Large_motionSuper35.tiff":
                    self.grainPlates.fullsize_grainHighLargeMotionSuper35 = fullsizeImage
                case "GrainHigh_Large_thirtyFiveWidth.tiff":
                    self.grainPlates.fullsize_grainHighLargeThirtyFiveWidth = fullsizeImage
                    
                case "GrainLow_Large_cropMediumSensorWidth.tiff":
                    self.grainPlates.fullsize_grainLowLargeCropMediumSensorWidth = fullsizeImage
                case "GrainLow_Large_halfFrameWidth.tiff":
                    self.grainPlates.fullsize_grainLowLargeHalfFrameWidth = fullsizeImage
                case "GrainLow_Large_mediumFormatWidth.tiff":
                    self.grainPlates.fullsize_grainLowLargeMediumFormatWidth = fullsizeImage
                case "GrainLow_Large_motion8mm.tiff":
                    self.grainPlates.fullsize_grainLowLargeMotion8mm = fullsizeImage
                case "GrainLow_Large_motion16mm.tiff":
                    self.grainPlates.fullsize_grainLowLargeMotion16mm = fullsizeImage
                case "GrainLow_Large_motionStandard35mm.tiff":
                    self.grainPlates.fullsize_grainLowLargeMotionStandard35mm = fullsizeImage
                case "GrainLow_Large_motionSuper8.tiff":
                    self.grainPlates.fullsize_grainLowLargeMotionSuper8 = fullsizeImage
                case "GrainLow_Large_motionSuper35.tiff":
                    self.grainPlates.fullsize_grainLowLargeMotionSuper35 = fullsizeImage
                case "GrainLow_Large_thirtyFiveWidth.tiff":
                    self.grainPlates.fullsize_grainLowLargeThirtyFiveWidth = fullsizeImage
                    
                default:
                    print("Unknown grain plate filename: \(url.lastPathComponent)")
                }
                
                
            }
        }
        DispatchQueue.main.async {
            print("All full-size grain plates updated for native size: \(nativeWidth)x\(nativeHeight)")
        }
    }
    
    
    func cacheFullSizePlates() {
        
        let urls = grainPlates.allURLs
        for url in urls {
            guard let fullsizeImage = self.convertToCIImage(url) else { continue }
            
            switch url.lastPathComponent {
            case "GrainHigh_Large_cropMediumSensorWidth.tiff":
                self.grainPlates.fullsize_grainHighLargeCropMediumSensorWidth = fullsizeImage
            case "GrainHigh_Large_halfFrameWidth.tiff":
                self.grainPlates.fullsize_grainHighLargeHalfFrameWidth = fullsizeImage
            case "GrainHigh_Large_mediumFormatWidth.tiff":
                self.grainPlates.fullsize_grainHighLargeMediumFormatWidth = fullsizeImage
            case "GrainHigh_Large_motion8mm.tiff":
                self.grainPlates.fullsize_grainHighLargeMotion8mm = fullsizeImage
            case "GrainHigh_Large_motion16mm.tiff":
                self.grainPlates.fullsize_grainHighLargeMotion16mm = fullsizeImage
            case "GrainHigh_Large_motionStandard35mm.tiff":
                self.grainPlates.fullsize_grainHighLargeMotionStandard35mm = fullsizeImage
            case "GrainHigh_Large_motionSuper8.tiff":
                self.grainPlates.fullsize_grainHighLargeMotionSuper8 = fullsizeImage
            case "GrainHigh_Large_motionSuper35.tiff":
                self.grainPlates.fullsize_grainHighLargeMotionSuper35 = fullsizeImage
            case "GrainHigh_Large_thirtyFiveWidth.tiff":
                self.grainPlates.fullsize_grainHighLargeThirtyFiveWidth = fullsizeImage
                
            case "GrainLow_Large_cropMediumSensorWidth.tiff":
                self.grainPlates.fullsize_grainLowLargeCropMediumSensorWidth = fullsizeImage
            case "GrainLow_Large_halfFrameWidth.tiff":
                self.grainPlates.fullsize_grainLowLargeHalfFrameWidth = fullsizeImage
            case "GrainLow_Large_mediumFormatWidth.tiff":
                self.grainPlates.fullsize_grainLowLargeMediumFormatWidth = fullsizeImage
            case "GrainLow_Large_motion8mm.tiff":
                self.grainPlates.fullsize_grainLowLargeMotion8mm = fullsizeImage
            case "GrainLow_Large_motion16mm.tiff":
                self.grainPlates.fullsize_grainLowLargeMotion16mm = fullsizeImage
            case "GrainLow_Large_motionStandard35mm.tiff":
                self.grainPlates.fullsize_grainLowLargeMotionStandard35mm = fullsizeImage
            case "GrainLow_Large_motionSuper8.tiff":
                self.grainPlates.fullsize_grainLowLargeMotionSuper8 = fullsizeImage
            case "GrainLow_Large_motionSuper35.tiff":
                self.grainPlates.fullsize_grainLowLargeMotionSuper35 = fullsizeImage
            case "GrainLow_Large_thirtyFiveWidth.tiff":
                self.grainPlates.fullsize_grainLowLargeThirtyFiveWidth = fullsizeImage
                
            default:
                print("Unknown grain plate filename: \(url.lastPathComponent)")
            }
            
            
        }
    }
    
    
    
    
    
    // MARK: - Scale Input Tiffs
    
    func scaledCGImage(from image: CGImage, scale: CGFloat) -> CGImage? {
        let newWidth = Int(CGFloat(image.width) * scale)
        let newHeight = Int(CGFloat(image.height) * scale)
        
        let colorSpace = image.colorSpace ?? CGColorSpace(name: CGColorSpace.adobeRGB1998)!
        
        guard let context = CGContext(
            data: nil,
            width: newWidth,
            height: newHeight,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: image.bitmapInfo.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        
        return context.makeImage()
    }
    
    
    
    func tilePlates(_ scale: CGFloat, _ tile: CIImage, _ imgToTile: CIImage) -> CIImage {
        let nativeTileFeather: CGFloat = 45.0
        let nativeTileSize: CGFloat = 1024.0
        
        let scaledTile = tile.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let scaledTileSize = nativeTileSize * scale
        let scaledTileFeather = nativeTileFeather * scale
        
        
        
        let rectToTile = imgToTile.extent
        
        let xyShift = scaledTileSize - scaledTileFeather
        let tileAmountX = Int(ceil(rectToTile.width / xyShift))
        let tileAmountY = Int(ceil(rectToTile.height / xyShift))
        
        print("""
            
            Grain Tiling Debug:
            
            Tile Scale = \(scale)
            Scaled Tile Size = \(scaledTile)
            
            XY Shift = \(xyShift)
            
            Total Tiles X = \(tileAmountX)
            Total Tiles Y = \(tileAmountY)
            
            """)
        
        
        var newGrain = CIImage(color: .gray).cropped(to: rectToTile)
        
        
        
        for row in 0..<tileAmountY {
            let yOffset = CGFloat(row) * xyShift
            print("""
                Y offset = \(yOffset)
                """)
            
            for col in 0..<tileAmountX {
                let xOffset = CGFloat(col) * xyShift
                
                print("""
                    X offset = \(xOffset)
                    """)
                
                let transform = CGAffineTransform(translationX: xOffset, y: yOffset)
                let shiftedGrain = tile.transformed(by: transform)
                
                newGrain = shiftedGrain.composited(over: newGrain)
            }
        }
        
        let grainCropped = newGrain.cropped(to: imgToTile.extent)
        
//        debugSave(grainCropped, "GrainTiled")
        
        return newGrain.cropped(to: imgToTile.extent)
    }
    
    
    // MARK: - Film Size Scaling Logic
    
    // ********** Scale Variables ********** //
    
    private var lastFormatChoice: Int = 999
    private var lastExportChoice: Int = 999
    
    // ********** Main function ********** //
    
    func loadUIPlates (_ item: ImageItem, _ dataModel: DataModel)  {
        print("Begining to load grain")
        
        
        guard let img = item.debayeredInit else {
            print("No debayeredInit, skipping grain generation")
            return
        }
        
        
        Task(priority: .utility) {
            
            await withTaskGroup(of: Void.self) { group in
                
                // 5x4, Medium Format, Crop Sensor
                group.addTask {
                    let (grainLow54, grainHigh54) = await self.scaleFor54(img)
                    let (plateL54, plateH54) = await self.tileAndRotateFromPlate(img, grainLow54, grainHigh54)
                    

                    await MainActor.run {
                        dataModel.updateItem(id: item.id) { item in
                            item.grain54_low = plateL54
                            item.grain54_high = plateH54
                        }
                    }
                    
                }
                
                group.addTask {
                    let (grainLow60mm, grainHigh60mm) = await self.scaleForMediumFormat(img)
                    let (plateL60, plateH60) = await self.tileAndRotateFromPlate(img, grainLow60mm, grainHigh60mm)
                    
                    
                    await MainActor.run {
                        dataModel.updateItem(id: item.id) { item in
                            item.grain60mm_low = plateL60
                            item.grain60mm_high = plateH60
                        }
                        
                    }
                }
                
                group.addTask {
                    let (grainLow53mm, grainHigh53mm) = await self.scaleForCropMediumFormat(img)
                    let (plateL53, plateH53) = await self.tileAndRotateFromPlate(img, grainLow53mm, grainHigh53mm)
                    
                    
                    await MainActor.run {
                        dataModel.updateItem(id: item.id) { item in
                            item.grain53mm_low = plateL53
                            item.grain53mm_high = plateH53
                        }
                    }
                }
                
                
                // 36
                group.addTask {
                    let (grainLow36mm, grainHigh36mm) = await self.scaleFor36mm(img)
                    let (plateL36, plateH36) = await self.tileAndRotateFromPlate(img, grainLow36mm, grainHigh36mm)
                    
                    
                    await MainActor.run {
                        dataModel.updateItem(id: item.id) { item in
                            item.grain36mm_low = plateL36
                            item.grain36mm_high = plateH36
                        }
                        
//                        debugSave(plateL36, "35mmLow")
                    }
                }
                
                // 25mm (Motion Super35)
                 group.addTask {
                     let (grainLow25mm, grainHigh25mm) = await self.scaleFor25mm(img)
                     let (plateL25, plateH25) = await self.tileAndRotateFromPlate(img, grainLow25mm, grainHigh25mm)
                     
                     await MainActor.run {
                         dataModel.updateItem(id: item.id) { item in
                             item.grain25mm_low = plateL25
                             item.grain25mm_high = plateH25
                         }
                     }
                 }
                 
                 // 21mm (Motion Standard 35mm)
                 group.addTask {
                     let (grainLow21mm, grainHigh21mm) = await self.scaleFor21mm(img)
                     let (plateL21, plateH21) = await self.tileAndRotateFromPlate(img, grainLow21mm, grainHigh21mm)
                     
                     await MainActor.run {
                         dataModel.updateItem(id: item.id) { item in
                             item.grain21mm_low = plateL21
                             item.grain21mm_high = plateH21
                         }
                     }
                 }
                 
                 // 18mm (Half Frame)
                 group.addTask {
                     let (grainLow18mm, grainHigh18mm) = await self.scaleFor18mm(img)
                     let (plateL18, plateH18) = await self.tileAndRotateFromPlate(img, grainLow18mm, grainHigh18mm)
                     
                     await MainActor.run {
                         dataModel.updateItem(id: item.id) { item in
                             item.grain18mm_low = plateL18
                             item.grain18mm_high = plateH18
                         }
                     }
                 }
                 
                 // 10mm (Motion 16mm)
                 group.addTask {
                     let (grainLow10mm, grainHigh10mm) = await self.scaleFor10mm(img)
                     let (plateL10, plateH10) = await self.tileAndRotateFromPlate(img, grainLow10mm, grainHigh10mm)
                     
                     await MainActor.run {
                         dataModel.updateItem(id: item.id) { item in
                             item.grain10mm_low = plateL10
                             item.grain10mm_high = plateH10
                         }
                     }
                 }
                
                
                // 5mm (Motion 8mm – 4.8mm)
                group.addTask {
                    let (grainLow5mm, grainHigh5mm) = await self.scaleFor8mm(img)
                    let (plateL5, plateH5) = await self.tileAndRotateFromPlate(img, grainLow5mm, grainHigh5mm)
                    
                    await MainActor.run {
                        dataModel.updateItem(id: item.id) { item in
                            item.grain5mm_low = plateL5
                            item.grain5mm_high = plateH5
                        }
                    }
                }

                // 6mm (Motion Super8 – 5.79mm)
                group.addTask {
                    let (grainLow6mm, grainHigh6mm) = await self.scaleFor5mm(img)
                    let (plateL6, plateH6) = await self.tileAndRotateFromPlate(img, grainLow6mm, grainHigh6mm)
                    
                    await MainActor.run {
                        dataModel.updateItem(id: item.id) { item in
                            item.grain6mm_low = plateL6
                            item.grain6mm_high = plateH6
                        }
                    }
                }

                
            } // End of concurrent
            await MainActor.run {
                dataModel.updateItem(id: item.id) { item in
                    item.grainPlatesLoaded = true
                }
            }
            
        } // End of task
    }
    
    
    // ************* Full Size Plate ******************** //
    
    func loadFullSizePlate(_ img: CIImage, _ choice: Int) async -> (CIImage, CIImage) {
        switch choice {
        case 9: // Large format 5x4 (127mm)
            let (grainLow54, grainHigh54) = await self.scaleFor54(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow54, grainHigh54)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        case 0: // Medium format (60mm)
            let (grainLow60, grainHigh60) = await self.scaleForMediumFormat(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow60, grainHigh60)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        case 1: // Crop medium format (43.8mm)
            let (grainLow53, grainHigh53) = await self.scaleForCropMediumFormat(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow53, grainHigh53)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        case 2: // Standard 35mm (36mm width)
            let (grainLow36, grainHigh36) = await self.scaleFor36mm(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow36, grainHigh36)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        case 5: // Motion Super35 (24.89mm)
            let (grainLow25, grainHigh25) = await self.scaleFor25mm(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow25, grainHigh25)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        case 4: // Motion Standard 35mm (21.95mm)
            let (grainLow21, grainHigh21) = await self.scaleFor21mm(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow21, grainHigh21)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        case 3: // Half Frame (18mm)
            let (grainLow18, grainHigh18) = await self.scaleFor18mm(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow18, grainHigh18)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        case 6: // Motion 16mm (10.26mm)
            let (grainLow10, grainHigh10) = await self.scaleFor10mm(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow10, grainHigh10)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        case 7: // Motion 8mm (4.8mm)
            let (grainLow5, grainHigh5) = await self.scaleFor8mm(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow5, grainHigh5)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        case 8: // Motion Super8 (5.79mm)
            let (grainLow6, grainHigh6) = await self.scaleFor5mm(img)
            let (plateL, plateH) = await self.tileAndRotateFromPlate(img, grainLow6, grainHigh6)
            
            print("HighRes Plates Complete")
            return (plateL, plateH)

        default:
            return (.clear, .clear)
        }
    }
        
    
    
    

    // ******************************************************************** //
    // Helpers to scale the format will accept input image and return plate //
    // ******************************************************************** //
    
    
    // ********** 5x4 ********** //
    
    func scaleFor54(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        let referenceLongEdge: CGFloat = 9194.0  // 5×4 reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 127.0 // 127mm (5 inches)

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 127.0  // 127mm (5 inches)

        let grainScalar = inputPixelsPerMM / referencePixelsPerMM

        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "Grain54Shadow_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)  // false = shadow plate
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled)
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "Grain54Highlight_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)  // true = highlight plate
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled)
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }

    // ********** MediumFormat (60mm) ********** //
    
    // We can get away with scaling up the plates by 2x
    func scaleForMediumFormat(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        
        let referenceLongEdge: CGFloat = 9194.0  // 5×4 reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 127.0 // 127mm (5 inches)

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 127.0  // 127mm (5 inches)


        let grainScalar = (inputPixelsPerMM / referencePixelsPerMM) * (127.0 / 60.0)

        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "Grain54Shadow_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)  // false = shadow plate
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled)
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "Grain54Highlight_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)  // true = highlight plate
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled)
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }
    
    // ********* Crop Medium Format ********** //
    
    func scaleForCropMediumFormat(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        
        
        let referenceLongEdge: CGFloat = 9194.0  // 5×4 reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 127.0 // 127mm (5 inches)

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 127.0  // 127mm (5 inches)


        let grainScalar = (inputPixelsPerMM / referencePixelsPerMM) * (127.0 / 53.0)

        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "Grain54Shadow_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)  // false = shadow plate
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled)
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "Grain54Highlight_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)  // true = highlight plate
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled)
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }
    
    
    
    
    // ********* 35mm ********** //
    
    func scaleFor36mm(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        let referenceLongEdge: CGFloat = 17512.0  // 36mm reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 36.0

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 36.0

        let grainScalar = inputPixelsPerMM / referencePixelsPerMM

        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Shadow_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled) // false = shadow
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Highlight_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled) // true = highlight
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }

    
    // ********* 25mm ********** //
    
    
    func scaleFor25mm(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        let referenceLongEdge: CGFloat = 17512.0  // 36mm reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 36.0 // 36mm

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 36.0

        // Scale to 25mm using 35mm plates as reference
        let grainScalar = (inputPixelsPerMM / referencePixelsPerMM) * (36.0 / 25.0)

        print("25mm Scalar = \(grainScalar)")

        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Shadow_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)  // false = shadow
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled)
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Highlight_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)  // true = highlight
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled)
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }
    
    // ********* 21mm ********** //
    
    
    func scaleFor21mm(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        let referenceLongEdge: CGFloat = 17512.0  // 36mm reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 36.0

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 36.0

        // Scale to 21mm using 35mm plates as reference
        let grainScalar = (inputPixelsPerMM / referencePixelsPerMM) * (36.0 / 21.0)
        print("21mm Scalar = \(grainScalar)")

        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Shadow_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)  // false = shadow
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled)
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Highlight_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)  // true = highlight
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled)
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }
    
    // ********* 18mm ********** //
    
    func scaleFor18mm(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        let referenceLongEdge: CGFloat = 17512.0  // 36mm reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 36.0

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 36.0

        // Scale to 18mm using 35mm plates as reference
        let grainScalar = (inputPixelsPerMM / referencePixelsPerMM) * (36.0 / 18.0)
        print("18mm Scalar = \(grainScalar)")

        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Shadow_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)  // false = shadow
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled)
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Highlight_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)  // true = highlight
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled)
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }
    
    // ********* 10mm ********** //
    
    func scaleFor10mm(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        let referenceLongEdge: CGFloat = 17512.0  // 36mm reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 36.0 // 36mm

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 36.0  // 127mm (5 inches)
        

        let grainScalar = (inputPixelsPerMM / referencePixelsPerMM) * (36.0 / 10.0)
        
        print("10mm Scalar = \(grainScalar)")
        
        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Shadow_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)  // false = shadow
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled)
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Highlight_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)  // true = highlight
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled)
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }
    
    
    
    // ******* 8mm ******* //

    
    func scaleFor8mm(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        let referenceLongEdge: CGFloat = 17512.0  // 36mm reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 36.0 // 36mm

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 36.0  // 127mm (5 inches)
        

        let grainScalar = (inputPixelsPerMM / referencePixelsPerMM) * (36.0 / 4.8)
        
        print("8mm Scalar = \(grainScalar)")
        
        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Shadow_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)  // false = shadow
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled)
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Highlight_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)  // true = highlight
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled)
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }
    
    
    // *********** Super8 ********** //
    
    func scaleFor5mm(_ inputImage: CIImage) async -> (CIImage, CIImage) {
        let referenceLongEdge: CGFloat = 17512.0  // 36mm reference long edge (px)
        let referencePixelsPerMM: CGFloat = referenceLongEdge / 36.0 // 36mm

        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
        let inputPixelsPerMM = inputLongEdge / 36.0  // 127mm (5 inches)
        

        let grainScalar = (inputPixelsPerMM / referencePixelsPerMM) * (36.0 / 5.79)
        
        print("5.79mm Scalar = \(grainScalar)")
        
        var grainLow: CIImage = .clear
        var grainHigh: CIImage = .clear

        await withTaskGroup(of: (Bool, CIImage?).self) { group in
            // Shadow plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Shadow_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (false, nil)  // false = shadow
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (false, scaled)
            }

            // Highlight plate
            group.addTask {
                guard let url = Bundle.main.url(forResource: "35mm_Highlight_4x_v3", withExtension: "png"),
                      let image = CIImage(contentsOf: url) else {
                    return (true, nil)  // true = highlight
                }
                let grainEven = image.evenOutTileExposure()
                let scaled = grainEven.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
                return (true, scaled)
            }

            for await (isHighlight, image) in group {
                if let img = image {
                    if isHighlight {
                        grainHigh = img
                    } else {
                        grainLow = img
                    }
                }
            }
        }

        return (grainLow, grainHigh)
    }
    
    
    

    
    // MARK: - Tiling
    
    
    // ********** Tile Variables ********** //

    
    @Published var Grain54Highlight_v3: CIImage?
    @Published var Grain54Shadow_v3: CIImage?

    
    @Published var tileCachedLow: CIImage?
    @Published var tileCachedHigh: CIImage?
    
    
    
    @Published var Grain54Shadow_v3_large: CIImage?
    @Published var Grain54Highlight_v3_large: CIImage?
    
    
    
    private var lastPlateExtentUI: CGRect = .zero
    private var lastPlateExtentLarge: CGRect = .zero


    // ******** Tile From Plate Init ******** //
  
    func tileAndRotateFromPlate(_ inputImage: CIImage, _ low: CIImage, _ high: CIImage) async -> (CIImage, CIImage) {
        await withTaskGroup(of: (CIImage, Bool).self) { group -> (CIImage, CIImage) in

            
            // Start both tiling operations concurrently
            group.addTask {
                let result = await inputImage.tileAndRotateFull(low)
                return (result, true) // mark as "low"
            }
            
            group.addTask {
                let result = await inputImage.tileAndRotateFull(high)
                return (result, false) // mark as "high"
            }
            
            var grainLow: CIImage = .clear
            var grainHigh: CIImage = .clear
            
            for await (result, isLow) in group {
                if isLow {
                    grainLow = result
                } else {
                    grainHigh = result
                }
            }
            
            return (grainLow, grainHigh)
        }
    }
    


    
    
    // ********** Tile High Res ********** //
    
//    
//    func tileAndRotateLarge(_ inputImage: CIImage) {
//        
//        DispatchQueue.main.async {
//            
//            if self.lastPlateExtentLarge == self.Grain54Shadow_v3_large?.extent || self.lastPlateExtentLarge == self.Grain54Highlight_v3_large?.extent {
//                return
//            }
//            
//            
//            self.Grain54Shadow_v3_large = nil
//            self.Grain54Highlight_v3_large = nil
//        }
//
//        let referenceLongEdge: CGFloat = 9194.0  // 5×4 reference long edge (px)
//        let referencePixelsPerMM: CGFloat = referenceLongEdge / 127.0 // 127mm (5 inches)
//        
//        let inputLongEdge = max(inputImage.extent.width, inputImage.extent.height)
//        let inputPixelsPerMM = inputLongEdge / 127.0  // 127mm (5 inches)
//        
//        let grainScalar = inputPixelsPerMM / referencePixelsPerMM
//        
//        var grainLow = CIImage.clear
//        var grainHigh = CIImage.clear
//        
//        let group = DispatchGroup()
//        let queue = DispatchQueue.global(qos: .utility)
//
//
//        group.enter()
//        queue.async {
//            
//            guard let grainShadowImage = self.tileCachedLow else {
//                return
//            }
//
//            
//            let lowTile = grainShadowImage.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
//            
//            grainLow = inputImage.tileAndRotateFull(lowTile)
//            
//            group.leave()
//        }
//        
//        
//        group.enter()
//        queue.async {
//            
//            guard let grainHighlightImage = self.tileCachedHigh else {
//                return
//            }
//            
//            let highTile = grainHighlightImage.transformed(by: CGAffineTransform(scaleX: grainScalar, y: grainScalar))
//            
//            grainHigh = inputImage.tileAndRotateFull(highTile)
//            
//            group.leave()
//        }
//        
//        group.wait()
//        
//        let lowCached = grainLow.convertToCGImageAndCache()
//        let highCached = grainHigh.convertToCGImageAndCache()
//        
//        DispatchQueue.main.async {
//            self.Grain54Shadow_v3_large = lowCached
//            self.Grain54Highlight_v3_large = highCached
//            
//            self.lastPlateExtentLarge = grainLow.extent
//            
//            self.lastExportChoice = 9
//            
//            print("Large grain plates updated")
//        }
//        
//        DispatchQueue.global(qos: .utility).async {
//            debugSave(grainLow, "TestFull")
//        }
//    }
    

}
