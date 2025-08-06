//
//  LutModel.swift
//  ColorForge
//
//  Created by admin on 27/05/2025.
//

import Foundation
import Accelerate
import CoreImage
import CoreVideo
import CoreImage.CIFilterBuiltins
import CoreGraphics
import simd


class LutModel {
	static let shared = LutModel()
	
	// MARK: - Init
	
	init() {
		loadLUTOnInitialization()
        createRamps()
	}
	
    // Ramps to be used to create inverse curves to be applied to the gradients for masking
    public var rawExposureRamp: CIImage?
    public var rawContrastRamp: CIImage?
    public var rawSaturationRamp: CIImage?
    public var HDRRamp: CIImage?
    public var HSDRamp: CIImage?
    
    
    public var enlargerRamp: CIImage?
    public var enlargerInverseData: Data?
    
    func createRamps() {
        let ramp = createLinearRamp(steps: 32)
        
        rawExposureRamp = ramp
        rawContrastRamp = ramp
        rawSaturationRamp = ramp
        HDRRamp = ramp
        HSDRamp = ramp
        enlargerRamp = ramp
    }
    
    
    
	private var isLUTLoaded = false
	private var cubeData: Data?
	private var cubeDimension: Float = 0.0
	public var cubeDataCache = [String: CachedLUTData]()
	
	public struct CachedLUTData {
		let data: Data
		let dimension: Float
	}
	
	public func getCachedLUT(named name: String) -> CachedLUTData? {
		return cubeDataCache[name]
	}
	
	// MARK: - Load lut on init
	
	public func loadLUTOnInitialization() {
		let dispatchGroup = DispatchGroup()
		
		let lutNames = [
			"NegToPrintGamut",
			"Pentax_P400_Oct24",
			"Pentax645Z_P400_Plus1",
			"Pentax645Z_P400_Plus2",
			"Pentax645ZGold",
			"Pentax645z_to_Tmax",
			"ImaconScan(negative)_to_NoritsuScan(positive)_AdobeRGBOUT",
			"LVT_neg_to_print", // Too desaturated
			"LVT_sRGB_Neg_to_Print", // Ok
			"PrintGamutJune25", // Trying this combined with new outputmap
			"PrintJune2025",
            "CaptureOneInput",
            "FPC2N",
            "FPN2P",
            "FPRefineRGB",
			"PipelineV3",
			"Pipeline",
            "2383v2",
            "3513v2"
			
		]
		
		for lutName in lutNames {
			dispatchGroup.enter()
			loadLUTData(from: lutName) {
				print("\(lutName) data cached on initialization.")
				dispatchGroup.leave()
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			print("All LUTs have been cached successfully.")
		}
	}
	
	// MARK: - Lut Data loading functions
	
	/// Loads luts from data
	private func loadLUTData(from resourceName: String, completion: @escaping () -> Void) {
		DispatchQueue.global(qos: .userInitiated).async {
			let bundle = Bundle(for: type(of: self))
			
			let resourceNameWithExtension = resourceName.hasSuffix(".data") ? resourceName : "\(resourceName).data"
			
			guard let lutURL = bundle.url(forResource: resourceNameWithExtension, withExtension: nil) else {
				print("Failed to find LUT file: \(resourceNameWithExtension)")
				DispatchQueue.main.async {
					completion()
				}
				return
			}
			
			print("LUT Data file found at \(lutURL)")
			
			// Load LUT data file
			guard let lutData = try? Data(contentsOf: lutURL) else {
				print("Failed to load LUT Data file contents: \(lutURL)")
				DispatchQueue.main.async {
					completion()
				}
				return
			}
			
			// Safely update cache on the main thread
			DispatchQueue.main.async {
				self.cubeDataCache[resourceName] = CachedLUTData(data: lutData, dimension: 32.0)
				print("LUT Data loaded successfully: \(resourceName), Dimension: 32.0")
				completion()
			}
		}
	}
	
	
	
	// MARK: - Generate Hald Image

    
    // Async wrapper
    public func generateFloatCubeImageAsync(size cubeSize: Int) async -> CIImage? {
        await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let start = DispatchTime.now()
                
                let image = self.generateFloatCubeImage(size: cubeSize)
                
                let end = DispatchTime.now()
                let elapsed = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                print("Cube image generation took \(elapsed) ms")

                continuation.resume(returning: image)
            }
        }
    }
    

    /// Accepts cube sizes of the below:
    /// 4
    /// 16
    /// 32
    /// 64
    /// 256
    public func generateFloatCubeImage(size cubeSize: Int) -> CIImage? {
        
        let pixels = cubeSize * cubeSize * cubeSize
        let width = cubeSize * cubeSize
        let height = cubeSize
        let channels = 3
        
        let memorySize = pixels * channels * MemoryLayout<Float32>.size
        let cubeSizeSquared = cubeSize * cubeSize
        let colorStep = 1.0 / Float(cubeSize - 1)
        
        // Allocate buffer for RGB float32 values
        let imageBuffer = UnsafeMutablePointer<Float32>.allocate(capacity: pixels * channels)
        defer { imageBuffer.deallocate() }
        
        for i in 0..<pixels {
            let offset = i * channels
            imageBuffer[offset + 0] = Float32(i % cubeSize) * colorStep     // R
            imageBuffer[offset + 1] = Float32((i / cubeSize) % cubeSize) * colorStep  // G
            imageBuffer[offset + 2] = Float32(i / cubeSizeSquared) * colorStep        // B
        }

        // Create pixel buffer with 4-channel RGBA float format (we'll pad alpha)
        var pixelBuffer: CVPixelBuffer?
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_128RGBAFloat, // 4x32-bit float = 128 bits
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            return nil
        }

        let rowStride = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<Float32>.size
        let bufferPtr = baseAddress.assumingMemoryBound(to: Float32.self)

        for y in 0..<height {
            for x in 0..<width {
                let flatIndex = y * width + x
                let rgbIndex = flatIndex * channels
                let pixelIndex = y * rowStride + x * 4 // 4 channels in destination buffer

                bufferPtr[pixelIndex + 0] = imageBuffer[rgbIndex + 0] // R
                bufferPtr[pixelIndex + 1] = imageBuffer[rgbIndex + 1] // G
                bufferPtr[pixelIndex + 2] = imageBuffer[rgbIndex + 2] // B
                bufferPtr[pixelIndex + 3] = 1.0 // A (unused)
            }
        }
		

        return CIImage(cvPixelBuffer: buffer)
    }
 
    
	// MARK: - Read Hald Image
	// Main function for reading data
    public func readCubeData(from ciImage: CIImage, size cubeSize: Int) -> Data? {
        let context = RenderingManager.shared.backgroundContext
        
        let width = cubeSize * cubeSize
        let height = cubeSize
        let channels = 4 // RGBA

        // Create a 128-bit float pixel buffer from the CIImage
        let attrs = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_128RGBAFloat,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height
        ] as CFDictionary

        var pixelBuffer: CVPixelBuffer?
        let pixelBufferStatus = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_128RGBAFloat,
            attrs,
            &pixelBuffer
        )

        guard pixelBufferStatus == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("❌ Failed to create pixel buffer for reading")
            return nil
        }
        
        let boundsRect = CGRect(x: 0, y: 0, width: width, height: height)
        
