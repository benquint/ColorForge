//
//  MetalProcessor.swift
//  ColorForge
//
//  Created by admin on 16/08/2025.
//

import Foundation
import Metal
import MetalKit
import CoreVideo
import CoreImage



struct UnpackedImageData {
    let itemId: UUID
    let originalModel: String
    let rawImageData: RawImageData
}

// Swift structure to match your C++ RawImageData
struct RawImageData {
	let rawPixels: Data
	let width: UInt32
	let height: UInt32
	let pitch: UInt32
	let cfaPattern: UInt32
    let orientation: Int
	let blackLevelRed: Float
	let blackLevelGreen: Float
	let blackLevelBlue: Float
	let whiteLevel: Float
	let camToAWG3: [Float] // 3x3 matrix as 9-element array (row-major)
	let rMul: Float
	let bMul: Float
    let chromaticity_x: Double
    let chromaticity_y: Double
	
	// Convenience computed property to get the 3x3 matrix
	var colorMatrix: [[Float]] {
		var matrix: [[Float]] = []
		for row in 0..<3 {
			var rowData: [Float] = []
			for col in 0..<3 {
				rowData.append(camToAWG3[row * 3 + col])
			}
			matrix.append(rowData)
		}
		return matrix
	}
	
	// Helper to get CFA pattern name
	var cfaPatternName: String {
		switch cfaPattern {
		case 0: return "RGGB"
		case 1: return "BGGR"
		case 2: return "GRBG"
		case 3: return "GBRG"
		default: return "Unknown"
		}
	}
}

// Metal-compatible Float3 with padding
struct Float3 {
	var x: Float
	var y: Float
	var z: Float
	var _pad: Float = 0.0 // 16-byte alignment like Metal's float3
}



// Fixed Metal structures to match your kernel parameters exactly with proper padding
struct Params {
	var blackLevel: Float       // 0
	var blackLevelRed: Float    // 4
	var blackLevelGreen: Float  // 8
	var blackLevelBlue: Float   // 12
	var whiteLevel: Float       // 16
	var cfaPattern: UInt32      // 20
	var coreSize: UInt32        // 24
	var _padBeforeMatrix: UInt32 = 0 // 28-31 (aligns next Float3 to 32)
	var camToAWG3: (Float3, Float3, Float3) // 32-79 (16-byte aligned each)
	var rMul: Float             // 80
	var bMul: Float             // 84
	var _padEnd: (Float, Float) = (0.0, 0.0) // 88-95
	
	init(from rawData: RawImageData, coreSize: UInt32 = 16) {
		self.blackLevel = 0.0 // Use individual channel black levels
		self.blackLevelRed = rawData.blackLevelRed
		self.blackLevelGreen = rawData.blackLevelGreen
		self.blackLevelBlue = rawData.blackLevelBlue
		self.whiteLevel = rawData.whiteLevel
		self.cfaPattern = rawData.cfaPattern
		self.coreSize = coreSize
		self.rMul = rawData.rMul
		self.bMul = rawData.bMul
		
		// Convert array to Float3 array
		let matrix = rawData.camToAWG3
		self.camToAWG3 = (
			Float3(x: matrix[0], y: matrix[1], z: matrix[2]),
			Float3(x: matrix[3], y: matrix[4], z: matrix[5]),
			Float3(x: matrix[6], y: matrix[7], z: matrix[8])
		)
	}
}

// Static assertion equivalent - check at runtime in init
extension Params {
	static func validateSize() {
		let expectedSize = 96
		let actualSize = MemoryLayout<Params>.size
		assert(actualSize == expectedSize, "Params struct size mismatch: expected \(expectedSize), got \(actualSize)")
	}
}



// Dummy masks structure (unused but kept for kernel signature compatibility)
struct Masks {
	var dummy: UInt32 = 0
}

class MetalDemosaicProcessor {
	static let shared: MetalDemosaicProcessor? = {
		do {
			return try MetalDemosaicProcessor()
		} catch {
			print("Failed to initialize Metal processor: \(error.localizedDescription)")
			return nil
		}
	}()
	
