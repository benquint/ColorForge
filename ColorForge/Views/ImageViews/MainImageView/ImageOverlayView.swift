//
//  ImageOverlayView.swift
//  ColorForge
//
//  Created by admin on 03/07/2025.
//

/// Here we will handle dragging gestures such as for gradients etc


// We should display the preview Image until 0.3 seconds after render task submitted

import SwiftUI
import AppKit


struct ImageOverlayView: View {
    @EnvironmentObject var pipeline: FilterPipeline
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var viewModel: ImageViewModel
    
    
    
    let viewWidth: CGFloat
    let viewHeight: CGFloat
    
    @Binding var selectedMask: UUID?
    @Binding var LinearStartPointBinding: CGPoint
    @Binding var LinearEndPointBinding: CGPoint
    
    
    // NEW VARS
    @State var imgSizeUI: CGSize = .zero
    @State var imgOrignUI: CGPoint = .zero
    @State var currentImgSize: CGSize = .zero
    
    
    @State var linearStartUI: CGPoint = .zero
    @State var linearEndUI: CGPoint = .zero
    
    
    
    
    // Radial mask bindings
    @Binding var radialStartPointBinding: CGPoint
    @Binding var radialEndPointBinding: CGPoint
    @Binding var radialFeatherBinding: Float
    @Binding var radialWidthBinding: CGFloat
    @Binding var radialHeightBinding: CGFloat
    @Binding var radialRotationBinding: Float
    @Binding var radialInvertBinding: Bool
    @Binding var radialOpacityBinding: Float
    
    @State private var currentOffset: CGSize = .zero
    @State private var lastDragOffset: CGSize = .zero
    
    @State private var imageSize: CGSize = .zero
    
    @State private var imageOrigin: CGPoint = .zero
    
    
    @State private var uiImageWidth: CGFloat = 0
    @State private var uiImageHeight: CGFloat = 0
    
    @State private var imageLoaded: Bool = false
    
    // CGPoints used for calculating change in position for linear masks
    @State private var initialCircleStart: CGPoint = .zero
    @State private var initialCircleEnd: CGPoint = .zero

    
    // CGPoints used for calculating change in position for radial masks
    @State private var initialRadialStart: CGPoint = .zero
    @State private var initialRadialEnd: CGPoint = .zero
    
    
    
