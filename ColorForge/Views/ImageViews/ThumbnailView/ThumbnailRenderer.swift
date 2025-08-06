//
//  ThumbnailRenderer.swift
//  ColorForge
//
//  Created by admin on 17/07/2025.
//

import Metal
import MetalKit
import CoreImage


final class ThumbnailRenderer: NSObject, MTKViewDelegate, ObservableObject {
    public let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let cicontext: CIContext
    
    let viewModel = ImageViewModel.shared
    let thumbModel = ThumbnailViewModel.shared
    
    var images: [CIImage]?

    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    var padding: CGFloat = 5.0

    weak var view: MTKView?

    private var oldWidth: CGFloat = 0.0
    private var oldHeight: CGFloat = 0
    
    var tileSize: CGFloat = 0.0
    var isResizing: Bool = false
    
    
    var imagesWithUUID: [(UUID, CIImage)] = []
    var updatedImagesWithUUID: [(UUID, CIImage)] = []
    
    var tileOriginsByUUID: [UUID: CGPoint] = [:]
    
    var cachedThumbnailViewImage: CIImage? = nil
    var fullCanvasSize: CGSize = .zero
    
    
    // Booleans
    var isInit: Bool = false
    
    
    /// Caching when updating images:
    ///
    /// Delay caching until adjustments have been completed since caching intermediates is expensive
    
    private var cacheDebounceWorkItem: DispatchWorkItem?

    private func cacheComposedImageDebounced(_ image: CIImage) {
        // Cancel any pending cache operations
        cacheDebounceWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.cachedThumbnailViewImage = image.insertingIntermediate(cache: true)
        }