	private let device: MTLDevice
//	private let commandQueue: MTLCommandQueue
    private let commandQueues: [MTLCommandQueue] // Changed to array
	private let computePipelineState: MTLComputePipelineState
	private let textureCache: CVMetalTextureCache
	
	
	init() throws {
		guard let device = MTLCreateSystemDefaultDevice() else {
			throw MetalError.deviceCreationFailed
		}
		self.device = device
		
        // Create 3 command queues for parallel processing
        var queues: [MTLCommandQueue] = []
        for _ in 0..<3 {
            guard let queue = device.makeCommandQueue() else {
                throw MetalError.commandQueueCreationFailed
            }
            queues.append(queue)
        }
        self.commandQueues = queues

		
		// Create texture cache for CVPixelBuffer conversion
		var textureCache: CVMetalTextureCache?
		let result = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
		guard result == kCVReturnSuccess, let cache = textureCache else {
			throw MetalError.textureCacheCreationFailed
		}
		self.textureCache = cache
		
		// Load and compile the Metal shader
		guard let library = device.makeDefaultLibrary() else {
			throw MetalError.libraryCreationFailed
		}
		
		guard let function = library.makeFunction(name: "demosaic_linear") else {
			throw MetalError.functionNotFound("demosaic_linear")
		}
		
		do {
			self.computePipelineState = try device.makeComputePipelineState(function: function)
		} catch {
			throw MetalError.pipelineCreationFailed(error)
		}
	}
	

    func processDemosaic(rawData: RawImageData, coreSize: UInt32 = 16, queueIndex: Int = 0) throws -> CVPixelBuffer {
		let width = Int(rawData.width)
		let height = Int(rawData.height)
    
		
		// Validate struct size at runtime
		Params.validateSize()
		
		print("Processing image: \(width)x\(height), CFA: \(rawData.cfaPatternName)")
		
		// Create input texture from raw data
		let inputTexture = try createInputTexture(from: rawData)
		print("Created input texture: \(inputTexture.width)x\(inputTexture.height)")
		
		// Create output pixel buffer - using RGBA16Unorm like your C++ code for debug
		let outputPixelBuffer = try createOutputPixelBufferUnorm(width: width, height: height)
		let outputTexture = try createOutputTextureUnorm(from: outputPixelBuffer)
		print("Created output texture: \(outputTexture.width)x\(outputTexture.height)")
		
		// Create parameter buffers
		var params = Params(from: rawData, coreSize: coreSize)
		var masks = Masks()
		var leftMargin: UInt32 = 0  // Adjust if needed
		var topMargin: UInt32 = 0   // Adjust if needed
		
		print("Params: CFA=\(params.cfaPattern), coreSize=\(params.coreSize)")
		print("Black levels: R=\(params.blackLevelRed), G=\(params.blackLevelGreen), B=\(params.blackLevelBlue)")
		print("White level: \(params.whiteLevel), Muls: R=\(params.rMul), B=\(params.bMul)")
		
		guard let paramsBuffer = device.makeBuffer(bytes: &params, length: MemoryLayout<Params>.size, options: []),
			  let masksBuffer = device.makeBuffer(bytes: &masks, length: MemoryLayout<Masks>.size, options: []),
			  let leftMarginBuffer = device.makeBuffer(bytes: &leftMargin, length: MemoryLayout<UInt32>.size, options: []),
			  let topMarginBuffer = device.makeBuffer(bytes: &topMargin, length: MemoryLayout<UInt32>.size, options: []) else {
			throw MetalError.bufferCreationFailed
		}
        
        let commandQueue = commandQueues[queueIndex % commandQueues.count]
		
		// Create command buffer and encoder
		guard let commandBuffer = commandQueue.makeCommandBuffer(),
			  let encoder = commandBuffer.makeComputeCommandEncoder() else {
			throw MetalError.commandBufferCreationFailed
		}
		
		// Set up compute pipeline
		encoder.setComputePipelineState(computePipelineState)
		encoder.setTexture(inputTexture, index: 0)
		encoder.setTexture(outputTexture, index: 1)
		encoder.setBuffer(paramsBuffer, offset: 0, index: 0)
		encoder.setBuffer(masksBuffer, offset: 0, index: 1)
		encoder.setBuffer(leftMarginBuffer, offset: 0, index: 2)
		encoder.setBuffer(topMarginBuffer, offset: 0, index: 3)
		
		// Calculate threadgroup and grid sizes - MATCHING YOUR C++ CODE
		let coreInt = Int(coreSize)
		let apron = 1  // Your kernel uses apron = 1 for bilinear
		let tileSize = coreInt + 2 * apron
		
		// Threadgroup size and memory exactly like C++
		let threadgroupSize = MTLSize(width: coreInt, height: coreInt, depth: 1)
		let threadgroupMemoryLength = tileSize * tileSize * MemoryLayout<Float>.size
		
		encoder.setThreadgroupMemoryLength(threadgroupMemoryLength, index: 0)
		
		let gridSize = MTLSize(
			width: (width + coreInt - 1) / coreInt,
			height: (height + coreInt - 1) / coreInt,
			depth: 1
		)
		
		print("Using threadgroup size: \(coreInt)x\(coreInt), grid: \(gridSize)")
		print("Threadgroup memory: \(threadgroupMemoryLength) bytes, tile: \(tileSize)x\(tileSize)")
		
		encoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadgroupSize)
		encoder.endEncoding()
		