//        let cubeSpace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!
//		let cubeSpace = CGColorSpaceCreateDeviceRGB()
		let adobeRGBColorSpace = CGColorSpace(name: CGColorSpace.adobeRGB1998)!

        // Render CIImage into pixel buffer (avoids clamping!)
        context.render(ciImage, to: buffer, bounds: boundsRect, colorSpace: nil)

        // Read back float RGBA values
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            print("❌ Could not lock base address")
            return nil
        }

        let rowStride = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<Float32>.size
        let bufferPtr = baseAddress.assumingMemoryBound(to: Float32.self)

        // CIColorCube requires data in [b][g][r] order, r fastest
        var cubeData: [Float32] = []

        for b in 0..<cubeSize {
            for g in 0..<cubeSize {
                for r in 0..<cubeSize {
                    let x = r + g * cubeSize
                    let y = b

                    let pixelIndex = y * rowStride + x * 4
                    let red   = bufferPtr[pixelIndex + 0]
                    let green = bufferPtr[pixelIndex + 1]
                    let blue  = bufferPtr[pixelIndex + 2]
                    let alpha = bufferPtr[pixelIndex + 3]

                    cubeData.append(contentsOf: [red, green, blue, alpha])
                }
            }
        }
        
        let finalData = Data(bytes: cubeData, count: cubeData.count * MemoryLayout<Float32>.size)


        return finalData
    }
    
    
	// MARK: - Output NSData To Text
	
    // Debug output
    func saveCubeDataAsText(_ data: Data, to filename: String = "cube_dump.txt") {
        let floatCount = data.count / MemoryLayout<Float32>.size
        guard floatCount % 4 == 0 else {
            print("❌ Data length is not a multiple of 4 floats (RGBA)")
            return
        }

        let floatPtr = data.withUnsafeBytes { $0.bindMemory(to: Float32.self) }

        var output = ""
        for i in 0..<floatCount/4 {
            let r = floatPtr[i * 4 + 0]
            let g = floatPtr[i * 4 + 1]
            let b = floatPtr[i * 4 + 2]
            let a = floatPtr[i * 4 + 3]
            output += "\(r) \(g) \(b) \(a)\n"
        }

        do {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(filename)
            try output.write(to: url, atomically: true, encoding: .utf8)
            print("Cube data written to: \(url.path)")
        } catch {
            print("Failed to save cube data to file: \(error)")
        }
    }
    
	
	// MARK: - Save NSData as .cube
    
    func saveCubeDataAsCubeFile(_ data: Data, cubeDimension: Int = 64, _ filename: String) {
        let floatCount = data.count / MemoryLayout<Float32>.size
        guard floatCount % 4 == 0 else {
            print("❌ Data length is not a multiple of 4 floats (RGBA)")
            return
        }

        let floatPtr = data.withUnsafeBytes { $0.bindMemory(to: Float32.self) }

        var cubeFileContent = "TITLE \"Exported LUT\"\nLUT_3D_SIZE \(cubeDimension)\n\n"

        for z in 0..<cubeDimension {
            for y in 0..<cubeDimension {
                for x in 0..<cubeDimension {
                    let i = z * (cubeDimension * cubeDimension) + y * cubeDimension + x
                    let r = floatPtr[i * 4 + 0]
                    let g = floatPtr[i * 4 + 1]
                    let b = floatPtr[i * 4 + 2]
                    cubeFileContent += "\(r) \(g) \(b)\n"
                }
            }
        }

        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let baseName = filename.replacingOccurrences(of: ".cube", with: "")
        var uniqueName = baseName
        var counter = 1
        var outputURL = documentsURL.appendingPathComponent("\(uniqueName).cube")

        while fileManager.fileExists(atPath: outputURL.path) {
            uniqueName = "\(baseName)_\(counter)"
            outputURL = documentsURL.appendingPathComponent("\(uniqueName).cube")
            counter += 1
        }

        do {
            try cubeFileContent.write(to: outputURL, atomically: true, encoding: .utf8)
            print("Cube file successfully saved to: \(outputURL.path)")
        } catch {
            print("Failed to save cube file: \(error)")
        }
    }
	
	

	
	// MARK: - Interpolate two luts (transform lut)
	
	func generateTransformLUT( _ sourceLUT: CIImage, _ targetLUT: CIImage, _ identityLut: CIImage, _ convertToLAB: Bool) -> Data? {
		
		var sLut = sourceLUT.Lin2LogC()
		var tLut = targetLUT.Lin2LogC()
		var id = identityLut.Lin2LogC()
		
		
		let kernel = CIColorKernelCache.shared.transformLut

		// Step 5: Apply kernel
		guard let result = kernel.apply(
			extent: sourceLUT.extent,
			roiCallback: { _, rect in rect },
			arguments: [sLut, tLut, id]
		) else {
			print("Failed to transform lut kernel")
			return nil
		}
		
		
		let resultNorm = result.LogC2Lin()
		
		guard let transformData = readCubeData(from: resultNorm, size: 64) else { return nil }
		
		return transformData
	}
	
	
	// MARK: - 1D Lut Logic
	
	// used for 1D lut generation
	public func createLinearRamp(steps: Int) -> CIImage? {
		guard steps >= 2 else { return nil }

		let width = steps
		let height = 1
		let channels = 3
		let memorySize = steps * channels * MemoryLayout<Float32>.size

		// Allocate buffer for RGB float32 values
		let imageBuffer = UnsafeMutablePointer<Float32>.allocate(capacity: steps * channels)
		defer { imageBuffer.deallocate() }

		let colorStep = 1.0 / Float(steps - 1)

		for i in 0..<steps {
			let value = Float32(i) * colorStep
			let offset = i * channels
			imageBuffer[offset + 0] = value // R
			imageBuffer[offset + 1] = value // G
			imageBuffer[offset + 2] = value // B
		}

		// Create pixel buffer with 4-channel RGBA float format
		var pixelBuffer: CVPixelBuffer?
		let attrs = [
			kCVPixelBufferCGImageCompatibilityKey: true,
			kCVPixelBufferCGBitmapContextCompatibilityKey: true
		] as CFDictionary

		let status = CVPixelBufferCreate(
			kCFAllocatorDefault,
			width,
			height,
			kCVPixelFormatType_128RGBAFloat,
			attrs,
			&pixelBuffer
		)

		guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
			return nil
		}

		CVPixelBufferLockBaseAddress(buffer, [])
		defer { CVPixelBufferUnlockBaseAddress(buffer, []) }

		guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
			return nil
		}

		let rowStride = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<Float32>.size
		let bufferPtr = baseAddress.assumingMemoryBound(to: Float32.self)

		for x in 0..<width {
			let rgbIndex = x * channels
			let pixelIndex = x * 4 // 4 channels

			bufferPtr[pixelIndex + 0] = imageBuffer[rgbIndex + 0] // R
			bufferPtr[pixelIndex + 1] = imageBuffer[rgbIndex + 1] // G
			bufferPtr[pixelIndex + 2] = imageBuffer[rgbIndex + 2] // B
			bufferPtr[pixelIndex + 3] = 1.0 // A
		}

		return CIImage(cvPixelBuffer: buffer)
	}
	
	
	// Sample Ramp
	public func sampleRampData(_ rampImage: CIImage, floatingPoint: Bool) -> Data? {
		let context = RenderingManager.shared.lutContext

		let width = Int(rampImage.extent.width)
		let height = 1

		let pixelFormat: OSType = floatingPoint ? kCVPixelFormatType_128RGBAFloat : kCVPixelFormatType_64RGBAHalf

		var pixelBuffer: CVPixelBuffer?
		let attrs: CFDictionary = [
			kCVPixelBufferPixelFormatTypeKey: pixelFormat,
			kCVPixelBufferWidthKey: width,
			kCVPixelBufferHeightKey: height,
			kCVPixelBufferCGImageCompatibilityKey: true,
			kCVPixelBufferCGBitmapContextCompatibilityKey: true
		] as CFDictionary

		let status = CVPixelBufferCreate(
			kCFAllocatorDefault,
			width,
			height,
			pixelFormat,
			attrs,
			&pixelBuffer
		)

		guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
			print("❌ Failed to create pixel buffer")
			return nil
		}

		let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!
		context.render(rampImage, to: buffer, bounds: rampImage.extent, colorSpace: colorSpace)

		CVPixelBufferLockBaseAddress(buffer, .readOnly)
		defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

		guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
			print("❌ Failed to get base address")
			return nil
		}

		if floatingPoint {
			let bufferPtr = baseAddress.assumingMemoryBound(to: Float32.self)
			let rowStride = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<Float32>.size

			var floatData: [Float32] = []

			for x in 0..<width {
				let pixelIndex = x * 4 // RGBA
				let r = bufferPtr[pixelIndex + 0]
				let g = bufferPtr[pixelIndex + 1]
				let b = bufferPtr[pixelIndex + 2]
				floatData.append(r)
				floatData.append(g)
				floatData.append(b)
			}

			return Data(bytes: floatData, count: floatData.count * MemoryLayout<Float32>.size)
		} else {
			// Not used for `curvesData`, but included for completeness
			let bufferPtr = baseAddress.assumingMemoryBound(to: UInt16.self)
			let rowStride = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<UInt16>.size

			var intData: [UInt16] = []

			for x in 0..<width {
				let pixelIndex = x * 4
				intData.append(bufferPtr[pixelIndex + 0]) // R
				intData.append(bufferPtr[pixelIndex + 1]) // G
				intData.append(bufferPtr[pixelIndex + 2]) // B
			}
			
			return Data(bytes: intData, count: intData.count * MemoryLayout<UInt16>.size)
		}
	}
    
    public func sampleRampDataAverage(_ rampImage: CIImage, floatingPoint: Bool) -> Data? {
        let context = RenderingManager.shared.lutContext

        let width = Int(rampImage.extent.width)
        let height = 1

        let pixelFormat: OSType = floatingPoint ? kCVPixelFormatType_128RGBAFloat : kCVPixelFormatType_64RGBAHalf

        var pixelBuffer: CVPixelBuffer?
        let attrs: CFDictionary = [
            kCVPixelBufferPixelFormatTypeKey: pixelFormat,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ] as CFDictionary

        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            pixelFormat,
            attrs,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            print("❌ Failed to create pixel buffer")
            return nil
        }

        let colorSpace = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!
        context.render(rampImage, to: buffer, bounds: rampImage.extent, colorSpace: colorSpace)

        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }

        guard let baseAddress = CVPixelBufferGetBaseAddress(buffer) else {
            print("❌ Failed to get base address")
            return nil
        }

        if floatingPoint {
            let bufferPtr = baseAddress.assumingMemoryBound(to: Float32.self)
            let rowStride = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<Float32>.size

            var floatData: [Float32] = []

            for x in 0..<width {
                let pixelIndex = x * 4 // RGBA
                let r = bufferPtr[pixelIndex + 0]
                let g = bufferPtr[pixelIndex + 1]
                let b = bufferPtr[pixelIndex + 2]
                let average = (r + g + b) / 3.0
                floatData.append(average)
                floatData.append(average)
                floatData.append(average)
            }

            return Data(bytes: floatData, count: floatData.count * MemoryLayout<Float32>.size)
        } else {
            // Not used for `curvesData`, but included for completeness
            let bufferPtr = baseAddress.assumingMemoryBound(to: UInt16.self)
            let rowStride = CVPixelBufferGetBytesPerRow(buffer) / MemoryLayout<UInt16>.size

            var intData: [UInt16] = []

            for x in 0..<width {
                let pixelIndex = x * 4
                intData.append(bufferPtr[pixelIndex + 0]) // R
                intData.append(bufferPtr[pixelIndex + 1]) // G
                intData.append(bufferPtr[pixelIndex + 2]) // B
            }
            
            return Data(bytes: intData, count: intData.count * MemoryLayout<UInt16>.size)
        }
    }
    
    
    func sampleRampAndReverse(_ baseRamp: CIImage, _ editedRamp: CIImage) -> Data? {
        // Get base (linear) ramp and edited ramp data
        guard let baseData = sampleRampDataAverage(baseRamp, floatingPoint: true) else { return nil }
        guard let editedData = sampleRampDataAverage(editedRamp, floatingPoint: true) else { return nil }
        
        let baseFloats: [Float32] = baseData.withUnsafeBytes {
            Array($0.bindMemory(to: Float32.self))
        }

        let editedFloats: [Float32] = editedData.withUnsafeBytes {
            Array($0.bindMemory(to: Float32.self))
        }
        
        // Ensure both are the same size (should both be width*3 values)
        guard baseFloats.count == editedFloats.count else {
            print("Ramp size mismatch")
            return nil
        }
        
        // Calculate difference curve: base + (edited - base) = edited * 1 + base * 0 (but as per spec)
        var difference: [Float32] = []
        difference.reserveCapacity(baseFloats.count)
        
        for i in 0..<baseFloats.count {
            let delta = editedFloats[i] - baseFloats[i]
            let diffValue = baseFloats[i] + delta  // This just equals edited[i] mathematically
            difference.append(diffValue)
        }
        
        var differenceData = Data(bytes: difference, count: difference.count * MemoryLayout<Float32>.size)
        
        
        differenceData = smoothCurvePoints(differenceData, 2)

        return differenceData
    }
    
	
	// MARK: - Smooth 3D lut
	
	func smooth3DLUT(_ data: Data, cubeSize: Int) -> Data {
		let floats = data.withUnsafeBytes { ptr in
			Array(ptr.bindMemory(to: Float32.self))
		}

		let countPerPixel = 4 // RGBA
		let totalPixels = cubeSize * cubeSize * cubeSize
		guard floats.count == totalPixels * countPerPixel else {
			print("Invalid LUT data size")
			return data
		}

		var smoothed = [Float32](repeating: 0, count: floats.count)

		let index = { (r: Int, g: Int, b: Int) -> Int in
			return b * cubeSize * cubeSize + g * cubeSize + r
		}

		for b in 0..<cubeSize {
			for g in 0..<cubeSize {
				for r in 0..<cubeSize {
					var sumR: Float32 = 0
					var sumG: Float32 = 0
					var sumB: Float32 = 0
					var count: Float32 = 0

					for dz in -1...1 {
						for dy in -1...1 {
							for dx in -1...1 {
								let rr = r + dx
								let gg = g + dy
								let bb = b + dz

								if rr >= 0, rr < cubeSize, gg >= 0, gg < cubeSize, bb >= 0, bb < cubeSize {
									let i = index(rr, gg, bb) * 4
									sumR += floats[i + 0]
									sumG += floats[i + 1]
									sumB += floats[i + 2]
									count += 1
								}
							}
						}
					}

					let dstIndex = index(r, g, b) * 4
					smoothed[dstIndex + 0] = sumR / count
					smoothed[dstIndex + 1] = sumG / count
					smoothed[dstIndex + 2] = sumB / count
					smoothed[dstIndex + 3] = 1.0 // Manually add alpha = 1.0
				}
			}
		}

		return Data(bytes: smoothed, count: smoothed.count * MemoryLayout<Float32>.size)
	}
	
	func smooth3DLUTGaussian(inputData: Data, cubeSize: Int, smoothness: Float) -> Data? {
		let floats = inputData.withUnsafeBytes { ptr in
			Array(ptr.bindMemory(to: Float32.self))
		}

		let totalEntries = cubeSize * cubeSize * cubeSize
		guard floats.count == totalEntries * 4 else {
			print("❌ Expected \(totalEntries * 4) floats (RGBA), but got \(floats.count)")
			return nil
		}

		// Step 1: Restructure into 3D RGB array, ignore alpha
		var lut = [[[SIMD3<Float>]]](repeating: [[SIMD3<Float>]](repeating: [SIMD3<Float>](repeating: .zero, count: cubeSize), count: cubeSize), count: cubeSize)

		for b in 0..<cubeSize {
			for g in 0..<cubeSize {
				for r in 0..<cubeSize {
					let index = ((b * cubeSize + g) * cubeSize + r) * 4
					let rgb = SIMD3<Float>(floats[index], floats[index + 1], floats[index + 2])
					lut[b][g][r] = rgb
				}
			}
		}

		// Step 2: Create Gaussian weights
		let radius = Int(ceil(Double(smoothness) * 2.0))
		let weights: [Float] = (0...(2 * radius)).map { i in
			let x = Float(i - radius)
			return exp(-(x * x) / (2 * smoothness * smoothness))
		}
		let weightSum = weights.reduce(0, +)

		// Step 3: Smooth the RGB values
		var result = lut
		for b in 0..<cubeSize {
			for g in 0..<cubeSize {
				for r in 0..<cubeSize {
					var sum = SIMD3<Float>(0, 0, 0)
					var total: Float = 0.0

					for dz in -radius...radius {
						for dy in -radius...radius {
							for dx in -radius...radius {
								let z = min(max(b + dz, 0), cubeSize - 1)
								let y = min(max(g + dy, 0), cubeSize - 1)
								let x = min(max(r + dx, 0), cubeSize - 1)

								let weight = weights[dz + radius] * weights[dy + radius] * weights[dx + radius]
								sum += lut[z][y][x] * weight
								total += weight
							}
						}
					}
					result[b][g][r] = sum / total
				}
			}
		}

		// Step 4: Flatten and re-add alpha = 1.0
		var final: [Float32] = []
		for b in 0..<cubeSize {
			for g in 0..<cubeSize {
				for r in 0..<cubeSize {
					let rgb = result[b][g][r]
					final.append(contentsOf: [rgb.x, rgb.y, rgb.z, 1.0])
				}
			}
		}

		return Data(bytes: final, count: final.count * MemoryLayout<Float32>.size)
	}
	
	
	// MARK: - 1D lut smoothing / alteration functions

	/// Applies box smoothing, 0 for none, 1 upwards for more.
	func smoothCurvePoints(_ curve: Data, _ smoothingVal: Int) -> Data {
		let floats = curve.withUnsafeBytes { ptr in
			Array(ptr.bindMemory(to: Float32.self))
		}

		guard floats.count % 3 == 0 else {
			print("❌ Curve data is not in RGB triplet format")
			return curve
		}

		let pointCount = floats.count / 3
		let radius = max(1, smoothingVal) // basic box blur radius
		let kernelSize = radius * 2 + 1

		var smoothed: [Float32] = Array(repeating: 0, count: floats.count)

		for channel in 0..<3 { // 0 = R, 1 = G, 2 = B
			for i in 0..<pointCount {
				var sum: Float32 = 0
				var count: Int = 0

				for j in max(0, i - radius)...min(pointCount - 1, i + radius) {
					sum += floats[j * 3 + channel]
					count += 1
				}

				smoothed[i * 3 + channel] = sum / Float32(count)
			}
		}

		return Data(bytes: smoothed, count: smoothed.count * MemoryLayout<Float32>.size)
	}

	
	
	
	func reverseCurveMetal(_ inputHald: CIImage, _ curveData: Data, _ size: Int = 64) -> CIImage {
		// Step 1: Validate and extract floats
		let inputFloats = curveData.withUnsafeBytes { ptr in
			Array(ptr.bindMemory(to: Float32.self))
		}

		guard inputFloats.count == size * 3 else {
			print("Curve data must contain \(size) RGB points")
			return inputHald
		}

		// Step 2: Downsample to 32 points by averaging every 2
		var reduced: [Float32] = []

		for i in stride(from: 0, to: size, by: 2) {
			let r0 = inputFloats[i * 3 + 0]
			let g0 = inputFloats[i * 3 + 1]
			let b0 = inputFloats[i * 3 + 2]
			let r1 = inputFloats[(i + 1) * 3 + 0]
			let g1 = inputFloats[(i + 1) * 3 + 1]
			let b1 = inputFloats[(i + 1) * 3 + 2]

			reduced.append((r0 + r1) / 2.0)
			reduced.append((g0 + g1) / 2.0)
			reduced.append((b0 + b1) / 2.0)
		}

		// Step 3: Convert to Metal buffer
		let floatData = reduced.withUnsafeBufferPointer {
			Data(buffer: $0)
		}

		// Step 4: Prepare CIColorKernel
		let kernel = CIColorKernelCache.shared.applyInverseCurve

		// Step 5: Apply kernel
		guard let result = kernel.apply(
			extent: inputHald.extent,
			roiCallback: { _, rect in rect },
			arguments: [inputHald, floatData]
		) else {
			print("Failed to apply inverse curve kernel")
			return inputHald
		}

		return result
	}

	// Swaps curves, requires identity hald
	func swapCurveMetal(_ identity: CIImage,
						_ scaledCurve: CIImage,
						_ unScaledCurve: CIImage
	) -> CIImage {

		// Step 4: Fetch kernel
		let kernel = CIColorKernelCache.shared.swapCurves

		// Step 5: Apply kernel
		guard let result = kernel.apply(
			extent: identity.extent,
			roiCallback: { _, rect in rect },
			arguments: [scaledCurve, unScaledCurve, identity]
		) else {
			print("Failed to apply swapCurves kernel")
			return identity
		}

		return result
	}
	
	
	// Scales via gain using inverse gain for bp
	func scaleCurve_0_to_1(_ inputCurve: Data) -> Data {
		let floats = inputCurve.withUnsafeBytes { ptr in
			Array(ptr.bindMemory(to: Float32.self))
		}

		guard floats.count % 3 == 0 else {
			print("Input curve is not in RGB triplet format")
			return inputCurve
		}

		let pointCount = floats.count / 3
		var scaled: [Float32] = Array(repeating: 0, count: floats.count)

		for i in 0..<pointCount {
			let r = floats[i * 3 + 0]
			let g = floats[i * 3 + 1]
			let b = floats[i * 3 + 2]

			// Step 1: white point scaling
			let wp = max(r, g, b)
			let whiteScalar: Float32 = wp == 0 ? 1.0 : 1.0 / wp
			var r1 = r * whiteScalar
			var g1 = g * whiteScalar
			var b1 = b * whiteScalar

			// Step 2: invert
			r1 = 1.0 - r1
			g1 = 1.0 - g1
			b1 = 1.0 - b1

			// Step 3: black point scaling
			let bp = min(r1, g1, b1)
			let blackScalar: Float32 = (1.0 - bp) == 0 ? 1.0 : 1.0 / (1.0 - bp)
			r1 = r1 * blackScalar
			g1 = g1 * blackScalar
			b1 = b1 * blackScalar

			// Step 4: invert back
			r1 = 1.0 - r1
			g1 = 1.0 - g1
			b1 = 1.0 - b1

			scaled[i * 3 + 0] = r1
			scaled[i * 3 + 1] = g1
			scaled[i * 3 + 2] = b1
		}

		return Data(bytes: scaled, count: scaled.count * MemoryLayout<Float32>.size)
	}
	
	func createCurvePreset(_ inputCurve: Data, _ name: String) {
		let id = UUID().uuidString

		// Step 1: Validate
		let floats = inputCurve.withUnsafeBytes { ptr in
			Array(ptr.bindMemory(to: Float32.self))
		}

		guard floats.count % 3 == 0 else {
			print("Curve is not in RGB triplet format")
			return
		}

		let pointCount = floats.count / 3
		guard pointCount == 64 else {
			print("Curve must contain 64 RGB points (192 floats)")
			return
		}

		// Step 2: Reduce to 16 RGB points (average each group of 4)
		var reduced: [(Float32, Float32, Float32)] = []

		for i in 0..<16 {
			var r: Float32 = 0
			var g: Float32 = 0
			var b: Float32 = 0
			for j in 0..<4 {
				let index = (i * 4 + j) * 3
				r += floats[index + 0]
				g += floats[index + 1]
				b += floats[index + 2]
			}
			reduced.append((r / 4, g / 4, b / 4))
		}

		// Step 3: Generate 16 linear X values from 0 to 1
		let xValues: [Float32] = (0..<16).map { Float32($0) / 15.0 }

		// Step 4: Format channel strings
		func channelString(channelIndex: Int) -> String {
			let yValues = reduced.map {
				switch channelIndex {
					case 0: return $0.0
					case 1: return $0.1
					case 2: return $0.2
					default: return 0
				}
			}

			let pairs = zip(xValues, yValues).enumerated().map { i, pair in
				let (x, y) = pair
				let formatted = "\(String(format: "%.6f", x)),\(String(format: "%.6f", y))"
				return i < xValues.count - 1 ? formatted + ";" : formatted
			}

			return pairs.joined()
		}

		let redString = channelString(channelIndex: 0)
		let greenString = channelString(channelIndex: 1)
		let blueString = channelString(channelIndex: 2)

		// Step 5: Construct XML
		let xml = """
		<?xml version="1.0"?>
		<SL Engine="1300">
			<E K="GradationCurve" V="0,0;1,1" />
			<E K="GradationCurveY" V="0,0;1,1" />
			<E K="GradationCurveRed" V="\(redString)" />
			<E K="GradationCurveGreen" V="\(greenString)" />
			<E K="GradationCurveBlue" V="\(blueString)" />
			<E K="Name" V="\(name)" />
			<E K="StyleSource" V="Curve" />
			<E K="UUID" V="\(id)" />
		</SL>
		"""

		// Step 6: Save to .copreset
		let filename = name.replacingOccurrences(of: " ", with: "_") + ".copreset"
		let fileManager = FileManager.default
		let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
		let fileURL = documentsURL.appendingPathComponent(filename)

		do {
			try xml.write(to: fileURL, atomically: true, encoding: .utf8)
			print("Saved preset to \(fileURL.path)")
		} catch {
			print("Failed to write preset: \(error)")
		}
	}
	

	
	
	
	// MARK: - Save Capture One LUT
	
	func generateCaptureOneLUT(_ id: UUID, _ pipeline: FilterPipeline, _ dataModel: DataModel) {
		let itemsCopy = dataModel.items
		
		Task (priority: .medium) {
			
			do {
				
				guard let rawHald = debayerHaldImage() else { return }
				
				
				guard let (hald, white, black, ramp, debayered) = await self.createCaptureOneInputs(id, itemsCopy) else { return }
				
//				debugSave(hald, "haldImage")
				
				// Create the variables
				var c1InputHald = rawHald // use the raw hald
				var pipelineHald = hald
				var whitePixel = white
				var blackPixel = black
				var linearRamp = ramp
				
				// Process each concurrently
				await withTaskGroup(of: Void.self) { group in
					// Hald Group
					group.addTask(priority: .medium) {
						c1InputHald =  c1InputHald.c1ToColorForge()
						pipelineHald = await self.applyPipline(hald, id, itemsCopy, pipeline)
					}
					// White Group
					group.addTask(priority: .medium) {
						whitePixel = await self.applyPipline(white, id, itemsCopy, pipeline)
					}
					// Black Group
					group.addTask(priority: .medium) {
						blackPixel = await self.applyPipline(black, id, itemsCopy, pipeline)
					}
					// Ramp Group
					group.addTask(priority: .medium) {
						linearRamp = await self.applyPipline(ramp, id, itemsCopy, pipeline)
					}
				}
				// *************************************************************************
				// Now read them in without concurrency to ensure thread safety in CoreImage
				// *************************************************************************
				
				
				
				
				
				// ********* Read the halds ********* //
				
				let c1Hald = hald.c1ToColorForge()
				guard let c1Data = readCubeData(from: c1Hald, size: 64) else { return }
				saveCubeDataAsCubeFile(c1Data, "RawToC1")
				
				guard let pipelineData = readCubeData(from: pipelineHald, size: 64) else { return }
				saveCubeDataAsCubeFile(pipelineData, "PipelineLUT")
				
				
				
				
				// ********* Create the luts ********* //
				
				// Apply both sets of data to the original hald to now get the combined hald
				var combinedHald = hald.applyLutData(c1Data)
				combinedHald = combinedHald.applyLutData(pipelineData)
				
				// Create the combined lut so we can apply it to the white / black pixel to scale
				guard let combinedData = readCubeData(from: combinedHald, size: 64) else { return }
				let whiteLutApplied = white.applyLutData(combinedData)
				let blackLutApplied = black.applyLutData(combinedData)
				
				// Sample the black and white pixels to get SIMD3<Float>s
				let wRGB = whiteLutApplied.sampleFloat3()
				let bRGB = blackLutApplied.sampleFloat3()
				
				
				
				
				// ********* Create the scalars ********* //
				
				
				// Extract white components
				let wR = wRGB.x, wG = wRGB.y, wB = wRGB.z
				// Extract black components
				let bR = bRGB.x, bG = bRGB.y, bB = bRGB.z
				
				// Get max / min
				let whiteMax = max(wR, wG, wB)
				let blackMin = min(bR, bG, bB)
				
				// White scalar for gain scaling
				let whiteScalar = 1.0 / whiteMax
				
				// We calculate the inverse, as we'll invert RGB and apply gain scaling
				let blackMinInverse = 1.0 - blackMin
				let blackInverseScalar = 1.0 / blackMinInverse
				
				

				// ********* Create the scaled FilmStandard to Linear Lut ********* //
				
				let scaledHald = hald.scale_WP_BP_ByScalar(whiteScalar, blackInverseScalar)
				guard let scalingData = readCubeData(from: scaledHald, size: 64) else { return }
				

				
				// ********* Apply all three luts ********* //
				
				var finalHald = hald.applyLutData(c1Data)
				finalHald = finalHald.applyLutData(pipelineData)
				finalHald = finalHald.applyLutData(scalingData)
				
			
				 
				
				// ********* Read in final hald ********* //
				guard let finalData = readCubeData(from: finalHald, size: 64) else { return }
				guard let smoothedData = smooth3DLUTGaussian(inputData: finalData, cubeSize: 64, smoothness: 4) else { return }
				let smoothedHald = hald.applyLutData(smoothedData)
				
				
				
				// Need to then scale the smoothed hald so curves hit 0 and 1
				
				// ********* Scale Smoothed Hald 0-1 ********* //
				let haldScaled01 = scaleHald01(smoothedHald, white, black)
				let haldScaled01Data = readCubeData(from: haldScaled01, size: 64)!
				
				
				// ********* Extract Curves ********* //
				
				// Get the unscaled curve
				let rampUnscaled = ramp.applyLutData(smoothedData)
				guard let unscaledCurve = sampleRampData(rampUnscaled, floatingPoint: true) else {return}
				
				let rampScaled = ramp.applyLutData(haldScaled01Data)
				let scaledCurve = sampleRampData(rampScaled, floatingPoint: true)!
				
				
				// Debug
				let scaledCurveHald = hald.applyCurveData(data: scaledCurve)
				let scaledCurveHaldData = readCubeData(from: scaledCurveHald, size: 64)!
				saveCubeDataAsCubeFile(scaledCurveHaldData, "ScaledCurve")
				
				
				// Get Transform lut
				guard let transformData = generateTransformLUT(scaledCurveHald, haldScaled01, hald, false) else {return}
				guard let smoothTransform = smooth3DLUTGaussian(inputData: transformData, cubeSize: 64, smoothness: 2) else {return}
				saveCubeDataAsCubeFile(smoothTransform, "RGBTransform")
				
				
				// Now we generate the curve for capture one preset, which adds back the split toning
				let c1Curve = swapCurveMetal(rampUnscaled, rampScaled, ramp)
				let c1CurveData = sampleRampData(c1Curve, floatingPoint: true)!
				createCurvePreset(c1CurveData, "CF_AfterICC_Test")
				let c1CurveHald = hald.applyCurveData(data: c1CurveData)
				let c1CurveHaldData = readCubeData(from: c1CurveHald, size: 64)!
				saveCubeDataAsCubeFile(c1CurveHaldData, "CF_AfterICC_TestCube")
				
				
				// ********* Reverse Curve ********* //
//				let reverseOnly = reverseCurveMetal(hald, lutCurve)
//				guard let reverseOnlyData = readCubeData(from: reverseOnly, size: 64) else { return }
//				let finalResultSmoothed = hald.applyLutData(smoothedData)
//				let finalResultInverse = finalResultSmoothed.applyLutData(reverseOnlyData)
				
				
				
				// ********* Save Final 3D Lut with no curve ********* //
//				guard let finalData = readCubeData(from: finalResultInverse, size: 64) else { return }
//				guard let finalSmoothed = smooth3DLUTGaussian(inputData: finalData, cubeSize: 64, smoothness: 1) else { return }
//				saveCubeDataAsCubeFile(finalData, "FinalC1LutV2")
				
				
				// ********* Generate CaptueOne Curve ********* //
//				createCurvePreset(lutCurve, "PrintCurveV1")
				
				

//				// Test save
//				guard let testInverse = readCubeData(from: inverseHald, size: 64) else { return }
//				saveCubeDataAsCubeFile(testInverse, "CurveRemoved")
//				
//				
//				// ********* 1D Lut Test ********* //
////				let rampApplied = ramp.applyLutData(finalData)
//				guard let rampData = sampleRampData(rampApplied, floatingPoint: true) else {return}
//				
//				let rampOutput = ramp.applyCurveData(data: rampData)
//				createCurvePreset(rampData, "curveTest")
//				debugSave(rampOutput, "curveTest")
				
				
//				// Sample the ramp
//				let linearData = sampleRampData(ramp, floatingPoint: true)  For inverting if need be, to be used as delta / base
////				let rampData = sampleRampData(linearRamp, floatingPoint: true)
				
//				scaleAndSaveLut(combinedHald, hald, wRGB, bRGB, c1Data, pipelineData)
			}
//			catch {
//				
//			}
		}
		
	}
	
	func scaleHald01(_ hald: CIImage, _ white: CIImage, _ black: CIImage) -> CIImage {
		guard let unscaledLut = readCubeData(from: hald, size: 64) else { return hald }
		let wp = white.applyLutData(unscaledLut), bp = black.applyLutData(unscaledLut)
		
		let w = wp.sampleFloat3(), b = bp.sampleFloat3()
		
		// Get white points and black points for R G B
		let wr = w.x, wg = w.y, wb = w.z, br = b.x, bg = b.y, bb = b.z
		
		// Get the gain scalars
		let r_ws = 1.0 / wr, g_ws = 1.0 / wg, b_ws = 1.0 / wb
		let r_bs = 1.0 / (1.0 - br), g_bs = 1.0 / (1.0 - bg), b_bs = 1.0 / (1.0 - bb)
		
		let scaledHald = hald.scale0to1(r_ws, g_ws, b_ws, r_bs, g_bs, b_bs)
		
		return scaledHald
	}
	
	
	// Create inputs for capture one profile creation
	///
	/// We need: hald image, 1D lut ramp, white pixel and black pixel
	///
	func createCaptureOneInputs(_ id: UUID, _ items: [ImageItem]) async -> (CIImage, CIImage, CIImage, CIImage, CIImage)?  {
		
		// Get the item
		guard let item = items.first(where: { $0.id == id }) else { return nil }
		
		// Safely unwrap the debayered image with no adjustments
		guard let debayered = item.debayeredInit else { return nil }
		
		// Get the hald image
		guard let haldImage = item.c1Hald else { return nil }
		
		// Create white and black pixel for scaling after
		let whitePixel = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
		let blackPixel = CIImage(color: .black).cropped(to: CGRect(x: 0, y: 0, width: 1, height: 1))
		
		guard let linearRamp = createLinearRamp(steps: 64) else { return nil }
		
		return (haldImage, whitePixel, blackPixel, linearRamp, debayered)
	}
	
	// Helper for applying pipeline
	func applyPipline( _ input: CIImage, _ id: UUID, _ items: [ImageItem], _ pipeline: FilterPipeline) async ->  CIImage {
		
		guard let item = items.first(where: { $0.id == id }) else { return input }
		
//		let pipeline = pipeline.buildPipeline(
//            for: item,
//            isInit: false,
//            isExport: false,
//            isLut: false,
//            maskingActive: false,
//            selectedMask: nil
//        )
//		
//		let result = pipeline.reduce(input) { image, node in
//			node.apply(to: image)
//		}

		return input
	}
	
	func scaleAndSaveLut( _ hald: CIImage, _ haldOriginal: CIImage,
						  _ white: SIMD3<Float>, _ black: SIMD3<Float>,
						  _ c1Data: Data, _ pipelineData: Data
	) {
		
		// Extract white components
		let wR = white.x, wG = white.y, wB = white.z
		// Extract black components
		let bR = black.x, bG = black.y, bB = black.z
		
		// Get max / min
		let whiteMax = max(wR, wG, wB)
		let blackMin = min(bR, bG, bB)
		
		// White scalar for gain scaling
		let whiteScalar = 1.0 / whiteMax
		
		// We calculate the inverse, as we'll invert RGB and apply gain scaling
		let blackMinInverse = 1.0 - blackMin
		let blackInverseScalar = 1.0 / blackMinInverse
		
		
		let scalingHald = haldOriginal.scale_WP_BP_ByScalar(whiteScalar, blackInverseScalar)
		guard let scalingData = readCubeData(from: scalingHald, size: 64) else { return }
		saveCubeDataAsCubeFile(scalingData, "ScalingLut")
		
//		// Apply the luts
//		var finalHald = haldOriginal
//		finalHald = finalHald.applyLutData(combinedLutData)
//		finalHald = finalHald.applyLutData(scalingData)
//		
//		
//		// Finally save
//		guard let outputData = readCubeData(from: finalHald, size: 64) else { return }
//		saveCubeDataAsCubeFile(outputData, "CaptureOneTest")
	}
	
	
	func debayerHaldImage() -> CIImage? {
		
		// Get the hald
		guard let haldURL = Bundle.main.url(forResource: "Hald64", withExtension: "dng") else { return nil }
		
		let node = DebayerHaldNode(rawFileURL: haldURL)
		let debayeredHald = node.apply()
		
		return debayeredHald
	}
	
	
}

