//
//  PixelBufferCache.swift
//  ColorForge
//
//  Created by admin on 12/08/2025.
//


/*
 
   ************** USAGE ****************
 
 
 // ------------- Store ---------------- //
 await PixelBufferCache.shared.set(pixelBuffer, for: item.id)

 // ---------- Retrive Buffer ---------- //
 if let pixelBuffer = PixelBufferCache.shared.get(item.id) {
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
    // use ciImage
 }

 // ---------- Retrive Image ---------- //
 if let ciImage = PixelBufferCache.shared.getCIImage(item.id) {
    // use ciImage
 }

 // ------------- Remove --------------- //
 await PixelBufferCache.shared.remove(item.id)
 
 // ----------- Clear All -------------- //
 await PixelBufferCache.shared.removeAll()
 
 */


import Foundation
import CoreImage
import LRUCache

final class PixelBufferCache: NSObject {
    static let shared = PixelBufferCache(limitBytes: PixelBufferCache.calculateOptimalCacheSize())

    // Replace NSCache with LRUCache (true LRU by cost)
    private let cache: LRUCache<String, CVPixelBuffer>
    // Track byte costs so we can log evictions
    private var costs: [String: Int] = [:]
    // Toggle if you don't want eviction logs
    var logEvictions = true
    
    // The actor goes here as a nested type
     private actor CacheState {
         private var costs: [String: Int] = [:]
         
         func setCost(_ cost: Int, for key: String) {
             costs[key] = cost
         }
         
         func getCost(for key: String) -> Int {
             return costs[key] ?? 0
         }
         
         func removeCost(for key: String) {
             costs.removeValue(forKey: key)
         }
         
         func removeAllCosts() {
             costs.removeAll()
         }
     }
     
    private let cacheState = CacheState()
    
    // Calculate optimal cache size: 80% of total RAM × 0.75 = 60% of total RAM
    private static func calculateOptimalCacheSize() -> Int {
        let totalRam = ProcessInfo.processInfo.physicalMemory
        let cacheSize = Double(totalRam) * 0.8 * 0.75  // 80% × 0.75 = 60%
        return Int(cacheSize)
    }
    
    private let totalRam: UInt64 // set during init
    
    private override init() {
        self.totalRam = ProcessInfo.processInfo.physicalMemory
        self.cache = LRUCache<String, CVPixelBuffer>()
        super.init()
    }

    private init(limitBytes: Int) {
        self.totalRam = ProcessInfo.processInfo.physicalMemory
        self.cache = LRUCache<String, CVPixelBuffer>(totalCostLimit: limitBytes)
        super.init()
    }
    
    
    // Convenience method to get total RAM in different units
    var totalRamBytes: UInt64 { totalRam }
    var totalRamMB: Double { Double(totalRam) / (1024 * 1024) }
    var totalRamGB: Double { Double(totalRam) / (1024 * 1024 * 1024) }
    
    // Method to set cache limit as percentage of total RAM
    func setCacheLimitAsPercentageOfRAM(_ percentage: Double) {
        let limitBytes = Int(Double(totalRam) * (percentage / 100.0))
        cache.totalCostLimit = limitBytes
    }

	var totalCostLimitBytes: Int {
		get { cache.totalCostLimit }
		set { cache.totalCostLimit = newValue }
	}

	
	
	
	
	// MARK: - UUID-only convenience (no role)

	func get(_ id: UUID) -> CVPixelBuffer? {
		return get(id.uuidString)
	}

    func set(_ pixelBuffer: CVPixelBuffer, for id: UUID) async { // ADD async
        await set(pixelBuffer, for: id.uuidString) // ADD await
    }

	func remove(_ id: UUID) async {
		await remove(id.uuidString)
	}

	/// Optional: fetch as CIImage directly
	func getCIImage(_ id: UUID) -> CIImage? {
		guard let pixelBuffer = get(id) else { return nil }
		return CIImage(cvPixelBuffer: pixelBuffer)
	}
	
	
	
	
	
	
	func get(_ key: String) -> CVPixelBuffer? {
		cache.value(forKey: key) // access refreshes recency in LRUCache
	}
    
    func set(_ pb: CVPixelBuffer, for key: String) async {
        let cost = CVPixelBufferGetDataSize(pb)

        // Optional eviction logging: compare keys before/after
        let beforeKeys: Set<String> = logEvictions ? Set(cache.keys) : []

        // Adjust local meter for replacements
        if let old = cache.value(forKey: key) {
            await cacheState.setCost(CVPixelBufferGetDataSize(old), for: key) // CHANGED
        }

        cache.setValue(pb, forKey: key, cost: cost)
        await cacheState.setCost(cost, for: key) // CHANGED

        if logEvictions {
            let afterKeys = Set(cache.keys)
            let evicted = beforeKeys.subtracting(afterKeys).subtracting([key])
            if !evicted.isEmpty {
                for k in evicted {
                    let evictedCost = await cacheState.getCost(for: k) // CHANGED
                    let mb = Double(evictedCost) / (1024 * 1024)
                    LogModel.shared.log("\nEvicting LR Buffer with key: \(k) (size: \(mb) MB)\n")
                    await cacheState.removeCost(for: k) // CHANGED
                }
            }
        }
    }

	/* func set(_ pb: CVPixelBuffer, for key: String) {
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
//                    print("\nEvicting CVPixelBuffer with key: \(k) (size: \(evictedCost) bytes)\n")
                    let mb = Double(evictedCost) / (1024 * 1024)
                    LogModel.shared.log("\nEvicting LR Buffer with key: \(k) (size: \(mb) MB)\n")
					costs.removeValue(forKey: k)
				}
			}
		}
	} */

//	func remove(_ key: String) {
//		_ = cache.removeValue(forKey: key)
//		costs.removeValue(forKey: key)
//	}
    
    func remove(_ key: String) async {
        _ = cache.removeValue(forKey: key)
        await cacheState.removeCost(for: key) // CHANGED
    }

//	func removeAll() {
//		cache.removeAll()
//		costs.removeAll()
//	}
    
    func removeAll() async {
        cache.removeAll()
        await cacheState.removeAllCosts() // CHANGED
    }
    
    func contains(_ id: UUID) -> Bool {
        return get(id) != nil
    }
}
