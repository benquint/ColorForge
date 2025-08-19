//
//  PixelBufferHRCache.swift
//  ColorForge
//
//  Created by Ben Quinton on 18/08/2025.
//



/*
 ************** USAGE ****************
 
 // ------------- Store ---------------- //
 await PixelBufferHRCache.shared.set(pixelBuffer, for: item.id)

 // ---------- Retrive Buffer ---------- //
 if let pixelBuffer = PixelBufferHRCache.shared.get(item.id) {
     let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
     // use ciImage
 }

 // ---------- Retrive Image ---------- //
 if let ciImage = PixelBufferHRCache.shared.getCIImage(item.id) {
     // use ciImage
 }

 // ------------- Remove --------------- //
 await PixelBufferHRCache.shared.remove(item.id)
 
 // ----------- Clear All -------------- //
 await PixelBufferHRCache.shared.removeAll()
 
 */


import Foundation
import CoreImage
import LRUCache

final class PixelBufferHRCache: NSObject {
    static let shared = PixelBufferHRCache(limitBytes: PixelBufferHRCache.calculateOptimalCacheSize())

    // Replace NSCache with LRUCache (true LRU by cost)
    private let cache: LRUCache<String, CVPixelBuffer>

    // Toggle if you don't want eviction logs
    var logEvictions = true
    
    // Add this after the cache property:
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

    // Calculate optimal cache size: 10% of total RAM
    private static func calculateOptimalCacheSize() -> Int {
        let totalRam = ProcessInfo.processInfo.physicalMemory
        let cacheSize = Double(totalRam) * 0.2  // 20% of total RAM
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

    func remove(_ id: UUID) async { // ADD async
        await remove(id.uuidString) // ADD await
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
                    LogModel.shared.log("\nEvicting HR Buffer with key: \(k) (size: \(mb) MB)\n")
                    await cacheState.removeCost(for: k) // CHANGED
                }
            }
        }
    }

    func remove(_ key: String) async {
        _ = cache.removeValue(forKey: key)
        await cacheState.removeCost(for: key) // CHANGED
    }

    func removeAll() async {
        cache.removeAll()
        await cacheState.removeAllCosts() // CHANGED
    }
    
    func contains(_ id: UUID) -> Bool {
        return get(id) != nil
    }
}
