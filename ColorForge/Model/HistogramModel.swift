//
//  HistogramModel.swift
//  ColorForge
//
//  Created by Ben Quinton on 04/08/2025.
//

import Foundation
import CoreImage
import SwiftUI
import CoreGraphics

struct HistogramBin: Identifiable {
    let id: Int       // the bin index (0–255)
    let value: Int    // the pixel count
}


class HistogramModel: ObservableObject {
    static let shared = HistogramModel()
    
    @Published var red: [HistogramBin] = []
    @Published var green: [HistogramBin] = []
    @Published var blue: [HistogramBin] = []
    @Published var luminance: [HistogramBin] = []
    
    
    private var debounceTask: Task<Void, Never>?
    private var processingTask: Task<Void, Never>? // <- track active histogram generation

    func generateDataDebounced(_ input: CIImage) {
        debounceTask?.cancel()

        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard !Task.isCancelled else { return }
            self?.generateData(input)
        }
    }
    

    func generateData(_ input: CIImage) {

        processingTask?.cancel()

        processingTask = Task(priority: .userInitiated) {
            let startTime = DispatchTime.now()
            
            let rgbaBins = histogramBin(input)


            guard !Task.isCancelled else { return }

            let buffer = await self.convertToPixelBuffer(rgbaBins)

            guard !Task.isCancelled else { return }

            async let redBins = self.histogramBins(buffer, channel: 0)
            async let greenBins = self.histogramBins(buffer, channel: 1)
            async let blueBins = self.histogramBins(buffer, channel: 2)
            async let lumBins = self.histogramBins(buffer, channel: 3)

            let (r, g, b, y) = await (redBins, greenBins, blueBins, lumBins)

            guard !Task.isCancelled else { return }

            let binCount = r.count
            let binWidth = 256.0 / Double(binCount)

            let redMapped = r.enumerated().map { HistogramBin(id: Int(Double($0.offset) * binWidth), value: $0.element) }
            let greenMapped = g.enumerated().map { HistogramBin(id: Int(Double($0.offset) * binWidth), value: $0.element) }
            let blueMapped = b.enumerated().map { HistogramBin(id: Int(Double($0.offset) * binWidth), value: $0.element) }
            let lumMapped = y.enumerated().map { HistogramBin(id: Int(Double($0.offset) * binWidth), value: $0.element) }


            await MainActor.run {
                self.red = redMapped
                self.green = greenMapped
                self.blue = blueMapped
                self.luminance = lumMapped

                let endTime = DispatchTime.now()
                let elapsed = Double(endTime.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000
            }
        }
    }
    
    func histogramBin(_ input: CIImage) -> CIImage {
        let filter = CIFilter.areaHistogram()
        filter.inputImage = input
        filter.count = 32
        filter.scale = 256
        filter.extent = input.extent
        guard let output = filter.outputImage else { return input }
        
        return output
    }

    func histogramBins(_ buffer: CVPixelBuffer, channel: Int) async -> [Int] {
        precondition(channel >= 0 && channel <= 3, "Channel must be 0 (R), 1 (G), 2 (B), or 3 (Luminance)")
        
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

        guard CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_128RGBAFloat else {
            fatalError("Unsupported pixel format. Expected 128-bit RGBA float.")
        }

        let width = CVPixelBufferGetWidth(buffer) // ← binCount
        let baseAddress = CVPixelBufferGetBaseAddress(buffer)!.assumingMemoryBound(to: Float.self)
        let floatsPerPixel = 4 // RGBA

        var bins = [Int](repeating: 0, count: width)

        for i in 0..<width {
            let offset = i * floatsPerPixel

            let r = baseAddress[offset + 0]
            let g = baseAddress[offset + 1]
            let b = baseAddress[offset + 2]

            let value: Float = switch channel {
            case 0: r
            case 1: g
            case 2: b
            case 3: 0.2126 * r + 0.7152 * g + 0.0722 * b
            default: 0
            }

            bins[i] = Int(value)
        }

        return bins
    }
    
    
   private func convertToPixelBuffer(_ image: CIImage) async -> CVPixelBuffer {
        
        let backgroundContext = RenderingManager.shared.scopeContext
        
        let width = Int(image.extent.width)
        let height = Int(image.extent.height)

        let attrs: [CFString: Any] = [
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_128RGBAFloat, // matches RGBAf format
            attrs as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            fatalError("Failed to create CVPixelBuffer")
        }

        // Lock base address for writing
        CVPixelBufferLockBaseAddress(buffer, [])
        backgroundContext.render(image, to: buffer, bounds: image.extent, colorSpace: nil)
        CVPixelBufferUnlockBaseAddress(buffer, [])


        return buffer
    }
}