    // MARK: - Body Start
    
    
    var body: some View {
        

            
            
            ZStack {
                
                // MARK: - Image
                
                let backingScale = NSScreen.main?.backingScaleFactor ?? 1.0
                
                if let image = viewModel.currentPreview {
                
                    if !viewModel.rendererInitialisedInUI {
                        
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(viewModel.renderingComplete ? 0 : 1)
                            .frame(width: viewModel.computedSizeForUI.width, height: viewModel.computedSizeForUI.height)
                            .onAppear{
                                viewModel.rendererInitialisedInUI = true
                            }
                            .onChange(of: image.size) {
                                
                            }
                    }
                    
                    
                    // MARK: - Linear Gradient
                    
                    if viewModel.showMaskPoints  && viewModel.maskingActive && viewModel.selectedMask == selectedMask && selectedMask != nil {
                        
                        
                        
                        ZStack {
                            
                            if viewModel.showMask {
                                
                                LinearGradientView(
                                    size: $imgSizeUI,
                                    viewWidth: viewWidth,
                                    viewHeight: viewHeight,
                                    origin: $imgOrignUI
                                )
                                .mask {
                                    Rectangle()
                                        .frame(width: viewModel.computedSizeForUI.width, height: viewModel.computedSizeForUI.height)
                                    
                                }
                            }
                            
                            if viewModel.maskingActive {
                                
                                Path { path in
                                    path.move(to: linearAdjustedLine(0))
                                    path.addLine(to: linearAdjustedLine(1))
                                }
                                .stroke(Color("SideBarText"), lineWidth: 1.5)
                                
                                
                                
                                // Start
                                Circle()
                                    .stroke(Color("SideBarText"), lineWidth: 3)
                                    .fill(Color.clear)
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                                    .position(viewModel.uiStartPoint)
                                    .gesture(
                                        DragGesture()
                                            .onChanged { gesture in
                                                
                                                viewModel.uiStartPoint = CGPoint(
                                                    x: initialCircleStart.x + gesture.translation.width,
                                                    y: initialCircleStart.y + gesture.translation.height
                                                )
                                                
                                                updateLinearMask()
                                            }
                                            .onEnded { _ in
                                                initialCircleStart = viewModel.uiStartPoint
                                                
                                                updateLinearMask()
                                            }
                                        
                                    )
                                
                                
                                // End
                                Circle()
                                    .stroke(Color("SideBarText"), lineWidth: 3)
                                    .fill(Color.clear)
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                                    .position(viewModel.uiEndPoint)
                                    .simultaneousGesture(
                                        DragGesture()
                                            .onChanged { gesture in
                                                viewModel.uiEndPoint = CGPoint(
                                                    x: initialCircleEnd.x + gesture.translation.width,
                                                    y: initialCircleEnd.y + gesture.translation.height
                                                )
                                                updateLinearMask()
                                            }
                                            .onEnded { _ in
                                                initialCircleEnd = viewModel.uiEndPoint
                                                updateLinearMask()
                                            }
                                        
                                    )
                            }
                        } // End of Linear ZStack
                        .mask(Rectangle()
                            .frame(width: viewWidth, height: viewHeight)
                        )
                    }
                    
                    
                    
                    
                    // MARK: - Radial Gradient
                    
                    
                    if viewModel.showMaskPoints  && viewModel.maskingActive && viewModel.selectedMask == selectedMask && selectedMask != nil {
                        
                        ZStack {
                            
                            if viewModel.showMask {
                                
                                RadialGradientView(
                                    start: $viewModel.radialUiStart,
                                    end: $viewModel.radialUiEnd,
                                    size: $imgSizeUI,
                                    width: $viewModel.radialUiWidth,
                                    height: $viewModel.radialUiHeight,
                                    feather: $viewModel.radialUiFeather,
                                    invert: $radialInvertBinding, viewWidth: viewWidth,
                                    viewHeight: viewHeight
                                )
                                .mask(Rectangle()
                                    .frame(width: radialInvertBinding ? imgSizeUI.width : viewWidth,
                                           height: radialInvertBinding ? imgSizeUI.height : viewHeight)
                                )
                                
                            }
                            
                            // MARK: - Ellipse Outline
                            
                            if radialInvertBinding && viewModel.showMask {
                                
                                Rectangle()
                                    .fill(Color.red.opacity(0.75))
                                    .frame(width: imgSizeUI.width, height: imgSizeUI.height)
                                    .reverseMask {
                                        ElipseView(viewWidth: viewWidth, viewHeight: viewHeight, imgSizeUI: imgSizeUI)
                                    }
                                
                                // This is correct
                                Ellipse()
                                    .stroke(Color("SideBarText"), lineWidth: 1)
                                    .frame(width: viewModel.radialUiWidth, height: viewModel.radialUiHeight)
                                    .position(viewModel.radialUiStart)
                                    .mask(Rectangle()
                                        .frame(width: viewWidth, height: viewHeight)
                                    )
                                
                                
                            } else {
                                
                                
                                Ellipse()
                                    .stroke(Color("SideBarText"), lineWidth: 1)
                                    .frame(width: viewModel.radialUiWidth, height: viewModel.radialUiHeight)
                                    .position(viewModel.radialUiStart)
                                    .mask(Rectangle()
                                        .frame(width: viewWidth, height: viewHeight)
                                    )
                                
                            }
                            
                            if !radialPointsEqual()  {
                                
                                // MARK: - Start Handle
                                Circle()
                                    .stroke(Color("MenuAccent"), lineWidth: 3)
                                    .fill(Color("SideBarText"))
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                                    .position(viewModel.radialUiStart)
                                    .mask(Rectangle()
                                        .frame(width: viewWidth, height: viewHeight)
                                    )
                                    .simultaneousGesture(
                                        moveRadialMaskGesture()
                                    )
                                
                                
                                
                                // MARK: - End Handle
                                Circle()
                                    .stroke(Color("SideBarText"), lineWidth: 3)
                                    .fill(Color("MenuAccent"))
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                                //                                .position(radialEndUI())
                                    .position(viewModel.radialUiEnd)
                                    .mask(Rectangle()
                                        .frame(width: viewWidth, height: viewHeight)
                                    )
                                    .simultaneousGesture(
                                        resizeRadialMaskGesture()
                                    )
                                
                                
                                // Rotate button
                                ZStack {
                                    Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(Color("MenuAccent"))
                                        .position(x: viewModel.radialUiStart.x,
                                                  y: (viewModel.radialUiStart.y - viewModel.radialUiHeight / 2.0) - 25)
                                    //                                    .offset(x: adjustRadialPoints(3).x + 2, y: adjustRadialPoints(3).y + 2)
                                        .opacity(0.8)
                                    
                                    Image(systemName: "arrow.trianglehead.clockwise.rotate.90")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(Color("SideBarText"))
                                        .position(x: viewModel.radialUiStart.x,
                                                  y: (viewModel.radialUiStart.y - viewModel.radialUiHeight / 2.0) - 25)
                                    //                                    .offset(x: adjustRadialPoints(3).x, y: adjustRadialPoints(3).y)
                                    
                                }
                                
                            }
                        } // End of Radial Z Stack
                    }
                    
                }
                
            }
            .frame(width: viewWidth, height: viewHeight)
            .contentShape(Rectangle())
            .simultaneousGesture(panGesture())
            .simultaneousGesture(linearMaskGesture())
            .simultaneousGesture(radialMaskGesture())
            .simultaneousGesture(zoomTap())
        
            .onAppear {
                calculateCoords()
            }
        
            // Bindings
            .onChange(of: LinearStartPointBinding) {
                
               
                
                guard viewModel.selectedMask != nil else { return }
                let point = deNormaliseCoord(LinearStartPointBinding)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let ui_point = convertCoordsToUI(point)
                    viewModel.uiStartPoint = ui_point
                    initialCircleStart = ui_point
                }
            }
            .onChange(of: LinearEndPointBinding) {
                
                
                
                guard viewModel.selectedMask != nil else { return }
                let point = deNormaliseCoord(LinearEndPointBinding)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let ui_point = convertCoordsToUI(point)
                    viewModel.uiEndPoint = ui_point
                    initialCircleEnd = ui_point
                    
                }
            }
            .onChange(of: radialStartPointBinding) {
                
                
                
                guard viewModel.selectedMask != nil else { return }
                let startPixelPoint = deNormaliseCoord(radialStartPointBinding)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let ui_start_point = convertCoordsToUI(startPixelPoint)
                    viewModel.radialUiStart = ui_start_point
                    initialRadialStart = ui_start_point
                    (viewModel.radialUiWidth, viewModel.radialUiHeight) = calculateEllipseSizeFromPoint(viewModel.radialUiStart, viewModel.radialUiEnd)
                }
            }
        
            .onChange(of: radialEndPointBinding) {

                guard viewModel.selectedMask != nil else { return }
                let endPixelPoint = deNormaliseCoord(radialEndPointBinding)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let ui_end_point = convertCoordsToUI(endPixelPoint)
                    viewModel.radialUiEnd = ui_end_point
                    initialRadialEnd = ui_end_point
                    (viewModel.radialUiWidth, viewModel.radialUiHeight) = calculateEllipseSizeFromPoint(viewModel.radialUiStart, viewModel.radialUiEnd)
                }
            }
            
        
        
    }
    
    
    // MARK: - Normalisation
    
    private func normaliseCoord(_ point: CGPoint) -> CGPoint{
        
        
        let err = CGPoint(x: 0, y: 0)
        
        guard let currentImg = viewModel.currentImage else {
            print("\nCurrent image is nil\n\n")
            return  err}
        
        let width = currentImg.extent.width, height = currentImg.extent.height
        
        let xNorm = point.x / width
        let yNorm = point.y / height
        let normCoord =  CGPoint(x: xNorm, y: yNorm)
    
        
        return normCoord
    }

    private func deNormaliseCoord(_ point: CGPoint) -> CGPoint{

        
        let err = CGPoint(x: 0, y: 0)
        guard let currentImg = viewModel.currentImage else {
            print("\nCurrent image is nil\n\n")
            return  err}
        let width = currentImg.extent.width, height = currentImg.extent.height
        
        let xNorm = point.x * width
        let yNorm = point.y * height
        
        let pixelCoord = CGPoint(x: xNorm, y: yNorm)
        
        
        return pixelCoord
    }
    
    
    
    // MARK: - Coordinate and size conversion
    
    
    /// Requirements:
    ///
    /// The following need to be valid in order for this to work:
    /// MetalView
    /// ViewSize
    ///
    /// We should call it only when calculating position, not on page load etc.
    
    private func calculateCoords() {
        
        // Unwrap the current image
        guard let currentImg = viewModel.currentImage else {
            print("\nCurrent image is nil\n\n")
            return }
        
        
        // First load in the metal Width
        let metalWidth = viewModel.metalSize.width
        let metalHeight = viewModel.metalSize.height
        
        // Then normalise the imageSize
        let imgWidthNorm = viewModel.metalImageWidth / metalWidth
        let imgHeightNorm = viewModel.metalImageHeight / metalHeight
        
        // Then normalise the padding
        let paddingXNorm = ((metalWidth - viewModel.metalImageWidth) / 2.0) / metalWidth
        let paddingYNorm = ((metalHeight - viewModel.metalImageHeight) / 2.0) / metalHeight
        
        // Load in the current views width / height
        let uiWidth = viewWidth
        let uiHeight = viewHeight
        
        // UI Origin
        let uiOrigin = CGPoint(
            x: paddingXNorm * viewWidth,
            y: paddingYNorm * viewHeight
        )
        
        // Calculate the image size
        let uiImgWidth = uiWidth * imgWidthNorm
        let uiImgHeight = uiHeight * imgHeightNorm
        
        
        // Update vars
        imgSizeUI = CGSize(width: uiImgWidth, height: uiImgHeight)
        imgOrignUI = uiOrigin
        currentImgSize = currentImg.extent.size
    }
    
    /*
     NB:
     
     To get normalised image coords we can do the following:
     
     (CurrentCoords - Origin) / image size
     
     Then we can flip the Y axis, and multiply the coords by the CIImages
     size to get the coreimage coords.
     
     */


    
    
    /// Accepts ui coord, and returns coord
    /// converted to image coords for CoreImage
    private func convertCoords(_ coord: CGPoint) -> CGPoint {
        calculateCoords()
        
        
        let origin = imgOrignUI
        let imgWidth = imgSizeUI.width
        let imgHeight = imgSizeUI.height
        
        let normalizedX = (coord.x - origin.x) / imgWidth
        
        // Normalise Y, then flip (1.0 – normalizedY)
        let normalizedY = (coord.y - origin.y) / imgHeight
        let flippedY = 1.0 - normalizedY
        
        let normCoord = CGPoint(x: normalizedX, y: flippedY)
        let ciCoord = CGPoint(x: normCoord.x * currentImgSize.width, y: normCoord.y * currentImgSize.height)
        
        return ciCoord
    }
    
    
    
    /// Accepts a CIImage coordinate and returns its corresponding point in UI space.
    private func convertCoordsToUI(_ ciCoord: CGPoint) -> CGPoint {
        calculateCoords()
        
        let origin = imgOrignUI
        let imgWidth = imgSizeUI.width
        let imgHeight = imgSizeUI.height
        let ciWidth = currentImgSize.width
        let ciHeight = currentImgSize.height
        
        // Step 1: Normalize CI coordinates (0–1)
        let normX = ciCoord.x / ciWidth
        let normY = ciCoord.y / ciHeight
        
        // Step 2: Undo Y flip (1.0 – normalizedY)
        let unflippedY = 1.0 - normY
        
        // Step 3: Scale to UI image size
        let uiX = normX * imgWidth + origin.x
        let uiY = unflippedY * imgHeight + origin.y
        
        return CGPoint(x: uiX, y: uiY)
    }
    
    /// For converting any variables such as width or height etc
    /// from UI relative size to CoreImage size
    private func convertSizes(_ length: CGFloat) -> CGFloat {
        calculateCoords()
        
        let UI_to_CI_scalar: CGFloat = currentImgSize.height / imgSizeUI.height
        
        return length * UI_to_CI_scalar
    }
    
    
    private func calculateRadialWidthAndHeightForCI(_ start: CGPoint, _ end: CGPoint) -> (CGFloat, CGFloat) {
        
        
        let dx = abs(end.x - start.x)
        let dy = abs(end.y - start.y)
        
//        return (dx * 2, dy * 2)
        
        var width = dx * 2
        var height = dy * 2
        
        (width, height) = scaleWidthHeightUI(start, end, width, height)
        
        
        return (width, height)
    }
    
    private func calculateRadialWidthAndHeightForUI(_ start: CGPoint, _ end: CGPoint) -> (CGFloat, CGFloat) {
        
        
        let dx = abs(end.x - start.x)
        let dy = abs(end.y - start.y)
        
        var width = dx * 2
        var height = dy * 2
        
        (width, height) = scaleWidthHeightUI(start, end, width, height)
        
        
        return (width, height)
    }
    

    
    
    
    
    
    // MARK: - Gestures
    
    
    
    // ****************************************************************** //
    // ****************************** TAP ******************************* //
    // ****************************************************************** //
    
    
    private func zoomTap() -> some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { value in
                
                print("Double tapped")
                
                let location = value.location
                
                
                // Calculate location
                let ciPoint = convertCoords(location)
                
                if viewModel.isZoomed {
                    viewModel.zoomScale = 1.0
                    viewModel.isZoomed = false
                    viewModel.zoomRect = .zero
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let id = viewModel.currentImgID {
                            print("ZoomingOut")
                            FilterPipeline.shared.applyPipelineV2Sync(id, dataModel)
                            
                        }
                    }
                } else {
                    print("Zooming")
                    let rect = viewModel.calculateZoomRect(ciPoint, imgSizeUI, CGSize(width: viewWidth, height: viewHeight))
                    
                    print("ZoomRect Size: \(rect)")
                    viewModel.zoomRect = rect
                    viewModel.isZoomed = true
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let id = viewModel.currentImgID {
							print("ZoomingIn")
                            FilterPipeline.shared.applyPipelineV2Sync(id, dataModel)
                            
                        }
                    }
                }
                

            }
    }
    

    
    
    
    
    
    
    // ****************************************************************** //
    // ****************************** PAN ******************************* //
    // ****************************************************************** //
    
    private func clampedRect(_ rect: CGRect, in bounds: CGRect) -> CGRect {
        var newRect = rect
        
        // Horizontal clamp
        if newRect.minX < bounds.minX {
            newRect.origin.x = bounds.minX
        }
        if newRect.maxX > bounds.maxX {
            newRect.origin.x = bounds.maxX - newRect.width
        }
        
        // Vertical clamp
        if newRect.minY < bounds.minY {
            newRect.origin.y = bounds.minY
        }
        if newRect.maxY > bounds.maxY {
            newRect.origin.y = bounds.maxY - newRect.height
        }
        
        return newRect
    }

    private func panGesture() -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard viewModel.isZoomed else { return }
                
                let aspectRatio = imgSizeUI.width / imgSizeUI.height
                let nativeWidth: Int
                let nativeHeight: Int
                
                if aspectRatio > 1.0 {
                    nativeWidth = max(viewModel.nativeHeight, viewModel.nativeWidth)
                    nativeHeight = min(viewModel.nativeHeight, viewModel.nativeWidth)
                } else {
                    nativeWidth = min(viewModel.nativeHeight, viewModel.nativeWidth)
                    nativeHeight = max(viewModel.nativeHeight, viewModel.nativeWidth)
                }
                
                // Define the full image bounds (in CI space)
                let imageBounds = CGRect(x: 0, y: 0, width: CGFloat(nativeWidth), height: CGFloat(nativeHeight))
                
                let backingScale = NSScreen.main?.backingScaleFactor ?? 1.0
                let scale = 4.0 * backingScale // Reduce sensitivity
                let delta = value.translation
                
                // Respect natural scroll setting
                let isNatural = UserDefaults.standard.bool(forKey: "com.apple.swipescrolldirection")
                let adjustedDeltaY = isNatural ? -delta.height : delta.height
                
                lastDragOffset.width = viewModel.zoomRect.origin.x
                lastDragOffset.height = viewModel.zoomRect.origin.y
                
                // Calculate new origin
                var newX = lastDragOffset.width - (delta.width / scale)
                var newY = lastDragOffset.height - (adjustedDeltaY / scale)
                
                // Clamp so the zoom window stays inside the image
                let proposedRect = CGRect(
                    x: newX,
                    y: newY,
                    width: viewModel.zoomRect.width,
                    height: viewModel.zoomRect.height
                )
                let clamped = clampedRect(proposedRect, in: imageBounds)
                
                // Update to clamped position
                newX = clamped.origin.x
                newY = clamped.origin.y
                
                currentOffset = CGSize(width: newX, height: newY)
                viewModel.zoomRect.origin = CGPoint(x: newX, y: newY)
                
                if let id = viewModel.currentImgID {
                    FilterPipeline.shared.applyPipelineV2Sync(id, dataModel)
                }
            }
            .onEnded { _ in
                guard viewModel.isZoomed else { return }
                lastDragOffset = currentOffset
                viewModel.zoomRect = CGRect(
                    x: currentOffset.width,
                    y: currentOffset.height,
                    width: viewModel.zoomRect.width,
                    height: viewModel.zoomRect.height
                )
            }
    }
    
    
    
    
    
    
    // ****************************************************************** //
    // ***************************** RADIAL ***************************** //
    // ****************************************************************** //
    

    
    private func radialPointsEqual() -> Bool {
        return viewModel.radialUiStart == viewModel.radialUiEnd
    }
    
    
    private func adjustRadialPoints(_ choice: Int) -> CGPoint {
        
        let start = viewModel.radialUiStart
        let end = viewModel.radialUiEnd
        let width = viewModel.radialUiWidth
        let height = viewModel.radialUiHeight
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(sqrt(dx * dx + dy * dy), 0.001)
        let ux = dx / length
        let uy = dy / length
        
        let rx = width / 2
        let ry = height / 2
        
        let ellipseEdgeX = start.x + ux * rx
        let ellipseEdgeY = start.y + uy * ry
        let adjustedEnd = CGPoint(x: ellipseEdgeX, y: ellipseEdgeY)
        
        let innerCircleRadius: CGFloat = 10
        let adjustedStart = CGPoint(x: start.x + ux * innerCircleRadius,
                                    y: start.y + uy * innerCircleRadius)
        let adjustedLineEnd = CGPoint(x: adjustedEnd.x - ux * innerCircleRadius,
                                      y: adjustedEnd.y - uy * innerCircleRadius)
        
//        viewModel.radialUiStart = adjustedStart
//        viewModel.radialUiEnd = adjustedEnd
//        updateRadialBinding()
        
        let padding = calculateAndReturnPadding()
        
        if choice == 0 {
            return adjustedStart
        } else if choice == 1 {
            return adjustedLineEnd
        } else if choice == 2 {
            return adjustedEnd
        } else {
            return padding
        }
    }
    
    private func updateRadialBinding() {
        (viewModel.radialUiWidth, viewModel.radialUiHeight) = calculateRadialWidthAndHeightForUI(viewModel.radialUiStart, viewModel.radialUiEnd)
        let ciStart = convertCoords(viewModel.radialUiStart)
        let ciEnd = convertCoords(viewModel.radialUiEnd)
        $radialStartPointBinding.wrappedValue = normaliseCoord(ciStart)
        $radialEndPointBinding.wrappedValue = normaliseCoord(ciEnd)
        
        let (ciWidth, ciHeight) = calculateRadialWidthAndHeightForCI(ciStart, ciEnd)
        
        $radialWidthBinding.wrappedValue = normaliseWidth(ciWidth)
        $radialHeightBinding.wrappedValue = normaliseHeight(ciHeight)
    }
    
    // Calculates radialUiEnd based on the current radial start, width, height,
    // and the direction vector implied by the current end point.
    private func radialEndUI() -> CGPoint {
        let start = viewModel.radialUiStart
        let end = viewModel.radialUiEnd
        
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(sqrt(dx * dx + dy * dy), 0.001)
        let ux = dx / length
        let uy = dy / length
        
        let rx = viewModel.radialUiWidth / 2
        let ry = viewModel.radialUiHeight / 2
        
        // Scale factor to ensure the end point lies on the ellipse edge
        let scale = 1.0 / sqrt((ux * ux) / (rx * rx) + (uy * uy) / (ry * ry))
        
        let result = CGPoint(
            x: start.x + ux * scale,
            y: start.y + uy * scale
        )
        
        
        
        return result
    }
    
    private func normaliseWidth(_ width: CGFloat) -> CGFloat{
        guard let currentImg = viewModel.currentImage else {
            print("\nCurrent image is nil\n\n")
            return  0.0}
        let imgwidth = currentImg.extent.width
        
        return width / imgwidth
    }
    
    private func normaliseHeight(_ height: CGFloat) -> CGFloat{
        guard let currentImg = viewModel.currentImage else {
            print("\nCurrent image is nil\n\n")
            return  0.0}
        let imgHeight = currentImg.extent.height
        
        return height / imgHeight
    }
    
    
    private func deNormaliseWidth(_ width: CGFloat) -> CGFloat{
        guard let currentImg = viewModel.currentImage else {
            print("\nCurrent image is nil\n\n")
            return  0.0}
        let imgwidth = currentImg.extent.width
        
        return width * imgwidth
    }
    
    private func deNormaliseHeight(_ height: CGFloat) -> CGFloat{
        guard let currentImg = viewModel.currentImage else {
            print("\nCurrent image is nil\n\n")
            return  0.0}
        let imgHeight = currentImg.extent.height
        
        return height * imgHeight
    }
    
    private func radialMaskGesture() -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard viewModel.drawingRadialMask && !viewModel.initialMaskDrawn else {return}
                
                // Calculate UI Variables
                viewModel.radialUiStart = value.startLocation
                viewModel.radialUiEnd = value.location
