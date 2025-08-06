//
//  ImageItemExtensions.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import Foundation
import ImageIO

extension ImageItem {
	
//	
//	private var settingsURL: URL {
//		AppDataManager.shared.settingsURL(for: self)
//	}
//	
	
//	private struct SettingsBundle: Codable {
//		let rawAdjustSettings: RawAdjustSettings
//		let textureSettings: TextureSettings
//		let negConvertSettings: NegConvertSettings
//		let enlargerSettings: EnlargerSettings
//		let scanSettings: ScanSettings
//	}
//	
//	
//	
//	
//	
//	func saveSettings() {
//		let bundle = SettingsBundle(
//			rawAdjustSettings: rawAdjustSettings,
//			textureSettings: textureSettings,
//			negConvertSettings: negConvertSettings,
//			enlargerSettings: enlargerSettings,
//			scanSettings: scanSettings
//		)
//		
//		do {
//			let folder = settingsURL.deletingLastPathComponent()
//			try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
//			let data = try JSONEncoder().encode(bundle)
//			try data.write(to: settingsURL)
//		} catch {
//			print("s Failed to save settings for image: \(error)")
//		}
//	}
	
	
	
	
//	static func load(from url: URL) -> ImageItem {
//		
////		func extractExifDate(from url: URL) -> Date? {
////			guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
////				  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
////				  let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
////				  let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String else {
////				return nil
////			}
////			
////			let formatter = DateFormatter()
////			formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
////			return formatter.date(from: dateString)
////		}
//		
//		
////		let captureDate = extractExifDate(from: url) ?? Date(timeIntervalSince1970: 0)
//		let captureDate = Date()
//		let importDate = Date()
//		let imageData = ImageObjectData(importDate: importDate, captureDate: captureDate)
//		
//		let id = UUID()
//		print("\nLoading: \nImage ID = \(id)\n")
//		
//		let tempItem = ImageItem(
//			id: id,
//			url: url,
//			imageObjects: ImageObject(),
//			imageData: imageData,
//			rawAdjustSettings: RawAdjustSettings(),
//			textureSettings: TextureSettings(),
//			negConvertSettings: NegConvertSettings(),
//			enlargerSettings: EnlargerSettings(),
//			scanSettings: ScanSettings()
//		)
//		
//		let settingsURL = AppDataManager.shared.settingsURL(for: tempItem)
//		
//		if let data = try? Data(contentsOf: settingsURL),
//		   let bundle = try? JSONDecoder().decode(SettingsBundle.self, from: data) {
//			return ImageItem(
//				id: id,
//				url: url,
//				imageObjects: ImageObject(),
//				imageData: imageData,
//				rawAdjustSettings: bundle.rawAdjustSettings,
//				textureSettings: bundle.textureSettings,
//				negConvertSettings: bundle.negConvertSettings,
//				enlargerSettings: bundle.enlargerSettings,
//				scanSettings: bundle.scanSettings
//			)
//		}
//		
//		return tempItem
//	}
}