		// Execute
		commandBuffer.commit()
		commandBuffer.waitUntilCompleted()
		
		if let error = commandBuffer.error {
			print("Command buffer error: \(error)")
			throw MetalError.executionFailed(error)
		}
		
		print("Metal processing completed successfully")
		return outputPixelBuffer
	}
    
    func calculateScale(width: Int, height: Int) async -> Float {
        let screenSize = NSScreen.main?.frame.size ?? CGSize(width: 2048, height: 2048)
        let screenShortEdge = min(screenSize.width, screenSize.height)
        
        let targetSize: CGFloat
        var scale: Float = 1.0
        
        let aspectRatio = Float(width) / Float(height)
        let isLandscape = aspectRatio > 1.0
        
        if screenShortEdge > 2048.0 {
            targetSize = screenShortEdge
            
            if isLandscape {
                // Landscape: scale based on height (shorter dimension)
                scale = Float(targetSize) / Float(height)
            } else {
                // Portrait: scale based on width (shorter dimension)
                scale = Float(targetSize) / Float(width)
            }
            
            return scale * 0.7
            
        } else {
            targetSize = 2048.0
            
            if isLandscape {
                // Landscape: scale based on height (shorter dimension)
                scale = Float(targetSize) / Float(height)
            } else {
                // Portrait: scale based on width (shorter dimension)
                scale = Float(targetSize) / Float(width)
            }
            
            return scale
        }
    }
    
	
	private func createInputTexture(from rawData: RawImageData) throws -> MTLTexture {
		let width = Int(rawData.width)
		let height = Int(rawData.height)
		
		let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
			pixelFormat: .r16Uint,
			width: width,
			height: height,
			mipmapped: false
		)
		textureDescriptor.usage = [.shaderRead]
		
		guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
			throw MetalError.textureCreationFailed
		}
		
		// Copy raw data to texture
		rawData.rawPixels.withUnsafeBytes { bytes in
			let bytesPerRow = Int(rawData.pitch)
			texture.replace(
				region: MTLRegionMake2D(0, 0, width, height),
				mipmapLevel: 0,
				withBytes: bytes.baseAddress!,
				bytesPerRow: bytesPerRow
			)
		}
		
		return texture
	}
	
	private func createOutputPixelBufferUnorm(width: Int, height: Int) throws -> CVPixelBuffer {
		let attributes: [String: Any] = [
			kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_64RGBAHalf,
			kCVPixelBufferWidthKey as String: width,
			kCVPixelBufferHeightKey as String: height,
			kCVPixelBufferMetalCompatibilityKey as String: true
		]
		
		var pixelBuffer: CVPixelBuffer?
		let result = CVPixelBufferCreate(
			kCFAllocatorDefault,
			width,
			height,
			kCVPixelFormatType_64RGBAHalf,
			attributes as CFDictionary,
			&pixelBuffer
		)
		
		guard result == kCVReturnSuccess, let buffer = pixelBuffer else {
			throw MetalError.pixelBufferCreationFailed
		}
		
		return buffer
	}

	private func createOutputTextureUnorm(from pixelBuffer: CVPixelBuffer) throws -> MTLTexture {
		let width = CVPixelBufferGetWidth(pixelBuffer)
		let height = CVPixelBufferGetHeight(pixelBuffer)
		
		var metalTexture: CVMetalTexture?
		let result = CVMetalTextureCacheCreateTextureFromImage(
			kCFAllocatorDefault,
			textureCache,
			pixelBuffer,
			nil,
			.rgba16Float,
			width,
			height,
			0,
			&metalTexture
		)
		
		guard result == kCVReturnSuccess,
			  let cvTexture = metalTexture,
			  let texture = CVMetalTextureGetTexture(cvTexture) else {
			throw MetalError.textureCreationFailed
		}
		
		return texture
	}
	
	
	
	// Add this function to create a CIImage from raw data for debugging
	func createDebugCIImage(from rawData: RawImageData) {
		let width = Int(rawData.width)
		let height = Int(rawData.height)
		
		// Create a simple grayscale representation of the raw Bayer data
		// We'll just take the raw 16-bit values and convert to 8-bit for visualization
		var grayscaleData = Data(count: width * height)
		
		rawData.rawPixels.withUnsafeBytes { rawBytes in
			let uint16Ptr = rawBytes.bindMemory(to: UInt16.self)
			
			for y in 0..<height {
				for x in 0..<width {
					let rawIndex = y * (Int(rawData.pitch) / 2) + x // pitch is in bytes, so divide by 2 for UInt16
					if rawIndex < uint16Ptr.count {
						let rawValue = uint16Ptr[rawIndex]
						// Convert 16-bit to 8-bit for visualization (simple scaling)
						let scaledValue = UInt8(min(255, rawValue >> 8))
						grayscaleData[y * width + x] = scaledValue
					}
				}
			}
		}
		
		// Create CIImage from the grayscale data
		let ciImage = CIImage(
			bitmapData: grayscaleData,
			bytesPerRow: width,
			size: CGSize(width: width, height: height),
			format: .L8,  // 8-bit grayscale
			colorSpace: CGColorSpace(name: CGColorSpace.genericGrayGamma2_2)
		)
		
		debugSave(ciImage, "RawImage")
	}
	
	
	
}

