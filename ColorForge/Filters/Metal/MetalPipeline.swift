////
////  MetalPipeline.swift
////  ColorForge
////
////  Created by Ben Quinton on 21/08/2025.
////
//
//import Foundation
//
//
//class MetalPipeline {
//    static let shared = MetalPipeline()
//    
//    private let device: MTLDevice
//    private let commandQueues: [MTLCommandQueue] // Changed to array
//    private let computePipelineState: MTLComputePipelineState
//    private let textureCache: CVMetalTextureCache
//    
//    
//    func setupOptimalThreadgroupSize(device: MTLDevice, pipelineState: MTLComputePipelineState) -> MTLSize {
//        
//        // Get hardware capabilities
//        let maxThreadsPerThreadgroup = pipelineState.maxTotalThreadsPerThreadgroup
//        let threadExecutionWidth = pipelineState.threadExecutionWidth
//        
//        // Calculate optimal square threadgroup size
//        let maxDimension = Int(sqrt(Double(maxThreadsPerThreadgroup)))
//        
//        // Round down to nearest multiple of threadExecutionWidth for efficiency
//        let optimalSize = (maxDimension / threadExecutionWidth) * threadExecutionWidth
//        
//        // Clamp to reasonable bounds (8-32 typically work well)
//        let threadgroupSize = max(8, min(32, optimalSize))
//        
//        print("Device: \(device.name)")
//        print("Max threads per threadgroup: \(maxThreadsPerThreadgroup)")
//        print("Thread execution width: \(threadExecutionWidth)")
//        print("Chosen threadgroup size: \(threadgroupSize)x\(threadgroupSize)")
//        
//        return MTLSize(width: threadgroupSize, height: threadgroupSize, depth: 1)
//    }
//
//    func dispatchPipelineKernel() {
//        let threadgroupSize = setupOptimalThreadgroupSize(device: device, pipelineState: pipelineState)
//        
//        let threadgroupsPerGrid = MTLSize(
//            width: (textureWidth + threadgroupSize.width - 1) / threadgroupSize.width,
//            height: (textureHeight + threadgroupSize.height - 1) / threadgroupSize.height,
//            depth: 1
//        )
//        
//        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid,
//                                           threadsPerThreadgroup: threadgroupSize)
//    }
//    
//    
//}
