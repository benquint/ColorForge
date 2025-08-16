//
//  SamModel.swift
//  ColorForge
//
//  Created by Ben Quinton on 07/08/2025.
//

import Foundation
import CoreImage
import AppKit
import Vision

class SamModel: ObservableObject {
    static let shared = SamModel()
    
    init() {
        
    }
    @Published var showPoints: Bool = false
    @Published var showSamMask: Bool = true
    @Published var newSamMask: Bool = false 
    @Published var addToMask: Bool = true
    @Published var subtractFromMask: Bool = false
    @Published var currentMaskCG: CGImage? = nil
    @Published var selectedMask: UUID? = nil
    
    @Published var currentMask: CIImage? = nil // To be bound to mask
    
    
    // MARK: - Add and Subtract to Mask
    
    func addMask(_ segmentation: SAMSegmentation, _ dataModel: DataModel) {
        print("Add called")
        
        
        
        var mask = CIImage(color: .black).cropped(to: segmentation.mask.extent)
        let newMask = segmentation.mask.composited(over: mask)
        
//        Task {
//         try await  detectContours(image: newMask)
//            await edgeAware(newMask)
//        }
            
        if self.currentMask == nil {
            mask = CIImage(color: .black).cropped(to: newMask.extent)
        } else if let currentMask = self.currentMask {
            mask = currentMask
        } else if self.currentMask == nil {
            print("No Current Mask")
        }
        
        mask = mask.add(newMask)
        
        let clamped = mask.applyingFilter("CIColorClamp", parameters: [
            "inputMinComponents": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputMaxComponents": CIVector(x: 1, y: 1, z: 1, w: 1)
        ])
        
        
        self.currentMask = clamped
        
        var softened = mask
        
        if let id = selectedMask {
            softened = softenMaskEdges(clamped, id, dataModel)
        }
        
        generateMaskForUI(softened)
        
        
        
        if let id = selectedMask {
            commitCurrentMask(mask: softened, to: dataModel, maskId: id)
        } else {
            print("\n\nSelected mask id is nil\n\n")
        }
    }
    
    private var debugIndex: Int = 0
    
    func subtractMask(_ segmentation: SAMSegmentation, _ dataModel: DataModel) {
        print("Subtract called")
        
        var mask = CIImage(color: .black).cropped(to: segmentation.mask.extent)
        let newMask = segmentation.mask.composited(over: mask)
        
        
        
        if self.currentMask == nil {
            mask = CIImage(color: .black).cropped(to: newMask.extent)
        } else if let currentMask = self.currentMask {
            mask = currentMask
        } else if self.currentMask == nil {
            print("No Current Mask")
        }
        
        mask = mask.subtract(newMask)
        
        let clamped = mask.applyingFilter("CIColorClamp", parameters: [
            "inputMinComponents": CIVector(x: 0, y: 0, z: 0, w: 0),
            "inputMaxComponents": CIVector(x: 1, y: 1, z: 1, w: 1)
        ])
        
        self.currentMask = clamped
        
        var softened = mask
        
        if let id = selectedMask {
            softened = softenMaskEdges(clamped, id, dataModel)
        }
        
        generateMaskForUI(softened)
        
        
        
        if let id = selectedMask {
            commitCurrentMask(mask: softened, to: dataModel, maskId: id)
        } else {
            print("\n\nSelected mask id is nil\n\n")
        }
    }
    
    // MARK: - Update bindings
    
    func updateMask( _ dataModel: DataModel) {
        guard var mask = self.currentMask else { return }
        guard let id = selectedMask else {return}
        mask = softenMaskEdges(mask, id, dataModel)
        generateMaskForUI(mask)
        commitCurrentMask(mask: mask, to: dataModel, maskId: id)
    }

    
    func commitCurrentMask(mask: CIImage, to dataModel: DataModel, maskId: UUID) {
        guard let id = ImageViewModel.shared.currentImgID else {
            print(" Failed to commit mask — missing image ID or currentMask")
            return
        }
        
        let finalMask = mask
        
        print("Committing mask to mask ID: \(maskId)")
        
        dataModel.updateItem(id: id) { item in
            if let maskIndex = item.maskSettings.aiMasks.firstIndex(where: { $0.id == maskId }) {
                item.maskSettings.aiMasks[maskIndex].maskImage = finalMask
            } else {
                print(" Mask ID not found in updateItem")
            }
        }
    }
     
