//
//  SaveModel.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import CoreImage
import CoreGraphics
import AppKit

class SaveModel {
    static let shared = SaveModel()
    
    // Array of contexts equal to performance cores for batch operations
    let ciContexts: [CIContext]
    
    private init() {
        
        let adobeRGBColorSpace = CGColorSpace(name: CGColorSpace.adobeRGB1998)!
        let device = MTLCreateSystemDefaultDevice()!
        let options: [CIContextOption: Any] = [
            .workingColorSpace: NSNull(),
            .outputColorSpace: adobeRGBColorSpace,
            .name: "batchContext",
            .outputPremultiplied: false,
            .useSoftwareRenderer: false,
            .workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
            .allowLowPower: false,
            .highQualityDownsample: false,
            .priorityRequestLow: false,
            .cacheIntermediates: false,
            .memoryTarget: 4_294_967_296
        ]
        
        var count: Int32 = 0
        var size = MemoryLayout<Int32>.size
        
        let result = sysctlbyname("hw.perflevel0.logicalcpu", &count, &size, nil, 0)
        
        let maxCores: Int
        if result == 0 {
            maxCores = Int(count)
        } else {
            maxCores = 1 // fallback
        }
        
        let numContexts = max(1, maxCores - 1)
        
        self.ciContexts = (0..<numContexts).map { _ in CIContext(mtlDevice: device, options: options) }
        
    }
    
    public func batchSave(_ ids: [UUID], _ dataModel: DataModel, _ destination: URL) async {
        
        let items = dataModel.items.filter { ids.contains($0.id) }

        print("batchSave started: received \(ids.count) IDs")
        print("Matched \(items.count) items in dataModel")

        if items.isEmpty {
            print("No matching items found. Aborting batchSave.")
            return
        }

        let numContexts = ciContexts.count
        let viewModel = ThumbnailViewModel.shared
        let maxGroupSize = viewModel.colCount

        let groupedItems = items.enumerated().reduce(into: Array(repeating: [ImageItem](), count: numContexts)) { result, pair in
            let (index, item) = pair
            result[index % numContexts].append(item)
        }

        await withTaskGroup(of: Void.self) { group in
            for (index, groupItems) in groupedItems.enumerated() {
                let context = ciContexts[index]

                group.addTask {
                    for item in groupItems {
                        let id = item.id
                        let url = item.url

                        if let hrImage = FilterPipeline.shared.applyPipelineV2Sync(id, dataModel) {
                            
                            let scaled = hrImage.scaleToValue(CGFloat(item.saveScale))
                            
                            await self.saveImageTiff(item, scaled, url, destination, context)
                            
                            await MainActor.run {
                                dataModel.updateItem(id: id) { item in
                                    item.isSaved = true
                                }
                            }
                            
                        } else {
                            print("Failed to generate image for item \(id)")
                        }
                    }
                }
            }
        }

        // Now that all image saves have completed, mark all as not exporting
        await MainActor.run {
            
            
            for id in ids {
                dataModel.updateItem(id: id) { item in
                    item.isExport = false
                }
            }
        }
        
        // Delay 3 seconds
        try? await Task.sleep(nanoseconds: 3 * 1_000_000_000)

        // Then set saveToggled = false on main thread
        await MainActor.run {
            ImageViewModel.shared.saveToggled = false
            for id in ids {
                dataModel.updateItem(id: id) { item in
                    item.isSaved = false
                }
            }
        }

        print("batchSave complete: \(items.count) items processed")
    }

    
    
    private func saveImageTiff(
        _ item: ImageItem,
        _ image: CIImage,
        _ originalUrl: URL,
        _ saveDestination: URL,
        _ context: CIContext
    ) async {
        await Task(priority: .userInitiated) {
            let width = image.extent.width
            let height = image.extent.height
            let outputColorSpace = CGColorSpace(name: CGColorSpace.adobeRGB1998)!
            let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
            
            guard let cgImage = context.createCGImage(image, from: image.extent) else {
                print("Failed to create CGImage.")
                return
            }
            
            guard let cgContext = CGContext(
                data: nil,
                width: Int(width),
                height: Int(height),
                bitsPerComponent: item.bitDepth,
                bytesPerRow: 0,
                space: outputColorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                print("Failed to create CGContext.")
                return
            }
            
            cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
            
            guard let outputCGImage = cgContext.makeImage() else {
                print("Failed to create output CGImage.")
                return
            }
            
            // Get safe, sanitized filename
            let originalFilename = originalUrl.deletingPathExtension().lastPathComponent
            let safeFilename = originalFilename
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: ":", with: "_") + ".tiff"
            
            let outputFileURL: URL
            if (try? saveDestination.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                outputFileURL = saveDestination.appendingPathComponent(safeFilename)
            } else {
                outputFileURL = saveDestination
            }
            
            // Prepare TIFF output with DPI settings
            let dpi: Int = 300
            var properties: [CFString: Any] = [
                kCGImagePropertyDPIWidth: dpi,
                kCGImagePropertyDPIHeight: dpi,
                kCGImagePropertyTIFFDictionary: [:]
            ]
            
            if let exif = item.exifDict {
                properties[kCGImagePropertyExifDictionary] = exif
            }
            if let gps = item.gpsDict {
                properties[kCGImagePropertyGPSDictionary] = gps
            }
            if let iptc = item.iptcDict {
                properties[kCGImagePropertyIPTCDictionary] = iptc
            }
            
            let mutableData = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(mutableData, kUTTypeTIFF, 1, nil) else {
                print("Failed to create CGImageDestination")
                return
            }
            
            CGImageDestinationAddImage(destination, outputCGImage, properties as CFDictionary)
            
            if CGImageDestinationFinalize(destination) {
                do {
                    try mutableData.write(to: outputFileURL, options: .atomic)
                    print("Saved TIFF image to: \(outputFileURL.path)")
                } catch {
                    print("Failed to write TIFF file: \(error)")
                }
            } else {
                print("Failed to finalize image destination.")
            }
        }.value
    }
    
    
}
