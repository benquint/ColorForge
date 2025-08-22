//
//  InitialPipeline.swift
//  ColorForge
//
//  Created by Ben Quinton on 22/08/2025.
//


import Foundation
import Metal
import MetalKit
import CoreImage
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import simd
import CoreImage
import MetalPerformanceShaders

struct PipelineParams {
    // Raw adjust
    var adaptationMatrix: simd_float3x3
    var ev: Float
    var isLog: Int32
    var isTiff: Int32
    var colorSpace: Int32 // 0 for AWG3, 1 for sRGB, 2 for AdobeRGB, 3 for sGamut3.cine, 4 for Rec2020
    var contrast: Float
    
    var hdrWhite: Float
    var hdrHighlight: Float
    var hdrShadow: Float
    var hdrBlack: Float
    
    var saturation: Float
    
    var redHue: Float; var redSaturation: Float; var redDensity: Float
    var greenHue: Float; var greenSaturation: Float; var greenDensity: Float
    var blueHue: Float; var blueSaturation: Float; var blueDensity: Float
    var cyanHue: Float; var cyanSaturation: Float; var cyanDensity: Float
    var magentaHue: Float; var magentaSaturation: Float; var magentaDensity: Float
    var yellowHue: Float; var yellowSaturation: Float; var yellowDensity: Float
}

class InitialPipeline {
    static let shared = InitialPipeline()

    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let computePipelineState: MTLComputePipelineState
    private let optimalThreadgroupSize: MTLSize

    let context: CIContext
    private let textureCache: CVMetalTextureCache

    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal device not available")
        }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            fatalError("Could not create command queue")
        }
        self.commandQueue = commandQueue
        
        let options: [CIContextOption: Any] = [
            .workingColorSpace: NSNull(),
            .outputColorSpace: NSNull(),
            .outputPremultiplied: true,
            .useSoftwareRenderer: false,
            .workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
            .allowLowPower: false,
            .highQualityDownsample: true,
            .priorityRequestLow: false,
            .cacheIntermediates: false,
            .memoryTarget: 4_294_967_296 // 4gb
        ]
        
        self.context = CIContext(mtlDevice: device, options: options)
        
        // Load shader library
        guard let libraryPath = Bundle.main.path(forResource: "Pipeline", ofType: "metallib"),
              let library = try? device.makeLibrary(filepath: libraryPath) else {
            fatalError("Could not load Pipeline.metallib from bundle resources")
        }
        
        guard let kernelFunction = library.makeFunction(name: "pipelineKernel") else {
            fatalError("Could not find pipelineKernel function")
        }
        
        // Add this in your init() method after creating the device
        var textureCache: CVMetalTextureCache?
        let cacheResult = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        guard cacheResult == kCVReturnSuccess, let cache = textureCache else {
            fatalError("Could not create Metal texture cache")
        }
        self.textureCache = cache
        
        
        do {
            self.computePipelineState = try device.makeComputePipelineState(function: kernelFunction)
        } catch {
            fatalError("Could not create compute pipeline state: \(error)")
        }
        
        // Calculate optimal threadgroup size
        self.optimalThreadgroupSize = Self.calculateOptimalThreadgroupSize(
            device: device,
            pipelineState: computePipelineState
        )
    }
    
    private static func calculateOptimalThreadgroupSize(device: MTLDevice, pipelineState: MTLComputePipelineState) -> MTLSize {
        let maxThreadsPerThreadgroup = pipelineState.maxTotalThreadsPerThreadgroup
        let threadExecutionWidth = pipelineState.threadExecutionWidth
        
        let maxDimension = Int(sqrt(Double(maxThreadsPerThreadgroup)))
        let optimalSize = (maxDimension / threadExecutionWidth) * threadExecutionWidth
        let threadgroupSize = max(8, min(32, optimalSize))
        
        print("Device: \(device.name)")
        print("Max threads per threadgroup: \(maxThreadsPerThreadgroup)")
        print("Thread execution width: \(threadExecutionWidth)")
        print("Chosen threadgroup size: \(threadgroupSize)x\(threadgroupSize)")
        
        return MTLSize(width: threadgroupSize, height: threadgroupSize, depth: 1)
    }
    
    
    // MARK: - Pipeline Processing
    
    func processMetal(inputTexture: MTLTexture, outputTexture: MTLTexture, params: PipelineParams) throws {
        
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {
            print("❌ Failed to create command buffer")
            throw MetalPipelineError.commandBufferCreationFailed
        }

        
        guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("❌ Failed to create command encoder")
            throw MetalPipelineError.commandEncoderCreationFailed
        }

        
        commandEncoder.setComputePipelineState(computePipelineState)
        commandEncoder.setTexture(inputTexture, index: 0)
        commandEncoder.setTexture(outputTexture, index: 1)
        
        var mutableParams = params
        commandEncoder.setBytes(&mutableParams, length: MemoryLayout<PipelineParams>.size, index: 0)
        
        let threadsPerGrid = MTLSize(width: inputTexture.width, height: inputTexture.height, depth: 1)