    // MARK: - Create Red overlay for UI
    
    private func generateMaskForUI(_ maskImage: CIImage) {
        let canvas = CIImage(color: .clear).cropped(to: maskImage.extent)
        let red = CIImage(
            color: CIColor(
                red: 1.0, green: 0.0,
                blue: 0.0, alpha: 0.6)).cropped(to: maskImage.extent)
        
        let mask = canvas.blendWithMask(maskImage, red)
        
        
        let context = RenderingManager.shared.mainImageContext
        
        // Try to create a CGImage from the CIImage
        if let cgImage = context.createCGImage(mask, from: mask.extent) {
            currentMaskCG = cgImage
        }
    }
    
    
    
    // MARK: - Soften edges of mask
    
    // Will need to set this externally when loading previously loaded masks
    private var lastSoftenVal: Float = 5.0 // the default
    
    // MARK: - Soften edges of mask using per-mask feather value
    private func softenMaskEdges(_ mask: CIImage, _ maskId: UUID, _ dataModel: DataModel) -> CIImage {
//        debugSave(mask, "Mask")
        
        // Look up the mask's feather setting
        guard let id = ImageViewModel.shared.currentImgID else {return mask}
        guard let item = dataModel.items.first(where: { $0.id == id }) else {return mask}
        guard let maskIndex = item.maskSettings.aiMasks.firstIndex(where: { $0.id == maskId }) else {return mask}
        
        let blackCanvas = CIImage(color: .black).cropped(to: mask.extent)
        
       
        
        let featherVal = item.maskSettings.aiMasks[maskIndex].feather
        let invert = item.maskSettings.aiMasks[maskIndex].invert
        let opacity = item.maskSettings.aiMasks[maskIndex].opacity
        
        func featherMask(_ image: CIImage, _ value: CGFloat) -> CIImage {
            guard value != 0.0 else {
                var result = image
                if invert {
                    result = image.applyingFilter("CIColorInvert")
                }
                return result
            }
            
            lastSoftenVal = Float(value)
            
            // Normalisation of feather
            let targetMax = min(image.extent.width, image.extent.height) * 0.1
            let featherScaled = scaleBlurRadius(CGFloat(value))
            let featherNorm = (targetMax / 100.0) * CGFloat(featherScaled)
            
            let safeMask = image.clampedToExtent()
            
            // Expand slightly
            let maximum = CIFilter.morphologyMaximum()
            maximum.inputImage = safeMask
            maximum.radius = Float(featherNorm) / 2.0
            guard let expanded = maximum.outputImage else {return mask}
            
            let filter = CIFilter.gaussianBlur()
            filter.inputImage = expanded
            filter.radius = Float(featherNorm) // <-- use stored feather
            
            guard var result = filter.outputImage else {
                return image
            }
            
            if invert {
                result = result.applyingFilter("CIColorInvert")
            }
            
            let croppedResult = result.cropped(to: image.extent)
            let cachedResult = croppedResult.insertingIntermediate(cache: true)
            
            return cachedResult
        }
        
        var result = featherMask(mask, CGFloat(featherVal))
        

        
        result = blackCanvas.blendWithOpacityPercent(result, opacity)
        
        
        return result
    }
    
    
    func scaleBlurRadius(_ value: CGFloat) -> CGFloat {
        let t = value / 100.0               // normalize 0–1
        let gamma: CGFloat = 2.0            // >1 compresses low end
        return pow(t, gamma) * 100.0        // back to 0–100 range
    }
    
    
    
    
    // MARK: - Edge aware
    