        cacheDebounceWorkItem = workItem
        // Schedule the caching to happen after 0.25 seconds of no new edits
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }


    // MARK: - Designated initializer
     override init() {
         print("Renderer init: setting up Metal and CIContext")

         // create things locally first
         let dev       = RenderingManager.shared.device
         let cmdQueue  = dev.makeCommandQueue()!
         let ciContext = RenderingManager.shared.thumbnailContext

         // assign all stored properties
         self.device       = dev
         self.commandQueue = cmdQueue
         self.cicontext    = ciContext

         // now call super
         super.init()

         print("Renderer init: completed")
     }

    func draw(in view: MTKView) {
        _ = inFlightSemaphore.wait(timeout: .distantFuture)

        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("Renderer: Failed to create commandBuffer")
            inFlightSemaphore.signal()
            return
        }

        commandBuffer.addCompletedHandler { _ in
            self.inFlightSemaphore.signal()
        }

        guard let drawable = view.currentDrawable else {
            print("Renderer: No drawable available")
            inFlightSemaphore.signal()
            return
        }

        let canvasSize = thumbModel.canvasSize  // Always use this for tiling and scaling
        var composedImage: CIImage = CIImage.empty()

        if thumbModel.isInitialLoad || isResizing {
            // Initial tiling pass
            var tilesWithUUID: [(UUID, CIImage)] = []
            for (uuid, image) in imagesWithUUID {
                let tile = self.createTile(image, canvasSize)
                tilesWithUUID.append((uuid, tile))
            }

            self.imagesWithUUID = tilesWithUUID
            composedImage = self.createThumbnailViewImageSerial(tilesWithUUID, canvasSize)
            self.cachedThumbnailViewImage = composedImage.insertingIntermediate(cache: true)
			thumbModel.initialRenderingComplete = true
            self.isResizing = false
        } else {
            // Append new thumbnails to the cached base
            composedImage = self.appendThumbnailViewImage(updatedImagesWithUUID, canvasSize)

//            // Always render the latest composite
//            self.cachedThumbnailViewImage = composedImage

            // Debounce the GPU caching (so we don’t thrash textures every change)
            cacheComposedImageDebounced(composedImage)
        }

        // Render to the current drawable (using the view size, not the canvas size)
        let destination = CIRenderDestination(
            width: Int(view.drawableSize.width),
            height: Int(view.drawableSize.height),
            pixelFormat: view.colorPixelFormat,
            commandBuffer: commandBuffer,
            mtlTextureProvider: { drawable.texture }
        )

        do {
            try cicontext.startTask(
                toRender: composedImage,
                from: composedImage.extent,
                to: destination,
                at: .zero
            )
        } catch {
            print("Renderer: failed to start render task: \(error)")
        }



        commandBuffer.present(drawable)
        commandBuffer.addCompletedHandler { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.thumbModel.renderingComplete = true
                self.thumbModel.isInitialLoad = false
            }
        }


        commandBuffer.commit()

    }
    
    

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }

    
    func updateThumbnailsInit(_ newImages: [CIImage], _ ids: [UUID]) {
        self.thumbModel.renderingComplete = false
		thumbModel.initialRenderingComplete = false

        // Only reset cache if we are truly doing a full refresh
        if newImages.count > 1 {
            self.cachedThumbnailViewImage = nil
        }

        guard newImages.count == ids.count else {
            print("Error: newImages and ids count mismatch")
            return
        }
        self.imagesWithUUID = zip(ids, newImages).map { ($0, $1) }
        DispatchQueue.main.async {
            self.view?.setNeedsDisplay(self.view!.bounds)
        }
    }
    
    func updateThumbnails(_ newImages: [CIImage], _ newIDs: [UUID]) {
        guard newImages.count == newIDs.count else {
            print("Error: newImages and ids count mismatch")
            return
        }
        self.updatedImagesWithUUID = zip(newIDs, newImages).map { ($0, $1) }
        DispatchQueue.main.async {
            self.view?.setNeedsDisplay(self.view!.bounds)
        }
    }
    

    func requestRedraw() {
        DispatchQueue.main.async {
            self.view?.setNeedsDisplay(self.view!.bounds)
        }
    }
    
    // Perform this concurrently so all images get scaled and turned into tiles at the same time
    func createTile(_ input: CIImage, _ viewSize: CGSize) -> CIImage {
        let columns = CGFloat(thumbModel.colCount)
        let padding = thumbModel.padding
        let canvasWidth = thumbModel.canvasSize.width > 0 ? thumbModel.canvasSize.width : viewSize.width
        let tileSize = canvasWidth / columns
        self.tileSize = tileSize

        let contentSize = tileSize - (padding * 2) // The area available for the image after padding

        // Compute scale to fit image inside the content area (respecting padding)
        let scale = min(contentSize / input.extent.width,
                        contentSize / input.extent.height)

        var tile = input.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // Compute translation to center image within padded region
        let translatedX = (tileSize - tile.extent.width) / 2.0
        let translatedY = (tileSize - tile.extent.height) / 2.0

        tile = tile.transformed(by: CGAffineTransform(translationX: translatedX, y: translatedY))

        // Create background canvas with full tile size
        let tileCanvas = CIImage(color: thumbModel.backgroundColor)
            .cropped(to: CGRect(x: 0, y: 0, width: tileSize, height: tileSize))

        // Composite image over canvas
        return tile.composited(over: tileCanvas)
    }
    
    func createRow(_ tiles: [(UUID, CIImage)],
                   _ y: CGFloat,
                   _ colCount: Int,
                   _ tileSize: CGFloat,
                   _ backgroundColor: CIColor) async -> (CIImage, [(UUID, CGPoint)]) {
        let rowWidth = CGFloat(colCount) * tileSize
        let row = CIImage(color: backgroundColor)
            .cropped(to: CGRect(x: 0, y: y, width: rowWidth, height: tileSize))

        var origins: [(UUID, CGPoint)] = []

        let compositedRow = tiles.enumerated().reduce(row) { current, item in
            let (index, (uuid, tile)) = item
            let x = CGFloat(index) * tileSize
            let point = CGPoint(x: x, y: y)
            origins.append((uuid, point))  // Store for later

            let transform = CGAffineTransform(translationX: x, y: y)
            let positionedTile = tile.transformed(by: transform)
            return positionedTile.composited(over: current)
        }

        return (compositedRow, origins)
    }
    
    
    func createRowSerial(_ tiles: [(UUID, CIImage)], _ y: CGFloat, _ colCount: Int, _ tileSize: CGFloat, _ backgroundColor: CIColor) -> CIImage {
        let rowWidth = CGFloat(colCount) * tileSize
        let row = CIImage(color: backgroundColor).cropped(to: CGRect(x: 0, y: y, width: rowWidth, height: tileSize))

        var compositedRow = row
        for (index, (uuid, tile)) in tiles.enumerated() {
            let x = CGFloat(index) * tileSize
            tileOriginsByUUID[uuid] = CGPoint(x: x, y: y)

            let transform = CGAffineTransform(translationX: x, y: y)
            let positionedTile = tile.transformed(by: transform)
            compositedRow = positionedTile.composited(over: compositedRow)
        }

        return compositedRow
    }

    func createThumbnailViewImageSerial(_ tiles: [(UUID, CIImage)], _ viewSize: CGSize) -> CIImage {
        // Reset stored origins
        tileOriginsByUUID.removeAll()

        let tileSize = self.tileSize
        let colCount = Int(thumbModel.colCount)
        let rowCount = Int(ceil(Double(tiles.count) / Double(colCount)))

        let extraRowPadding: CGFloat = 40.0

        // Calculate total view height including 40px above each row
        let baseHeight = CGFloat(rowCount) * tileSize
        var viewHeight = baseHeight + (CGFloat(rowCount) * extraRowPadding)

        if viewHeight < viewSize.height {
            viewHeight = viewSize.height
        }
        let viewWidth = viewSize.width

        thumbModel.canvasSize = CGSize(width: viewWidth, height: viewHeight)
        oldWidth = viewWidth
        oldHeight = viewHeight

        // Full canvas background
        let fullCanvas = CIImage(color: thumbModel.backgroundColor)
            .cropped(to: CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight))

        // Split tiles into rows
        let tileRows: [[(UUID, CIImage)]] = stride(from: 0, to: tiles.count, by: colCount).map {
            Array(tiles[$0 ..< min($0 + colCount, tiles.count)])
        }

        var finalImage = fullCanvas

        for (rowIndex, rowTiles) in tileRows.enumerated() {
            // Y offset for this row: start from top, include padding for each row above
            let y = viewHeight
                  - (CGFloat(rowIndex + 1) * tileSize)
                  - (CGFloat(rowIndex + 1) * extraRowPadding)

            for (index, (uuid, _)) in rowTiles.enumerated() {
                let x = CGFloat(index) * tileSize
                tileOriginsByUUID[uuid] = CGPoint(x: x, y: y)
            }

            // Composite the row onto the final canvas
            let rowImage = createRowSerial(rowTiles, y, colCount, tileSize, thumbModel.backgroundColor)
            finalImage = rowImage.composited(over: finalImage)
        }

        // Save for overlays
        thumbModel.tileOriginsByUUID = tileOriginsByUUID
        thumbModel.tileSize = tileSize

        return finalImage.insertingIntermediate(cache: true)
    }
    
    
    /// This will create tiles for each image using createTile()
    ///
    /// Then find each tile's origin by searching:
    /// var tileOriginsByUUID: [UUID: CGPoint] = [:]
    ///
    /// It will then composite them over the cachedThumbnailView CIImage and return that
    ///
    func appendThumbnailViewImage(_ tiles: [(UUID, CIImage)], _ viewSize: CGSize) -> CIImage {
        // Use the cached image as the base
        guard let base = cachedThumbnailViewImage else {
            print("appendThumbnailViewImage: No cached base image available.")
            return CIImage.empty()
        }

        var composite = base

        for (uuid, image) in tiles {
            // Lookup origin
            guard let origin = tileOriginsByUUID[uuid] else {
                print("appendThumbnailViewImage: No origin found for UUID \(uuid)")
                continue
            }

            // Create tile and position it
            let tile = createTile(image, thumbModel.canvasSize)
            let transformedTile = tile.transformed(by: CGAffineTransform(translationX: origin.x, y: origin.y))

            // Composite tile over base
            composite = transformedTile.composited(over: composite)
        }
        
        // Update origins and tile size for overlays
        thumbModel.tileOriginsByUUID = tileOriginsByUUID
        thumbModel.tileSize = tileSize

        return composite
    }
    

    
    func triggerRedraw(_ newImages: [CIImage], _ ids: [UUID]) {
        

        // Only reset cache if we are truly doing a full refresh
        if newImages.count > 1 {
            self.cachedThumbnailViewImage = nil
        }

        guard newImages.count == ids.count else {
            print("Error: newImages and ids count mismatch")
            return
        }
        self.imagesWithUUID = zip(ids, newImages).map { ($0, $1) }
        DispatchQueue.main.async {
            self.view?.setNeedsDisplay(self.view!.bounds)
        }
        self.isResizing = true
    }
    
    
    func resizeCachedThumbnailImage(to newSize: CGSize) {
        guard let cached = cachedThumbnailViewImage, oldWidth > 0, oldHeight > 0 else {
            oldWidth = newSize.width
            oldHeight = newSize.height
            return
        }

        // Scale uniformly by width for both axes
        let widthScalar = newSize.width / oldWidth
        let transform = CGAffineTransform(scaleX: widthScalar, y: widthScalar)

        // Scale the cached composite image
        var scaledImage = cached.transformed(by: transform)

        // Compute new scaled height based on original image height
        let scaledHeight = oldHeight * widthScalar
        let heightDiff = newSize.height - scaledHeight

        // Build a new canvas with the final desired size (even if height shrinks)
        let newCanvas = CIImage(color: thumbModel.backgroundColor).cropped(to: CGRect(
            x: 0, y: 0,
            width: scaledImage.extent.width,
            height: newSize.height
        ))

        // Calculate how much to shift the scaled image so its *top edge* stays fixed
        // We shift it up (positive) when adding height, down (negative) when shrinking
        let vOffset = heightDiff

        scaledImage = scaledImage.transformed(by: CGAffineTransform(translationX: 0, y: vOffset))
        scaledImage = scaledImage.composited(over: newCanvas)

        thumbModel.canvasSize = newCanvas.extent.size
        cachedThumbnailViewImage = scaledImage

        // Scale and shift tile origins to match
        tileOriginsByUUID = tileOriginsByUUID.mapValues { origin in
            CGPoint(
                x: origin.x * widthScalar,
                y: (origin.y * widthScalar) + vOffset
            )
        }
        
        thumbModel.tileOriginsByUUID = tileOriginsByUUID
        thumbModel.tileSize = tileSize

        // Update stored reference size so subsequent resizes are relative to the new state
        oldWidth = newSize.width
        oldHeight = newSize.height

        isResizing = true
        DispatchQueue.main.async {
            self.view?.setNeedsDisplay(self.view!.bounds)
        }
    }
    
    


    
}
