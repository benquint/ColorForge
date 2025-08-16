//
//  RenderingManager.swift
//  ColorForge
//
//  Created by admin on 23/05/2025.
//


/*
 
 Class to handle the rendering logic, aka rendering to thumbnails,
 display, saving etc.
 
 
 */

import Foundation
import CoreImage
import SwiftUI
import CoreGraphics
import CoreVideo
import MetalKit

class RenderingManager {
	static let shared = RenderingManager()
	
	var renderer: Renderer?
	
	
	let thumbnailContext: CIContext
	let mainImageContext: CIContext
//	let fullscreenContext: CIContext
	let exportContext: CIContext
	let backgroundContext: CIContext
	let cacheContext: CIContext
    
    let scopeContext: CIContext
    
    let lutContext: CIContext
	
	let device: MTLDevice
	
	private init() {
		let adobeRGBColorSpace = CGColorSpace(name: CGColorSpace.adobeRGB1998)!
		let linearDisplayP3 = CGColorSpace(name: CGColorSpace.extendedDisplayP3)!
		
		
		// Main display context
		let optionsMain: [CIContextOption: Any] = [
			.workingColorSpace: NSNull(),
			.outputColorSpace: adobeRGBColorSpace,
//			.workingColorSpace: linearDisplayP3, // Temporary debug
//			.outputColorSpace: linearDisplayP3, // Temporary debug
			.name: "mainImageContext",
			.outputPremultiplied: false,
			.useSoftwareRenderer: false,
			.workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
			.allowLowPower: false, // Use high-performance mode
			.highQualityDownsample: true, // Enable high-quality downsampling
			.priorityRequestLow: false, // Prioritize high performance
			.cacheIntermediates: true, // Cache intermediate results for performance
			.memoryTarget: 4_294_967_296 // 4gb
		]
		
		if let device = MTLCreateSystemDefaultDevice() {
			self.device = device
			self.mainImageContext = CIContext(mtlDevice: device, options: optionsMain)
		} else {
			print("Falling back to default CIContext without Metal support.")
			self.device = MTLCreateSystemDefaultDevice()! // Fallback to ensure device is set
			self.mainImageContext = CIContext(options: optionsMain)
		}
		
		
		// Thumbnail display context
		let optionsThumbnail: [CIContextOption: Any] = [
            .workingColorSpace: NSNull(),
            .outputColorSpace: adobeRGBColorSpace,
            .name: "thumbnailContext",
			.outputPremultiplied: false,
			.useSoftwareRenderer: false,
			.workingFormat: NSNumber(value: CIFormat.RGBAh.rawValue),
			.allowLowPower: false, // Use high-performance mode
			.highQualityDownsample: true, // Enable high-quality downsampling
			.priorityRequestLow: false, // Prioritize high performance
			.cacheIntermediates: true, // Cache intermediate results for performance
			.memoryTarget: 4_294_967_296 // 4gb
		]
		
		
		if let device = MTLCreateSystemDefaultDevice() {
			self.thumbnailContext = CIContext(mtlDevice: device, options: optionsThumbnail)
		} else {
			print("Falling back to default CIContext without Metal support.")
			self.thumbnailContext = CIContext(options: optionsThumbnail)
		}
		
		
//		// Full screen - not sure we'll need this.
//		let optionsFullScreen: [CIContextOption: Any] = [
//			.workingColorSpace: linearDisplayP3,
//			.outputColorSpace: adobeRGBColorSpace,
//			.name: "fullscreenImageContext",
//			.outputPremultiplied: true,
//			.useSoftwareRenderer: false,
//			.workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
//			.allowLowPower: false, // Use high-performance mode
//			.highQualityDownsample: false, // Enable high-quality downsampling
//			.priorityRequestLow: false, // Prioritize high performance
//			.cacheIntermediates: true, // Cache intermediate results for performance
//			.memoryTarget: 4_294_967_296 // 4gb
//		]
//		
//		
//		// Full screen to use same options as main image
//		if let device = MTLCreateSystemDefaultDevice() {
//			self.fullscreenContext = CIContext(mtlDevice: device, options: optionsFullScreen)
//		} else {
//			print("Falling back to default CIContext without Metal support.")
//			self.fullscreenContext = CIContext(options: optionsFullScreen)
//		}
		
		
		// Export context options
		let optionsExport: [CIContextOption: Any] = [
			.workingColorSpace: NSNull(),
			.outputColorSpace: adobeRGBColorSpace,
			.name: "exportContext",
			.outputPremultiplied: true,
			.useSoftwareRenderer: false,
			.workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
			.allowLowPower: false,
			.highQualityDownsample: true,
			.priorityRequestLow: false,
			.cacheIntermediates: false,
			.memoryTarget: 4_294_967_296 // 4gb
		]
		
		if let device = MTLCreateSystemDefaultDevice() {
			self.exportContext = CIContext(mtlDevice: device, options: optionsExport)
		} else {
			print("Falling back to default CIContext without Metal support.")
			self.exportContext = CIContext(options: optionsExport)
		}
        
        let proPhoto = CGColorSpace(name: CGColorSpace.rommrgb)!
        let extended = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!
        // Export context options
        let optionsLut: [CIContextOption: Any] = [
            .workingColorSpace: NSNull(),
			.outputColorSpace: NSNull(),
//            .workingColorSpace: extended,
//            .outputColorSpace: extended,
            .name: "exportContext",
            .outputPremultiplied: true,
            .useSoftwareRenderer: false,
            .workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
            .allowLowPower: true,
            .highQualityDownsample: true,
            .priorityRequestLow: false,
            .cacheIntermediates: true,
            .memoryTarget: 4_294_967_296 // 4gb
        ]
        
        if let device = MTLCreateSystemDefaultDevice() {
            self.lutContext = CIContext(mtlDevice: device, options: optionsExport)
        } else {
            print("Falling back to default CIContext without Metal support.")
            self.lutContext = CIContext(options: optionsExport)
        }
		
		
		
		// Sampling context
		let optionsSampling: [CIContextOption: Any] = [
			.workingColorSpace: NSNull(),
			.outputColorSpace: NSNull(),
			.name: "exportContext",
			.outputPremultiplied: true,
			.useSoftwareRenderer: false,
			.workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
			.allowLowPower: true,
			.highQualityDownsample: true,
			.priorityRequestLow: false,
			.cacheIntermediates: false,
			.memoryTarget: 4_294_967_296 // 4gb
		]
		
		if let device = MTLCreateSystemDefaultDevice() {
			self.backgroundContext = CIContext(mtlDevice: device, options: optionsSampling)
		} else {
			print("Falling back to default CIContext without Metal support.")
			self.backgroundContext = CIContext(options: optionsSampling)
		}
		
		let optionsCache: [CIContextOption: Any] = [
			.workingColorSpace: NSNull(),
			.outputColorSpace: NSNull(),
			.name: "cacheContext",
			.outputPremultiplied: false,
			.useSoftwareRenderer: false,
			.workingFormat: NSNumber(value: CIFormat.RGBAf.rawValue),
			.allowLowPower: false, // Use high-performance mode
			.highQualityDownsample: false, // Enable high-quality downsampling
			.priorityRequestLow: false, // Push to background
			.cacheIntermediates: false, // Cache intermediate results for performance
			.memoryTarget: 4_294_967_296 // 4gb
		]
		
		if let device = MTLCreateSystemDefaultDevice() {
			self.cacheContext = CIContext(mtlDevice: device, options: optionsCache)
		} else {
			print("Falling back to default CIContext without Metal support.")
			self.cacheContext = CIContext(options: optionsCache)
		}
        
        // Main display context
        let scopeOptions: [CIContextOption: Any] = [
            .workingColorSpace: NSNull(),
            .outputColorSpace: NSNull(),
            .name: "scopeContext",
            .outputPremultiplied: false,
            .useSoftwareRenderer: false,
            .workingFormat: NSNumber(value: CIFormat.RGBAh.rawValue),
            .allowLowPower: false, // Use high-performance mode
            .highQualityDownsample: true, // Enable high-quality downsampling
            .priorityRequestLow: false, // Prioritize high performance
            .cacheIntermediates: true, // Cache intermediate results for performance
            .memoryTarget: 4_294_967_296 // 4gb
        ]
        
        if let device = MTLCreateSystemDefaultDevice() {
            self.scopeContext = CIContext(mtlDevice: device, options: scopeOptions)
        } else {
            print("Falling back to default CIContext without Metal support.")
            self.scopeContext = CIContext(options: scopeOptions)
        }
        
		
	}
	

}
