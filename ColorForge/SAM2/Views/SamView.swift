//
//  ImageView.swift
//  SAM2-Demo
//
//  Created by Cyril Zakka on 9/8/24.
//

import SwiftUI

struct SamView: View {
    @EnvironmentObject var sam2: SAM2
    @EnvironmentObject var viewModel: ImageViewModel
    
    
    let viewWidth: CGFloat
    let viewHeight: CGFloat
    @State var imageSize: CGSize = .zero
    
    @State private var displayImage: NSImage? = nil
    //	@Binding var imageLoaded: Bool
    
    
    //	@Binding var originalSize: NSSize? // Make this the Coreimage size
    
    
    // ML Model Properties
    var tools: [SAMTool] = [pointTool, boundingBoxTool]
    var categories: [SAMCategory] = [.foreground, .background]
    
    @Binding var selectedTool: SAMTool?
    @State private var selectedCategory: SAMCategory?
    @State private var selectedPoints: [SAMPoint] = []
    @State private var boundingBoxes: [SAMBox] = []
    @State private var currentBox: SAMBox?
    @State private var currentSegmentation: SAMSegmentation?
    @State private var segmentationImages: [SAMSegmentation] = []
    @State private var originalSize: CGSize = .zero
    
    
    @State private var imgSize: CGSize = .zero
    
    @State var animationPoint: CGPoint = .zero
    @State private var error: Error?
    
    var pointSequence: [SAMPoint] {
        boundingBoxes.flatMap { $0.points } + selectedPoints
    }
    
    var body: some View {
        
        ZStack {
            
            // Faded image view (background only)
            if let image = displayImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(viewModel.renderingComplete ? 0 : 1)
                    .frame(width: imgSize.width,
                           height: imgSize.height)
            }
            
            // Transparent layer for gestures + overlays
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle()) 
                .frame(width: imgSize.width, height: imgSize.height)
                .onTapGesture(coordinateSpace: .local) { handleTap(at: $0) }
                .gesture(boundingBoxGesture)
                .onHover { changeCursorAppearance(is: $0) }
                .background(GeometryReader { geometry in
                    Color.clear.preference(key: SizePreferenceKey.self, value: geometry.size)
                })
                .onPreferenceChange(SizePreferenceKey.self) { imageSize = $0 }
                .onChange(of: selectedPoints.count, {
                    if !selectedPoints.isEmpty {
                        print("Starting segmentation with \(selectedPoints.count) points")
                        performForwardPass()
                    }
                })
                .onChange(of: boundingBoxes.count, {
                    if !boundingBoxes.isEmpty {
                        print("Starting segmentation")
                        performForwardPass()
                    }
                })
                .overlay {
                    PointsOverlay(selectedPoints: $selectedPoints, selectedTool: $selectedTool, imageSize: imageSize)
                    BoundingBoxesOverlay(boundingBoxes: boundingBoxes, currentBox: currentBox, imageSize: imageSize)
                    
                    if !segmentationImages.isEmpty {
                        ForEach(Array(segmentationImages.enumerated()), id: \.element.id) { index, segmentation in
                            SegmentationOverlay(segmentationImage: $segmentationImages[index], imageSize: imageSize, shouldAnimate: false)
                                .zIndex(Double (segmentationImages.count - index))
                        }
                    }
                    
                    if let currentSegmentation = currentSegmentation {
                        SegmentationOverlay(segmentationImage: .constant(currentSegmentation), imageSize: imageSize, origin: animationPoint, shouldAnimate: true)
                            .zIndex(Double(segmentationImages.count + 1))
                    }
                }
            
                .onAppear {
                    if selectedTool == nil {
                        selectedTool = tools[0]
                    }
                    if selectedCategory == nil {
                        selectedCategory = categories.first
                    }
                    
                }
            
