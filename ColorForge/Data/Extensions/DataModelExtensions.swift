//
//  DataModelExtensions.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import Foundation
import SwiftUI
import AppKit
import ImageIO

extension DataModel {
	

	
	func updateItem(id: UUID, mutate: @escaping (inout ImageItem) -> Void) {
		guard let index = items.firstIndex(where: { $0.id == id }) else { return }

		DispatchQueue.main.async {
			self.objectWillChange.send()
			var copy = self.items[index]
			mutate(&copy)
			self.items[index] = copy
		}
	}
	
	func updateItemV2(id: UUID, mutate: (inout ImageItem) -> Void) {
		if let index = self.items.firstIndex(where: { $0.id == id }) {
			var copy = self.items[index]
			mutate(&copy)
			self.items[index] = copy
		}
	}
	
	func binding<T: Equatable>(
		for url: URL,
		settingsPath: WritableKeyPath<ImageItem, T>
	) -> UndoableBinding<T>? {
		guard let index = items.firstIndex(where: { $0.url == url }) else { return nil }
        
		let binding = Binding<T>(
			get: {
				self.items[index][keyPath: settingsPath]
			},
			set: { newValue in
				
				let oldValue = self.items[index][keyPath: settingsPath]
				if oldValue != newValue {
					self.items[index][keyPath: settingsPath] = newValue
					
					if let id = ImageViewModel.shared.currentImgID {
						Task(priority: .userInitiated) {
							await FilterPipeline.shared.applyPipelineV2(id, self)
						}
					}
				}
			}
		)

		let setUndoable: (_ newValue: T, _ label: String) -> Void = { newValue, label in
			let oldValue = self.items[index][keyPath: settingsPath]
			if oldValue != newValue {
				self.undoManager?.registerUndo(withTarget: self) { target in
					target.items[index][keyPath: settingsPath] = oldValue
					if let id = ImageViewModel.shared.currentImgID {
						Task(priority: .userInitiated) {
							await FilterPipeline.shared.applyPipelineV2(id, self)
						}
					}
				}
				self.undoManager?.setActionName(label)

				self.items[index][keyPath: settingsPath] = newValue
				if let id = ImageViewModel.shared.currentImgID {
					Task(priority: .userInitiated) {
						await FilterPipeline.shared.applyPipelineV2(id, self)
					}
				}
			}
		}

		return UndoableBinding(binding: binding, setUndoable: setUndoable)
	}
	
	
	

	
	
	
	
	
	
	
	
	
	
	
	
	
//	// Binding
//	func binding<T>(
//		for url: URL,
//		settingsPath: WritableKeyPath<ImageItem, T>
//	) -> Binding<T>? {
//		guard let index = items.firstIndex(where: { $0.url == url }) else { return nil }
//		
//		return Binding(
//			get: {
//				self.items[index][keyPath: settingsPath]
//			},
//			set: { newValue in
//
//					print("Setting new value for \(settingsPath): \(newValue)")
//					self.items[index][keyPath: settingsPath] = newValue
//					_ = FilterPipeline.shared.applyPipeline(for: self.items[index].url, in: self)
//
//			}
//		)
//	}
	
//	func extractEmbeddedThumbnail(from url: URL, for id: UUID, completion: @escaping () -> Void) {
//		
//		guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
//			  CGImageSourceGetCount(imageSource) > 0 else {
//			print("Failed to create image source for embedded preview.")
//			completion()
//			return
//		}
//		
//		// Try to get the first image (embedded preview)
//		let options: [NSString: Any] = [
//			kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
//			kCGImageSourceCreateThumbnailWithTransform: true,
//			kCGImageSourceThumbnailMaxPixelSize: 300
//		]
//		
//		guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
//			print("Failed to extract embedded thumbnail.")
//			completion()
//			return
//		}
//		
//		let nsImage = NSImage(cgImage: thumbnail, size: NSSize(width: thumbnail.width, height: thumbnail.height))
//		
////		DispatchQueue.main.async {
//			self.updateItem(id: id) { updated in
//				var newImageObjects = updated.imageObjects
//				newImageObjects.thumbnailImage = nsImage
//				updated.imageObjects = newImageObjects // Reassign to trigger SwiftUI
//			}
//			print("Extracted embedded thumbnail successfully.")
//			completion()
////		}
//		
//	}
	
//	func extractPreview(from rawURL: URL, completion: @escaping (NSImage?) -> Void) {
////		DispatchQueue.global(qos: .userInitiated).async{
//			
//			let options: [CFString: Any] = [
//				kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
//				kCGImageSourceCreateThumbnailWithTransform: true, // Preserves original orientation
//				kCGImageSourceThumbnailMaxPixelSize: 500
//			]
//			
//			// Create the CGImageSource
//			guard let source = CGImageSourceCreateWithURL(rawURL as CFURL, nil) else {
//				print("Failed to create CGImageSource from URL: \(rawURL)")
//				completion(nil)
//				return
//			}
//			
//			// Create the thumbnail CGImage
//			guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
//				print("Failed to create thumbnail for URL: \(rawURL)")
//				completion(nil)
//				return
//			}
//			
//
//			
//			// Convert CGImage to NSImage
//			let previewImage = NSImage(cgImage: cgImage, size: .zero)
//			
//			
//			// Call the completion handler with the preview image and date
////			DispatchQueue.main.async{
//				completion(previewImage)
////			}
////		}
//	}
	
//	func extractPreview(from rawURL: URL) {
//			
//			let options: [CFString: Any] = [
//				kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
//				kCGImageSourceCreateThumbnailWithTransform: true, // Preserves original orientation
//				kCGImageSourceThumbnailMaxPixelSize: 500
//			]
//			
//			// Create the CGImageSource
//			guard let source = CGImageSourceCreateWithURL(rawURL as CFURL, nil) else {
//				print("Failed to create CGImageSource from URL: \(rawURL)")
//				return
//			}
//			
//			// Create the thumbnail CGImage
//			guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
//				print("Failed to create thumbnail for URL: \(rawURL)")
//				return
//			}
//
//			// Convert CGImage to NSImage
//			let previewImage = NSImage(cgImage: cgImage, size: .zero)
//	}
//	
	
//	func extractEmbeddedThumbnail(from url: URL, for id: UUID) {
//		DispatchQueue.global(qos: .userInitiated).async {
//			guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil),
//				  CGImageSourceGetCount(imageSource) > 0 else {
//				print("Failed to create image source for embedded preview.")
//				return
//			}
//			
//			// Try to get the first image (embedded preview)
//			let options: [NSString: Any] = [
//				kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
//				kCGImageSourceCreateThumbnailWithTransform: true,
//				kCGImageSourceThumbnailMaxPixelSize: 300
//			]
//			
//			guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
//				print("Failed to extract embedded thumbnail.")
//				return
//			}
//			
//			let nsImage = NSImage(cgImage: thumbnail, size: NSSize(width: thumbnail.width, height: thumbnail.height))
//			
//			DispatchQueue.main.async {
//				self.updateItem(id: id) { updated in
//					var newData = updated.imageData
//					var newImageObjects = updated.imageObjects
//					newImageObjects.thumbnailImage = nsImage
//					newData.thumbLoaded = true
//					updated.imageObjects = newImageObjects // Reassign to trigger SwiftUI
//					updated.imageData = newData
//				}
//				print("Extracted embedded thumbnail successfully.")
//			}
//
//		}
//	}
	
//	
//	func currentBinding<T>(
//		for pipeline: FilterPipeline,
//		settingsPath: WritableKeyPath<RawAdjustSettings, T>
//	) -> Binding<T>? {
//		let url = pipeline.currentURL ?? self.items.first?.url
//		return url.flatMap { self.binding(for: $0, settingsPath: settingsPath) }
//	}
	
	
}

extension UndoableBinding {
	func undoable(using dataModel: DataModel, label: String = "Edit") -> Binding<Value> {
		Binding(
			get: { self.binding.wrappedValue },
			set: { newValue in
				self.setUndoable(newValue, label)
			}
		)
	}
	
	static func constant(_ value: Value) -> UndoableBinding<Value> {
		UndoableBinding(
			binding: .constant(value),
			setUndoable: { _, _ in }
		)
	}

}

extension DataModel {
	var visibleItems: [ImageItem] {
		// Currently just returns all; add sorting/filtering logic here later
		items
	}
}