//                (viewModel.radialUiWidth, viewModel.radialUiHeight) = calculateRadialWidthAndHeightForUI(value.startLocation, value.location)
                (viewModel.radialUiWidth, viewModel.radialUiHeight) =
                    calculateEllipseSizeFromPoint(viewModel.radialUiStart, viewModel.radialUiEnd)
                
//                updateRadialBinding()
                
                // Calculate CoreImage variables
                let ciStart = convertCoords(value.startLocation)
                let ciEnd = convertCoords(value.location)
                
                $radialStartPointBinding.wrappedValue = normaliseCoord(ciStart)
                $radialEndPointBinding.wrappedValue = normaliseCoord(ciEnd)
                
                let (ciWidth, ciHeight) = calculateRadialWidthAndHeightForCI(ciStart, ciEnd)
                
                $radialWidthBinding.wrappedValue = normaliseWidth(ciWidth)
                $radialHeightBinding.wrappedValue = normaliseHeight(ciHeight)
                
                
            }
            .onEnded{ value in
                guard viewModel.drawingRadialMask && !viewModel.initialMaskDrawn else { return }
                
                // Calculate UI Variables
                viewModel.radialUiStart = value.startLocation
                viewModel.radialUiEnd = value.location
//                (viewModel.radialUiWidth, viewModel.radialUiHeight) = calculateRadialWidthAndHeightForUI(value.startLocation, value.location)
                
                (viewModel.radialUiWidth, viewModel.radialUiHeight) =
                    calculateEllipseSizeFromPoint(viewModel.radialUiStart, viewModel.radialUiEnd)
                
                initialRadialStart = viewModel.radialUiStart
                initialRadialEnd = viewModel.radialUiEnd
                
//                updateRadialBinding()
                
                // Calculate CoreImage variables
                let ciStart = convertCoords(value.startLocation)
                let ciEnd = convertCoords(value.location)
                $radialStartPointBinding.wrappedValue = normaliseCoord(ciStart)
                $radialEndPointBinding.wrappedValue = normaliseCoord(ciEnd)
                
                let (ciWidth, ciHeight) = calculateRadialWidthAndHeightForCI(ciStart, ciEnd)
                
                $radialWidthBinding.wrappedValue = normaliseWidth(ciWidth)
                $radialHeightBinding.wrappedValue = normaliseHeight(ciHeight)
                
                
                
                viewModel.initialMaskDrawn = true
            }
    }
    
    private func moveRadialMaskGesture() -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                viewModel.radialUiStart = CGPoint(
                    x: initialRadialStart.x + gesture.translation.width,
                    y: initialRadialStart.y + gesture.translation.height
                )
                
                viewModel.radialUiEnd = CGPoint(
                    x: initialRadialEnd.x + gesture.translation.width,
                    y: initialRadialEnd.y + gesture.translation.height
                )

                
            }
            .onEnded { _ in
                initialRadialStart = viewModel.radialUiStart
                initialRadialEnd = viewModel.radialUiEnd
                

                // Calculate CoreImage variables
                let ciStart = convertCoords(viewModel.radialUiStart)
                let ciEnd = convertCoords(viewModel.radialUiEnd)
                $radialStartPointBinding.wrappedValue = normaliseCoord(ciStart)
                $radialEndPointBinding.wrappedValue = normaliseCoord(ciEnd)
                
                let (ciWidth, ciHeight) = calculateRadialWidthAndHeightForCI(ciStart, ciEnd)
                
                $radialWidthBinding.wrappedValue = normaliseWidth(ciWidth)
                $radialHeightBinding.wrappedValue = normaliseHeight(ciHeight)
            }
    }
    
    /// Given the ellipse center (start) and a point (end),
    /// returns the width and height so the ellipse edge passes through that point.
    private func calculateEllipseSizeFromPoint(_ start: CGPoint, _ end: CGPoint) -> (CGFloat, CGFloat) {
        let dx = abs(end.x - start.x)
        let dy = abs(end.y - start.y)
        
        var width = dx * 2
        var height = dy * 2
        
        (width, height) = scaleWidthHeightUI(start, end, width, height)
        
        
        return (width, height)
    }
    
    /// Scales the given width and height so that the ellipse passes through `point`,
    /// relative to `center`. Returns adjusted (width, height).
    private func scaleWidthHeightUI(_ start: CGPoint, _ end: CGPoint, _ width: CGFloat, _ height: CGFloat) -> (CGFloat, CGFloat) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        
        let rx = max(width / 2, 0.001)
        let ry = max(height / 2, 0.001)
        
        // How far along the ellipse radius the point is (scale factor).
        let ratio = sqrt((dx * dx) / (rx * rx) + (dy * dy) / (ry * ry))
        
        // If ratio <= 1, point is already inside or on the ellipse, no scaling needed.
        guard ratio > 0 else { return (width, height) }
        
        let scale = 1.0 + (1.0 - (1 / ratio))

        return (width * scale, height * scale)
    }
    
    private func resizeRadialMaskGesture() -> some Gesture {
        DragGesture()
            .onChanged { gesture in
                let start = viewModel.radialUiStart
                let dragLocation = CGPoint(
                    x: initialRadialEnd.x + gesture.translation.width,
                    y: initialRadialEnd.y + gesture.translation.height
                )

                // The dragged point *defines* the ellipse edge.
                viewModel.radialUiEnd = dragLocation
                (viewModel.radialUiWidth, viewModel.radialUiHeight) =
                    calculateEllipseSizeFromPoint(start, dragLocation)
            }
            .onEnded { value in
                let endLocation = CGPoint(
                    x: initialRadialEnd.x + value.translation.width,
                    y: initialRadialEnd.y + value.translation.height
                )

                // Final width/height so ellipse includes the handle
                (viewModel.radialUiWidth, viewModel.radialUiHeight) =
                    calculateEllipseSizeFromPoint(viewModel.radialUiStart, endLocation)

                initialRadialEnd = endLocation
                viewModel.radialUiEnd = endLocation

                // CoreImage coordinate updates
                let ciStart = convertCoords(viewModel.radialUiStart)
                let ciEnd = convertCoords(endLocation)
                $radialStartPointBinding.wrappedValue = normaliseCoord(ciStart)
                $radialEndPointBinding.wrappedValue = normaliseCoord(ciEnd)

                let (ciWidth, ciHeight) = calculateRadialWidthAndHeightForCI(ciStart, ciEnd)
                $radialWidthBinding.wrappedValue = normaliseWidth(ciWidth)
                $radialHeightBinding.wrappedValue = normaliseHeight(ciHeight)
            }
    }
    
    
    
    // ****************************************************************** //
    // ***************************** LINEAR ***************************** //
    // ****************************************************************** //
    
    
    private func linearPointsEqual() -> Bool {
        return viewModel.uiStartPoint == viewModel.uiEndPoint
    }
    
    
    
    private func linearAdjustedLine(_ choice: Int) -> CGPoint {
        let start = viewModel.uiStartPoint
        let end = viewModel.uiEndPoint
        let radius: CGFloat = 10
        
        // Vector from start to end
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = max(sqrt(dx * dx + dy * dy), 0.001) // prevent divide by 0
        
        // Unit direction vector
        let ux = dx / length
        let uy = dy / length
        
        // Adjusted points at the edge of the circles
        let adjustedStart = CGPoint(x: start.x + ux * radius, y: start.y + uy * radius)
        let adjustedEnd = CGPoint(x: end.x - ux * radius, y: end.y - uy * radius)
        
        if choice == 0 {
            return adjustedStart
        } else {
            return adjustedEnd
        }
    }
    
    private func updateLinearMask() {
        let ciStart = convertCoords(viewModel.uiStartPoint)
        let ciEnd = convertCoords(viewModel.uiEndPoint)
        
        $LinearStartPointBinding.wrappedValue = normaliseCoord(ciStart)
        $LinearEndPointBinding.wrappedValue = normaliseCoord(ciEnd)
    }
    

    
    // Main Gesture, used to draw initial mask
    private func linearMaskGesture() -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard viewModel.drawingLinearMask && !viewModel.initialMaskDrawn else {return}
                viewModel.uiStartPoint = value.startLocation
                viewModel.uiEndPoint = value.location
                
                updateLinearMask()
                
            }
            .onEnded { value in
                guard viewModel.drawingLinearMask && !viewModel.initialMaskDrawn else {return}
                viewModel.uiStartPoint = value.startLocation
                viewModel.uiEndPoint = value.location
                
                updateLinearMask()
                
                
                
                initialCircleStart = viewModel.uiStartPoint
                initialCircleEnd = viewModel.uiEndPoint
                
                viewModel.initialMaskDrawn = true
            }
    }
    
    
    
    
    
    
    

    
    
    private func calculateAndReturnPadding() -> CGPoint {
        return CGPoint(
            x: (viewWidth - viewModel.metalImageWidth) / 2.0,
            y: (viewHeight - viewModel.metalImageHeight) / 2.0)
    }

    
}