            // MARK: - Image encoding
                .onAppear {
                    segmentationImages = []
                    self.reset()
                    Task {
                        if let displayImage, let pixelBuffer = displayImage.pixelBuffer(width: 1024, height: 1024) {
                            originalSize = displayImage.size
                            do {
                                try await sam2.getImageEncoding(from: pixelBuffer)
                                print("Image encoding complete")
                            } catch {
                                print("Image encoding error")
                                self.error = error
                            }
                        } else {
                            print("Error unwrapping displayImage and converting to buffer")
                        }
                    }
                }
            
            
        }// End of Z Stack
        .background(Color .clear)
        .frame(width: viewWidth, height: viewHeight)
        .onAppear{
            calculateImageSize()
            
            
            if let image = viewModel.currentPreview {
                imageSize = imgSize
                originalSize = image.size
                displayImage = image
            }
        }
        .onChange(of: viewWidth) {
            calculateImageSize()
        }
        .onChange(of: viewHeight) {
            calculateImageSize()
        }
        
    }
    
    private func reset() {
        selectedPoints = []
        boundingBoxes = []
        currentBox = nil
        currentSegmentation = nil
    }
    
    
    
    
    private func changeCursorAppearance(is inside: Bool) {
        if inside {
            if selectedTool == pointTool {
                NSCursor.pointingHand.push()
            } else if selectedTool == boundingBoxTool {
                NSCursor.crosshair.push()
            }
        } else {
            NSCursor.pop()
        }
    }
    
    private var boundingBoxGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard selectedTool == boundingBoxTool else { return }
                
                if currentBox == nil {
                    currentBox = SAMBox(startPoint: value.startLocation.fromSize(imageSize), endPoint: value.location.fromSize(imageSize), category: selectedCategory!)
                } else {
                    currentBox?.endPoint = value.location.fromSize(imageSize)
                }
            }
            .onEnded { value in
                guard selectedTool == boundingBoxTool else { return }
                
                if let box = currentBox {
                    boundingBoxes.append(box)
                    animationPoint = box.midpoint.toSize(imageSize)
                    currentBox = nil
                }
            }
    }
    
    private func handleTap(at location: CGPoint) {
        if selectedTool == pointTool {
            placePoint(at: location)
            animationPoint = location
        }
    }
    
    private func placePoint(at coordinates: CGPoint) {
        let samPoint = SAMPoint(coordinates: coordinates.fromSize(imageSize), category: selectedCategory!)
        self.selectedPoints.append(samPoint)
    }
    
    private func performForwardPass() {
        print("[DEBUG] Starting forward pass...")
        print("[DEBUG] Point sequence count: \(pointSequence.count)")
        print("[DEBUG] Image size passed to prompt encoder: \(imageSize)")
        
        Task {
            do {
                print("[DEBUG] Calling SAM2.getPromptEncoding...")
                try await sam2.getPromptEncoding(from: pointSequence, with: imageSize)
                print("[DEBUG] Prompt encoding complete.")
                
                let targetSize = originalSize ?? .zero
                print("[DEBUG] Requesting mask for size: \(targetSize)")
                
                if let mask = try await sam2.getMask(for: targetSize) {
                    print("[DEBUG] Mask successfully generated (extent: \(mask.extent)). Updating UI...")
                    
                    DispatchQueue.main.async {
                        let colorSet = self.segmentationImages.map { $0.tintColor }
                        let furthestColor = furthestColor(from: colorSet, among: SAMSegmentation.candidateColors)
                        let segmentationNumber = segmentationImages.count
                        
                        print("[DEBUG] Creating new segmentation overlay #\(segmentationNumber + 1) with color: \(furthestColor)")
                        
                        let segmentationOverlay = SAMSegmentation(
                            image: mask,
                            tintColor: furthestColor,
                            title: "Untitled \(segmentationNumber + 1)"
                        )
                        self.currentSegmentation = segmentationOverlay
                    }
                } else {
                    print("[DEBUG] No mask returned from SAM2.getMask.")
                }
            } catch {
                self.error = error
                print("[ERROR] Forward pass failed: \(error)")
            }
        }
    }
    
    private func calculateImageSize() {
        // Unwrap the current image
        guard let currentImg = viewModel.currentImage else { return }
        
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
        
        
        // Calculate the image size
        let uiImgWidth = uiWidth * imgWidthNorm
        let uiImgHeight = uiHeight * imgHeightNorm
        
        imgSize = CGSize(width: uiImgWidth, height: uiImgHeight)
    }
    
    
    
}



#Preview {
    ContentView()
}

extension CGPoint {
    func fromSize(_ size: CGSize) -> CGPoint {
        CGPoint(x: x / size.width, y: y / size.height)
    }
    
    func toSize(_ size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}
