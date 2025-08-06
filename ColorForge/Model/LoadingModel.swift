//
//  LoadingModel.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import Foundation
import CoreImage
import SwiftUI
import CoreGraphics


class LoadingModel {
	static let shared = LoadingModel()
	let pipeline = FilterPipeline.shared
	
	// MARK: - main function
	
	
	/*
	 
	 The aim of this function will be to ingest raw URLS and begin to populate the imageItem struct
	 
	 
	 
	 */
	
	
//	func loadImage(for item: ImageItem, in dataModel: DataModel) {
//		let id = item.id
//		let url = item.url
//		
//		// Step 1 - Debayer and extract metadata
//		let debayerNode = DebayerNode(rawFileURL: url)
//		let (debayered, xySIMD, baseline, nativeWidth, nativeHeight, rotation) = debayerNode.apply()
//		
//		guard let (temp, tint) = debayered.calculateTempAndTintFromXY(xySIMD.x, xySIMD.y) else { return }
//	
//
//		let pipelineNodes = pipeline.buildPipeline(for: item, isInit: false, isExport: false)
//		let pipelineResult = pipelineNodes.reduce(debayered) { image, node in
//			node.apply(to: image)
//		}
//		
//		pipelineResult.renderAndUpdateThumb(id: id, in: dataModel)
//		
//		
//		// Step 1 — Update debayeredInit
//		dataModel.updateItem(id: id) { updated in
//			updated.imageObjects.debayeredInit = debayered
//			updated.imageData.nativeWidth = nativeWidth
//			updated.imageData.nativeHeight = nativeHeight
//			updated.imageData.nativeRotation = rotation
//			
//			updated.rawAdjustSettings.xyChromaticity = CGPoint(x: CGFloat(xySIMD.x), y: CGFloat(xySIMD.y))
//			updated.rawAdjustSettings.temp = temp
//			updated.rawAdjustSettings.tint = tint
//			updated.rawAdjustSettings.initTemp = temp
//			updated.rawAdjustSettings.initTint = tint
//			updated.rawAdjustSettings.baselineExposure = baseline
//			
//			updated.imageObjects.processImage = pipelineResult
//		}
//	
//
//		// Move this to when an image is first loaded into the image view
//		// Step 4 — Background full-resolution render (slow)
////		DispatchQueue.global(qos: .background).async {
////			let debayerLarge = DebayerFullNode(rawFileURL: url, scale: 0.5)
////			let large = debayerLarge.apply()
////			
////			DispatchQueue.main.async {
////				dataModel.updateItem(id: id) { updated in
////					updated.imageObjects.fullResCiImage = large
////				}
////				print("Full-res image assigned for ID: \(id)")
////			}
////		}
//	}
	
	
}