// Error handling
enum MetalError: Error, LocalizedError {
	case deviceCreationFailed
	case commandQueueCreationFailed
	case textureCacheCreationFailed
	case libraryCreationFailed
	case functionNotFound(String)
	case pipelineCreationFailed(Error)
	case bufferCreationFailed
	case textureCreationFailed
	case pixelBufferCreationFailed
	case commandBufferCreationFailed
	case executionFailed(Error)
	
	var errorDescription: String? {
		switch self {
		case .deviceCreationFailed:
			return "Failed to create Metal device"
		case .commandQueueCreationFailed:
			return "Failed to create command queue"
		case .textureCacheCreationFailed:
			return "Failed to create texture cache"
		case .libraryCreationFailed:
			return "Failed to create Metal library"
		case .functionNotFound(let name):
			return "Metal function '\(name)' not found"
		case .pipelineCreationFailed(let error):
			return "Failed to create compute pipeline: \(error.localizedDescription)"
		case .bufferCreationFailed:
			return "Failed to create Metal buffer"
		case .textureCreationFailed:
			return "Failed to create Metal texture"
		case .pixelBufferCreationFailed:
			return "Failed to create CVPixelBuffer"
		case .commandBufferCreationFailed:
			return "Failed to create command buffer"
		case .executionFailed(let error):
			return "Metal execution failed: \(error.localizedDescription)"
		}
	}
}