    func edgeAware(_ mask: CIImage) async -> CIImage {
        guard let image = ImageViewModel.shared.currentImage else { return mask }
        guard let contours = try? await detectContours(image: mask) else { return mask }

        let extent = image.extent
        let (pointsNorm, distance) = await evenlySpacedPoints(contours, 50, 0.002)

        // Convert normalized points to image space
        let pointsImageSpace = pointsNorm.map { pt in
            CGPoint(x: pt.x * extent.width, y: pt.y * extent.height)
        }

        // Prepare NSImage for debug drawing
        let size = NSSize(width: extent.width, height: extent.height)
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()

        // Background black
        NSColor.black.setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

        // Draw the original contour path (not smoothed) in white
        var transform = CGAffineTransform.identity
        transform = transform.scaledBy(x: extent.width, y: extent.height)
        if let scaledPath = contours.normalizedPath.copy(using: &transform) {
            let bezier = NSBezierPath(cgPath: scaledPath)
            NSColor.white.setStroke()
            bezier.lineWidth = 1.0
            bezier.stroke()
        }

        // Draw evenly spaced points as red circles
        NSColor.red.setFill()
        for p in pointsImageSpace {
            let dotRect = NSRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)
            let dot = NSBezierPath(ovalIn: dotRect)
            dot.fill()
        }

        nsImage.unlockFocus()

