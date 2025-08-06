//
//  SaveNodes.swift
//  ColorForge
//
//  Created by admin on 12/06/2025.
//

import Foundation
import CoreImage
import CoreGraphics
import AppKit
import ImageIO
import UniformTypeIdentifiers

func saveImage(_ item: ImageItem, _ image: CIImage, _ originalUrl: URL, _ saveDestination: URL) {


    
    DispatchQueue.global(qos: .userInitiated).async {
        let context = RenderingManager.shared.exportContext
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
            bitsPerComponent: 16,
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

        // Prepare TIFF output with DPI settings using CGImageDestination
        let dpi: Int = 300
        
        var properties: [CFString: Any] = [
            kCGImagePropertyDPIWidth: dpi,
            kCGImagePropertyDPIHeight: dpi
        ]

        // Always include an empty TIFF dictionary (required)
        properties[kCGImagePropertyTIFFDictionary] = [:]

        // Conditionally include metadata if present
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
    }
}

//public func saveImage(_ image: CIImage, _ originalUrl: URL, _ saveDestination: URL) {
//	DispatchQueue.global(qos: .userInitiated).async {
//		let context = RenderingManager.shared.exportContext
//		let width = image.extent.width
//		let height = image.extent.height
//		let outputColorSpace = CGColorSpace(name: CGColorSpace.adobeRGB1998)!
//		let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
//
//		guard let cgImage = context.createCGImage(image, from: image.extent) else {
//			print("Failed to create CGImage.")
//			return
//		}
//
//		guard let cgContext = CGContext(
//			data: nil,
//			width: Int(width),
//			height: Int(height),
//			bitsPerComponent: 16,
//			bytesPerRow: 0,
//			space: outputColorSpace,
//			bitmapInfo: bitmapInfo.rawValue,
//
//		) else {
//			print("Failed to create CGContext.")
//			return
//		}
//
//		cgContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
//
//		guard let outputCGImage = cgContext.makeImage() else {
//			print("Failed to create output CGImage.")
//			return
//		}
//
//		let bitmapRep = NSBitmapImageRep(cgImage: outputCGImage)
//		let fileType: NSBitmapImageRep.FileType = .tiff
//		let fileProperties: [NSBitmapImageRep.PropertyKey: Any] = [:]
//        
//        
//
//		guard let fileData = bitmapRep.representation(using: fileType, properties: fileProperties) else {
//			print("Failed to create file data from CGImage.")
//			return
//		}
//
//        // Get safe, sanitized filename
//        let originalFilename = originalUrl.deletingPathExtension().lastPathComponent
//        let safeFilename = originalFilename
//            .replacingOccurrences(of: "/", with: "_")
//            .replacingOccurrences(of: ":", with: "_") + ".tiff"
//
//        let outputFileURL: URL
//        if (try? saveDestination.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
//            outputFileURL = saveDestination.appendingPathComponent(safeFilename)
//        } else {
//            outputFileURL = saveDestination
//        }
//
//		do {
//			try fileData.write(to: outputFileURL)
//			print("Saved TIFF image to: \(outputFileURL.path)")
//		} catch {
//			print("Failed to save TIFF image: \(error)")
//		}
//	}
//}


public func debugSave(_ image: CIImage, _ suffix: String) {
	DispatchQueue.global(qos: .userInitiated).async {
		let context = RenderingManager.shared.lutContext

		let width = image.extent.width
		let height = image.extent.height
		let outputColorSpace = CGColorSpace(name: CGColorSpace.adobeRGB1998)!
        let colorSpace = CGColorSpace(name: CGColorSpace.rommrgb)!
        let deviceRGB = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)

		guard let cgImage = context.createCGImage(image, from: image.extent) else {
			print("Failed to create CGImage.")
			return
		}

		guard let cgContext = CGContext(
			data: nil,
			width: Int(width),
			height: Int(height),
			bitsPerComponent: 16,
			bytesPerRow: 0,
			space: deviceRGB,
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

		let bitmapRep = NSBitmapImageRep(cgImage: outputCGImage)
		let fileType: NSBitmapImageRep.FileType = .tiff
		let fileProperties: [NSBitmapImageRep.PropertyKey: Any] = [:]

		guard let fileData = bitmapRep.representation(using: fileType, properties: fileProperties) else {
			print("Failed to create file data from CGImage.")
			return
		}

		let fileManager = FileManager.default
		let sandboxURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
		let outputFolderURL = sandboxURL.appendingPathComponent("DebugOutput")

		// Ensure directory exists
		do {
			try fileManager.createDirectory(at: outputFolderURL, withIntermediateDirectories: true, attributes: nil)
		} catch {
			print("Failed to create debug output directory: \(error)")
			return
		}

		// Find next available debugNNN.tiff filename
		let existingFiles = (try? fileManager.contentsOfDirectory(at: outputFolderURL, includingPropertiesForKeys: nil)) ?? []
		let existingNumbers = existingFiles.compactMap { url -> Int? in
			let name = url.deletingPathExtension().lastPathComponent
			let pattern = #"^debug(\d{3})$"#
			if let match = name.range(of: pattern, options: .regularExpression) {
				return Int(name.suffix(3))
			}
			return nil
		}
		let nextNumber = (existingNumbers.max() ?? 0) + 1
		let numberStr = String(format: "%03d", nextNumber)
        let cleanSuffix = suffix.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffixPart = cleanSuffix.isEmpty ? "" : "_\(cleanSuffix)"
        let outputFilename = "debug\(numberStr)\(suffixPart).tiff"
		let outputFileURL = outputFolderURL.appendingPathComponent(outputFilename)

		// Write the file
		do {
			try fileData.write(to: outputFileURL)
			print("Saved TIFF image to: \(outputFileURL.path)")
		} catch {
			print("Failed to save TIFF image: \(error)")
		}
	}
}

