//
//  PixelBufferCache.swift
//  ColorForge
//
//  Created by admin on 12/08/2025.
//


/*
 
   ************** USAGE ****************
 
 
 // ------------- Store ---------------- //
 PixelBufferCache.shared.set(pixelBuffer, for: item.id)

 // ---------- Retrive Buffer ---------- //
 if let pixelBuffer = PixelBufferCache.shared.get(item.id) {
	 let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
	 // use ciImage
 }

 // ---------- Retrive Image ---------- //
 if let ciImage = PixelBufferCache.shared.getCIImage(item.id) {
	 // use ciImage
 }
 
 */


import Foundation
import CoreImage
import LRUCache

final class PixelBufferCache: NSObject {
	static let shared = PixelBufferCache(limitBytes: 4 * 1024 * 1024 * 1024)

	// Replace NSCache with LRUCache (true LRU by cost)
	private let cache: LRUCache<String, CVPixelBuffer>
	// Track byte costs so we can log evictions
	private var costs: [String: Int] = [:]
	// Toggle if you don’t want eviction logs
	var logEvictions = true

	private override init() {
		self.cache = LRUCache<String, CVPixelBuffer>()
		super.init()
	}

	private init(limitBytes: Int) {
		self.cache = LRUCache<String, CVPixelBuffer>(totalCostLimit: limitBytes)
		super.init()
	}

	var totalCostLimitBytes: Int {
		get { cache.totalCostLimit }
		set { cache.totalCostLimit = newValue }
	}

	
	
	
	
	// MARK: - UUID-only convenience (no role)

	func get(_ id: UUID) -> CVPixelBuffer? {
		return get(id.uuidString)
	}

	func set(_ pixelBuffer: CVPixelBuffer, for id: UUID) {
		set(pixelBuffer, for: id.uuidString)
	}

	func remove(_ id: UUID) {
		remove(id.uuidString)
	}

	/// Optional: fetch as CIImage directly
	func getCIImage(_ id: UUID) -> CIImage? {
		guard let pixelBuffer = get(id) else { return nil }
		return CIImage(cvPixelBuffer: pixelBuffer)
	}
	
	
	
	
	
	
	func get(_ key: String) -> CVPixelBuffer? {
		cache.value(forKey: key) // access refreshes recency in LRUCache
	}

	func set(_ pb: CVPixelBuffer, for key: String) {
		let cost = CVPixelBufferGetDataSize(pb)

		// Optional eviction logging: compare keys before/after
		let beforeKeys: Set<String> = logEvictions ? Set(cache.keys) : []

		// Adjust local meter for replacements
		if let old = cache.value(forKey: key) {
			costs[key] = CVPixelBufferGetDataSize(old) // ensure we have the old cost
		}

		cache.setValue(pb, forKey: key, cost: cost)
		costs[key] = cost

		if logEvictions {
			let afterKeys = Set(cache.keys)
			let evicted = beforeKeys.subtracting(afterKeys).subtracting([key])
			if !evicted.isEmpty {
				for k in evicted {
					let evictedCost = costs[k] ?? 0
					print("\nEvicting CVPixelBuffer with key: \(k) (size: \(evictedCost) bytes)\n")
					costs.removeValue(forKey: k)
				}
			}
		}
	}

	func remove(_ key: String) {
		_ = cache.removeValue(forKey: key)
		costs.removeValue(forKey: key)
	}

	func removeAll() {
		cache.removeAll()
		costs.removeAll()
	}
}
