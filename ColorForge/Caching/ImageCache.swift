//
//  ImageCache.swift
//  ColorForge
//
//  Created by admin on 12/08/2025.
//

import Foundation
import AppKit
import CoreImage

class ImageCache {
	static let shared = ImageCache()

	private init() {}

	private let thumbnail_cache = NSCache<NSURL, NSImage>()

	func thumbnail_image(for url: NSURL) -> NSImage? {
		return thumbnail_cache.object(forKey: url)
	}

	func insert_thumbnailImage(_ image: NSImage?, for url: NSURL) {
		guard let image = image else { return }
		thumbnail_cache.setObject(image, forKey: url)
	}
}