        // Convert NSImage → CIImage
        var proposedRect = CGRect(origin: .zero, size: size)
        if let cgImage = nsImage.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) {
            let ciDebug = CIImage(cgImage: cgImage)
            debugSave(ciDebug, "EdgeAware_Debug")
        }

        return mask
    }
    
    private func cropToPoint(
        _ image: CIImage, _ point: CGPoint,
        _ distance: CGFloat) async -> (CIImage, CGPoint) {
            
            let size = CGSize(width: distance, height: distance)
            let origin = CGPoint(x: point.x - (distance / 2.0),
                                 y: point.y - (distance / 2.0))
            let cropRect = CGRect(origin: origin, size: size)
            let cropped = image.cropped(to: cropRect)
            
            return (cropped, origin)
        }
    
    
    
    
    
    
    
    // MARK: - Vectors
    
    
    func detectContours(image: CIImage) async throws -> ContoursObservation? {
        // Set up the detect contours request
        var request = DetectContoursRequest()
        request.contrastAdjustment = 1.5
        request.contrastPivot = nil

        // Perform the detect contours request
        let contoursObservations = try await request.perform(
            on: image
//            orientation: .downMirrored // Use for flipping origin
        )

        // Get the path
        let contours = contoursObservations.normalizedPath

        return contoursObservations
    }
    
    // MARK: - Evenly Spaced Points
    
    /// Returns up to 100 evenly spaced points along the [0,0] contour,
    /// and the spacing between them in normalized units (0–1).
    func evenlySpacedPoints(
        _ observation: ContoursObservation,
        _ spacing: CGFloat, // desired spacing in normalized units
        _ epsilon: Float = 0.002
    ) async -> (points: [CGPoint], spacing: CGFloat) {
        
        // 1. Get smoothed main contour ([0,0])
        let targetPath = IndexPath(indexes: [0, 0])
        guard let contour = observation.countourAtIndexPath(targetPath) else {
            fatalError("Contour [0,0] not found")
        }
        
        let smoothed: ContoursObservation.Contour
        do {
            smoothed = try contour.polygonApproximation(epsilon: epsilon)
        } catch {
            print("Polygon approximation failed for [0, 0]: \(error)")
            smoothed = contour
        }
        
        // 2. Convert normalizedPoints → CGPoint
        let pts = smoothed.normalizedPoints.map {
            CGPoint(x: CGFloat($0.x), y: CGFloat($0.y))
        }
        guard pts.count > 1 else {
            return (pts, 0)
        }
        
        // 3. Compute cumulative distances
        var distances: [CGFloat] = [0]
        for i in 1..<pts.count {
            let dx = pts[i].x - pts[i - 1].x
            let dy = pts[i].y - pts[i - 1].y
            distances.append(distances.last! + sqrt(dx*dx + dy*dy))
        }
        // Close loop
        let dx = pts[0].x - pts.last!.x
        let dy = pts[0].y - pts.last!.y
        distances.append(distances.last! + sqrt(dx*dx + dy*dy))
        
        let totalLength = distances.last!
        
        // 4. Determine number of points based on desired spacing
        let count = max(1, Int(round(totalLength / spacing)))
        
        // 5. Resample evenly
        var resampled: [CGPoint] = []
        var targetDist: CGFloat = 0
        var segIndex = 0
        
        for _ in 0..<count {
            while segIndex < distances.count - 1 && distances[segIndex + 1] < targetDist {
                segIndex += 1
            }
            
            let segStart = pts[segIndex % pts.count]
            let segEnd   = pts[(segIndex + 1) % pts.count]
            let segLen   = distances[segIndex + 1] - distances[segIndex]
            let t = segLen > 0 ? (targetDist - distances[segIndex]) / segLen : 0
            
            let x = segStart.x + (segEnd.x - segStart.x) * t
            let y = segStart.y + (segEnd.y - segStart.y) * t
            resampled.append(CGPoint(x: x, y: y))
            
            targetDist += spacing
        }
        
        return (resampled, spacing)
    }
    
    // MARK: - Get mask bounding box
    
    
    func unifiedBoundingBox(from observation: ContoursObservation, extent: CGRect) async -> CGRect {
        
        func isFrameContour(_ contour: ContoursObservation.Contour) -> Bool {
            let bb = contour.normalizedPath.boundingBoxOfPath
            let eps: CGFloat = 1e-4
            let isOrigin = abs(bb.minX - 0) < eps && abs(bb.minY - 0) < eps
            let isSize   = abs(bb.width - 1) < eps && abs(bb.height - 1) < eps
            if isOrigin && isSize { return true }
            
            let area = contour.calculateArea(useOrientedArea: false)
            if area > 0.98 { return true }
            
            return false
        }
        
        func bbox(for contour: ContoursObservation.Contour) -> CGRect {
            let pts = contour.normalizedPoints
            guard !pts.isEmpty else { return .null }
            
            var minX = Float.greatestFiniteMagnitude
            var minY = Float.greatestFiniteMagnitude
            var maxX = -Float.greatestFiniteMagnitude
            var maxY = -Float.greatestFiniteMagnitude
            
            for p in pts {
                minX = min(minX, p.x)
                minY = min(minY, p.y)
                maxX = max(maxX, p.x)
                maxY = max(maxY, p.y)
            }
            
            let x = CGFloat(minX) * extent.width  + extent.origin.x
            let y = CGFloat(minY) * extent.height + extent.origin.y
            let w = CGFloat(maxX - minX) * extent.width
            let h = CGFloat(maxY - minY) * extent.height
            return CGRect(x: x, y: y, width: w, height: h)
        }
        
        func collectBoxes(_ contour: ContoursObservation.Contour, into out: inout [CGRect]) {
            if !isFrameContour(contour) {
                out.append(bbox(for: contour))
            }
            for child in contour.childContours {
                collectBoxes(child, into: &out)
            }
        }
        
        // If you ever need parallel processing:
        // This could be turned into a TaskGroup to process top-level contours concurrently.
        
        return await withTaskGroup(of: CGRect.self) { group in
            for top in observation.topLevelContours {
                group.addTask {
                    var boxes: [CGRect] = []
                    collectBoxes(top, into: &boxes)
                    return boxes.reduce(CGRect.null) { $0.union($1) }
                }
            }
            
            var unified = CGRect.null
            for await box in group {
                unified = unified.union(box)
            }
            return unified
        }
    }

    
    // 1) Helper to decide if this contour is the image border
    func isFrameContour(_ contour: ContoursObservation.Contour) -> Bool {
        // Work purely in normalized space so we’re resolution-agnostic.
        let path = contour.normalizedPath
        let bb = path.boundingBoxOfPath // normalized
        // Allow for tiny numerical slop
        let eps: CGFloat = 1e-4
        let isOrigin = abs(bb.minX - 0) < eps && abs(bb.minY - 0) < eps
        let isSize   = abs(bb.width - 1) < eps && abs(bb.height - 1) < eps
        if isOrigin && isSize { return true }

        // Extra safety: if the contour’s area covers ~the whole image in normalized units.
        // (calculateArea returns in normalized units since points are normalized)
        let area = contour.calculateArea(useOrientedArea: false)
        if area > 0.98 { return true } // conservative; tweak if needed

        return false
    }
    
}