//        print("Dispatching threads: \(threadsPerGrid)")
//        print("Threadgroup size: \(optimalThreadgroupSize)")
        
        commandEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: optimalThreadgroupSize)
        commandEncoder.endEncoding()
        
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        
        if let error = commandBuffer.error {
            print("❌ Command buffer error: \(error)")
            throw MetalPipelineError.executionFailed(error)
        }
        
       
    }
    

    // MARK: - Convenience Methods
    
    func processImage(_ item: ImageItem, _ inImage: CIImage) throws -> CIImage {
        let wbModel = WhiteBalanceModel.shared
        
        let initTemp = item.initTemp
        let initTint = item.initTint
        let temp = item.temp
        let tint = item.tint
        var exp = item.exposure + item.baselineExposure
        
        if item.applyScanMode {
            exp += 2.0
        }
        
        let hueScalar: Float = 0.000833
        
        // Calculate the adaptation matrix
        let adaptationMatrix = WhiteBalanceModel.adaptationMatrix(
            initTemp: initTemp,
            initTint: initTint,
            temp: temp,
            tint: tint
        )
        
        let params = PipelineParams(
            // White balance (identity matrix for no change)
            adaptationMatrix: adaptationMatrix,
            
            // Basic adjustments
            ev: exp,
            isLog: 1, // Log Mode On
            isTiff: 0,
            colorSpace: 0,
            contrast: item.contrast / 100.0,
            
            // HDR controls
            hdrWhite: item.hdrWhite / 100.0,
            hdrHighlight: item.hdrHighlight / 100.0,
            hdrShadow: item.hdrShadow / 100.0,
            hdrBlack: item.hdrBlack / 100.0,
            
            // Color grading
            saturation: (item.saturation / 100.0) + 1.0,
            
            // HSD controls with proper normalizations
            redHue: (item.redHue / 2.0) * hueScalar, redSaturation: (item.redHue / 200) + 1, redDensity: item.redDen / 200,
            greenHue: (item.greenHue / 2.0) * hueScalar, greenSaturation: (item.greenHue / 200) + 1, greenDensity: item.greenDen / 200,
            blueHue: (item.blueHue / 2.0) * hueScalar, blueSaturation: (item.blueHue / 200) + 1, blueDensity: item.blueDen / 200,
            cyanHue: (item.cyanHue / 2.0) * hueScalar, cyanSaturation: (item.cyanHue / 200) + 1, cyanDensity: item.cyanDen / 200,
            magentaHue: (item.magentaHue / 2.0) * hueScalar, magentaSaturation: (item.magentaHue / 200) + 1, magentaDensity: item.magentaDen / 200,
            yellowHue: (item.yellowHue / 2.0) * hueScalar, yellowSaturation: (item.yellowHue / 200) + 1, yellowDensity: item.yellowDen / 200
        )
        
        // Convert CVPixelBuffer to MTLTexture
        let inputTexture = try createTexture(from: inImage)
        
        // Create output texture
        let outputTexture = try createOutputTexture(matching: inputTexture)
        
        // Process with Metal
        try processMetal(inputTexture: inputTexture, outputTexture: outputTexture, params: params)
        
        // Convert MTLTexture back to CIImage
        return CIImage(mtlTexture: outputTexture, options: nil)!
    }
    
    
    private func createTexture(from ciImage: CIImage) throws -> MTLTexture {
        let width = Int(ciImage.extent.width)
        let height = Int(ciImage.extent.height)
        
        // Create texture descriptor similar to your working example
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba16Float, // Use half float format
            width: width,
            height: height,
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            throw MetalPipelineError.textureCreationFailed
        }

        context.render(ciImage,
                      to: texture,
                      commandBuffer: nil,
                      bounds: ciImage.extent,
                      colorSpace: CGColorSpaceCreateDeviceRGB())

        return texture
    }


    
    private func createOutputTexture(matching inputTexture: MTLTexture) throws -> MTLTexture {
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba32Float,
            width: inputTexture.width,
            height: inputTexture.height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw MetalPipelineError.textureCreationFailed
        }
        
        return texture
    }
    
    

    
    
    
}

// MARK: - Supporting Types


enum MetalPipelineError: Error {
    case imageLoadFailed
    case textureCreationFailed
    case contextCreationFailed
    case imageCreationFailed
    case imageSaveFailed
    case commandBufferCreationFailed
    case commandEncoderCreationFailed
    case executionFailed(Error)
    
    var localizedDescription: String {
        switch self {
        case .imageLoadFailed:
            return "Failed to load image"
        case .textureCreationFailed:
            return "Failed to create Metal texture"
        case .contextCreationFailed:
            return "Failed to create CGContext"
        case .imageCreationFailed:
            return "Failed to create CGImage"
        case .imageSaveFailed:
            return "Failed to save image"
        case .commandBufferCreationFailed:
            return "Failed to create command buffer"
        case .commandEncoderCreationFailed:
            return "Failed to create command encoder"
        case .executionFailed(let error):
            return "Pipeline execution failed: \(error.localizedDescription)"
        }
    }
    
    
}
