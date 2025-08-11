//
//  ContentViewSam.swift
//  ColorForge
//
//  Created by admin on 30/07/2025.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import CoreML

import os

// TODO: Add reset, bounding box, and eraser

let logger = Logger(
	subsystem:
		"com.cyrilzakka.SAM2-Demo.ContentView",
	category: "ContentView")


struct PointsOverlay: View {
	@Binding var selectedPoints: [SAMPoint]
	@Binding var selectedTool: SAMTool?
	let imageSize: CGSize
	
	var body: some View {
		ForEach(selectedPoints, id: \.self) { point in
			Circle()
				.frame(width: 10, height: 10)
				.foregroundStyle(point.category.color)
				.position(point.coordinates.toSize(imageSize))
			
		}
	}
}

struct BoundingBoxesOverlay: View {
	let boundingBoxes: [SAMBox]
	let currentBox: SAMBox?
	let imageSize: CGSize
	
	var body: some View {
		ForEach(boundingBoxes) { box in
			BoundingBoxPath(box: box, imageSize: imageSize)
		}
		if let currentBox = currentBox {
			BoundingBoxPath(box: currentBox, imageSize: imageSize)
		}
	}
}

struct BoundingBoxPath: View {
	let box: SAMBox
	let imageSize: CGSize
	
	var body: some View {
		Path { path in
			path.move(to: box.startPoint.toSize(imageSize))
			path.addLine(to: CGPoint(x: box.endPoint.x, y: box.startPoint.y).toSize(imageSize))
			path.addLine(to: box.endPoint.toSize(imageSize))
			path.addLine(to: CGPoint(x: box.startPoint.x, y: box.endPoint.y).toSize(imageSize))
			path.closeSubpath()
		}
		.stroke(
			box.category.color,
			style: StrokeStyle(lineWidth: 2, dash: [5, 5])
		)
	}
}

struct SegmentationOverlay: View {
    @EnvironmentObject var samModel: SamModel
	@Binding var segmentationImage: SAMSegmentation
	let imageSize: CGSize
	
	@State var counter: Int = 0
	var origin: CGPoint = .zero
	var shouldAnimate: Bool = false
	
	var body: some View {
        let nsImage = NSImage(cgImage: segmentationImage.cgImage, size: imageSize)
        
		Image(nsImage: nsImage)
			.resizable()
			.scaledToFit()
			.allowsHitTesting(false)
			.frame(width: imageSize.width, height: imageSize.height)
			.opacity(segmentationImage.isHidden ? 0:0.6)
			.onAppear {
				if shouldAnimate {
					counter += 1
				}
			}
	}

}


struct SegmentationOverlayV2: View {
    @EnvironmentObject var samModel: SamModel
    let imageSize: CGSize

    
    var body: some View {
        
        if let cgImage = samModel.currentMaskCG {
            
            let nsImage = NSImage(cgImage: cgImage, size: imageSize)
                
                Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .allowsHitTesting(false)
                .frame(width: imageSize.width, height: imageSize.height)
                .opacity(samModel.showSamMask ? 0.8 : 0.0)
        }
    }

}


struct ContentViewSam {
	
	// ML Models
	
	
	@State private var imageSize: CGSize = .zero
	
	// File importer
	@State private var imageURL: URL?
	@State private var isImportingFromFiles: Bool = false
	
	
	// Mask exporter
	@State private var exportURL: URL?
	@State private var exportMaskToPNG: Bool = false
	@State private var showInspector: Bool = true
	@State private var selectedSegmentations = Set<SAMSegmentation.ID>()
	
	// Photos Picker
	@State private var isImportingFromPhotos: Bool = false
	@State private var selectedItem: PhotosPickerItem?
	
	@State private var error: Error?
	
	// ML Model Properties
	var tools: [SAMTool] = [pointTool, boundingBoxTool]
	var categories: [SAMCategory] = [.foreground, .background]
	
	@State private var selectedTool: SAMTool?
	@State private var selectedCategory: SAMCategory?
	@State private var selectedPoints: [SAMPoint] = []
	@State private var boundingBoxes: [SAMBox] = []
	@State private var currentBox: SAMBox?
	@State private var originalSize: NSSize?
	@State private var currentScale: CGFloat = 1.0
	@State private var visibleRect: CGRect = .zero
	
}
struct SizePreferenceKey: PreferenceKey {
	static var defaultValue: CGSize = .zero
	static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
		value = nextValue()
	}
}

#Preview {
	ContentView()
}