public func saveImage32BitDebug(_ image: CIImage) {
    let context = CIContext(options: [
        .outputPremultiplied: false,
        .useSoftwareRenderer: false
    ])

    let width = Int(image.extent.width)
    let height = Int(image.extent.height)
    let rowBytes = width * 4 * MemoryLayout<Float>.size // 4 channels × float

    let byteCount = rowBytes * height
    let rawData = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: MemoryLayout<Float>.alignment)
    defer { rawData.deallocate() }

    let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!

    context.render(
        image,
        toBitmap: rawData,
        rowBytes: rowBytes,
        bounds: image.extent,
        format: .RGBAf,
        colorSpace: colorSpace
    )

    guard let provider = CGDataProvider(dataInfo: nil, data: rawData, size: byteCount, releaseData: { _,_,_ in }) else {
        print("Failed to create data provider.")
        return
    }

    guard let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 32,
        bitsPerPixel: 128,
        bytesPerRow: rowBytes,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    ) else {
        print("Failed to create CGImage.")
        return
    }

    let fileManager = FileManager.default
    let sandboxURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    let outputFolderURL = sandboxURL.appendingPathComponent("DebugOutput")

    do {
        try fileManager.createDirectory(at: outputFolderURL, withIntermediateDirectories: true, attributes: nil)

        // Find next available debugNNN_32bit.tiff filename
        let existingFiles = (try? fileManager.contentsOfDirectory(at: outputFolderURL, includingPropertiesForKeys: nil)) ?? []
        let existingNumbers = existingFiles.compactMap { url -> Int? in
            let name = url.deletingPathExtension().lastPathComponent
            let pattern = #"^debug(\d{3})(?:_32bit)?$"#
            if let match = name.range(of: pattern, options: .regularExpression) {
                return Int(name[match].suffix(3))
            }
            return nil
        }
        let nextNumber = (existingNumbers.max() ?? 0) + 1
        let numberStr = String(format: "%03d", nextNumber)
        let outputFileURL = outputFolderURL.appendingPathComponent("debug\(numberStr)_32bit.tiff")

        guard let dest = CGImageDestinationCreateWithURL(outputFileURL as CFURL, UTType.tiff.identifier as CFString, 1, nil) else {
            print("Failed to create TIFF destination.")
            return
        }

        CGImageDestinationAddImage(dest, cgImage, [
            kCGImagePropertyTIFFCompression as String: 1
        ] as CFDictionary)

        if CGImageDestinationFinalize(dest) {
            print("Saved 32-bit TIFF to: \(outputFileURL.path)")
        } else {
            print("Failed to finalize TIFF image.")
        }
    } catch {
        print("Failed to save TIFF image: \(error)")
    }
}

public func saveImage32BitFloat(_ image: CIImage) {
	let context = CIContext(options: [
		.outputPremultiplied: false,
		.useSoftwareRenderer: false
	])

	let width = Int(image.extent.width)
	let height = Int(image.extent.height)
	let rowBytes = width * 4 * MemoryLayout<Float>.size // 4 channels x float

	// Create raw buffer
	let byteCount = rowBytes * height
	let rawData = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: MemoryLayout<Float>.alignment)
	defer { rawData.deallocate() }

	let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB)!

	// Render to float buffer
	context.render(
		image,
		toBitmap: rawData,
		rowBytes: rowBytes,
		bounds: image.extent,
		format: .RGBAf,
		colorSpace: colorSpace
	)

	// Create CGDataProvider
	guard let provider = CGDataProvider(dataInfo: nil, data: rawData, size: byteCount, releaseData: { _,_,_ in }) else {
		print("Failed to create data provider.")
		return
	}

	// Create CGImage manually from buffer
	guard let cgImage = CGImage(
		width: width,
		height: height,
		bitsPerComponent: 32,
		bitsPerPixel: 128,
		bytesPerRow: rowBytes,
		space: colorSpace,
		bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
		provider: provider,
		decode: nil,
		shouldInterpolate: false,
		intent: .defaultIntent
	) else {
		print("Failed to create CGImage.")
		return
	}

	// Write TIFF using Image I/O
	let fileManager = FileManager.default
	let sandboxURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
	let outputFolderURL = sandboxURL.appendingPathComponent("UnitTestOutput")
	let outputFileURL = outputFolderURL.appendingPathComponent("unitTest_float32.tiff")

	do {
		try fileManager.createDirectory(at: outputFolderURL, withIntermediateDirectories: true, attributes: nil)

		guard let dest = CGImageDestinationCreateWithURL(outputFileURL as CFURL, UTType.tiff.identifier as CFString, 1, nil) else {
			print("Failed to create TIFF destination.")
			return
		}

		CGImageDestinationAddImage(dest, cgImage, [
			kCGImagePropertyTIFFCompression as String: 1, // No compression
		] as CFDictionary)

		if CGImageDestinationFinalize(dest) {
			print("Saved 32-bit TIFF to: \(outputFileURL.path)")
		} else {
			print("Failed to finalize TIFF image.")
		}
	} catch {
		print("Failed to save TIFF image: \(error)")
	}
}
