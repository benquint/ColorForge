//
//  CustomKernels.swift
//  ColorForge
//
//  Created by Ben Quinton on 22/05/2025.
//

import Foundation
import CoreImage

// Global class
public final class CIColorKernelCache {
	public static let shared = CIColorKernelCache()
    
    // Gamut mapping
    let sphGamutMap: CIColorKernel

	// RawAdjust
	let encodeSensor: CIColorKernel 
	let exposure: CIColorKernel
	let contrast: CIColorKernel
	let globalSaturation: CIColorKernel
	let hdrKernel: CIColorKernel
	let previewHSD: CIColorKernel
	let hsdKernel: CIColorKernel
	
	// Neg convert kernels
	let decodeCineon: CIColorKernel
	let halation: CIColorKernel
	let grainPlateBlendKernel: CIColorKernel
	let decodeNegative: CIColorKernel
    let encodeNegative: CIColorKernel
	let mtfBandKernel: CIColorKernel

	// Scan Kernels
	let scanContrast: CIColorKernel
	let offsetRGB: CIColorKernel
    let lift: CIColorKernel
	
    // Capture one Kernels
    let convertToC1: CIColorKernel
    let c1ToColorForge: CIColorKernel
    let filmStandardToLinear: CIColorKernel
	let applyInverseCurve: CIColorKernel
	let transformLut: CIColorKernel
	let scale0to1: CIColorKernel
	let swapCurves: CIColorKernel 
	
	// Custom helper kernels
	let scaleWP_BP_withScalar: CIColorKernel
	let scaleWP_BP: CIColorKernel
	let multiplyByValue: CIColorKernel
	let combineRGBAndInvert: CIColorKernel
	let returnChannelAndInvert: CIColorKernel
	let blendWithOpacity: CIColorKernel
	let calculateTempFromXY: CIColorKernel
    let blendWithMaskMetal: CIColorKernel
    let arriOverlayBlend: CIColorKernel
    let arriSoftLightBlend: CIColorKernel
	
	// Enlarger Kernels
	let enlargerBW: CIColorKernel
	let ilfordCurve: CIColorKernel
	let legacyEnlarger: CIColorKernel
	let legacyPrintCurve: CIColorKernel
	let legacyGrade0Curve: CIColorKernel
	let enlargerV2: CIColorKernel
    let enlargerV2Masked: CIColorKernel 
	let mapOutputValues: CIColorKernel
	let enlargerOffsets: CIColorKernel
	let enlargerCurves: CIColorKernel
	let printCurve: CIColorKernel
	let enlargerFilter: CIColorKernel
	
	// ColorSpace
	let RGBtoYUV: CIColorKernel
	let YUVtoRGB: CIColorKernel
    let UVtoRGB: CIColorKernel
	let gamutMap: CIColorKernel
	let toneMapLinear: CIColorKernel
	let adobeCRCurve: CIColorKernel
	let rgbToSpherical: CIColorKernel
	let sphericalToRgb: CIColorKernel
    
    
    // Masking
    let ditherMask: CIColorKernel
	let softenMask: CIColorKernel
	
	// Gamma
	let encodeLogC: CIColorKernel
	let decodeLogC: CIColorKernel
    
    // Helper
    let addTwoImages: CIColorKernel
    let multiplyTwoImages: CIColorKernel
    let evenTile: CIColorKernel
    
    let mixGrainAndApply: CIColorKernel
    
    // Film grain new
    let returnChannelF3: CIColorKernel
    let combineChannelsF3: CIColorKernel
    let blendPaper: CIColorKernel
    let smoothStepMetal: CIColorKernel
	
	
	// Apply sigmoid smoothing to mask image
	let applySigmoidSmoothing: CIColorKernel
    
    // ColorSpace
	
	let AWG4_to_LinearP3: CIColorKernel
	let decodeSLog3: CIColorKernel
	
	// Realistic Grain
	let realisticFilmGrain: CIKernel
	let copyChannel: CIColorKernel
	let normaliseGrain: CIColorKernel
    
    let perlinNoise: CIColorKernel
    let perlinNoiseColorGradient: CIColorKernel
    let maskPerlinNoise: CIColorKernel
    
    let addMask: CIColorKernel
    let subtractMask: CIColorKernel
    
    let printHalationV2: CIColorKernel
    
	let createBorder: CIColorKernel
    
    let edgeAwareFilter: CIColorKernel
    
    // Mask gamma correction kernels
    let enlargerGamma: CIColorKernel
    
    let perlinNoiseMix: CIColorKernel
    
    
    let grainMix: CIColorKernel
    let maskGrain: CIColorKernel
	let perlinNoiseSmall: CIColorKernel
    
	private init() {
		guard let url = Bundle.main.url(forResource: "CIKernels", withExtension: "metallib"),
			  let data = try? Data(contentsOf: url) else {
			fatalError("Failed to load metallib")
		}
		
		print("Metallib loaded from: \(url)")

		func load(_ name: String) -> CIColorKernel {
			guard let kernel = try? CIColorKernel(functionName: name, fromMetalLibraryData: data) else {
				fatalError("Missing kernel: \(name)")
			}
			return kernel
		}
		
		func loadWarp(_ name: String) -> CIWarpKernel {
			guard let kernel = try? CIWarpKernel(functionName: name, fromMetalLibraryData: data) else {
				fatalError("Missing warp kernel: \(name)")
			}
			return kernel
		}
		
		func loadSampler(_ name: String) -> CIKernel {
			guard let kernel = try? CIKernel(functionName: name, fromMetalLibraryData: data) else {
				fatalError("Missing sampler kernel: \(name)")
			}
			return kernel
		}
        
        // Gamut Map
        self.sphGamutMap = load("sphGamutMap")

		// Raw Adjust
		self.encodeSensor = load("encodeSensor")
		self.exposure = load("exposure")
		self.contrast = load("contrast")
		self.globalSaturation = load("globalSaturation")
		self.hdrKernel = load("HDRKernel")
		self.previewHSD = load("previewHueRange")
		self.hsdKernel = load("hsdKernel")
		
		
		// Sony
		self.decodeSLog3 = load("decodeSLog3")
		
		
		// Neg convert
		self.decodeCineon = load("decodeCineon")
		self.halation = load("halation")
		self.grainPlateBlendKernel = load("grainPlateBlendKernel")
		self.decodeNegative = load("decodeNegative")
        self.encodeNegative = load("encodeNegative")
		self.mtfBandKernel = load("mtfBandKernel")
		
		// Scan kernels
		self.offsetRGB = load("offsetRGB")
		self.scanContrast = load("scanContrast")
        self.lift = load("lift")
		
		// Custom helper kernels
		self.scaleWP_BP_withScalar = load("scaleWP_BP_withScalar")
		self.scaleWP_BP = load("scaleWP_BP")
		self.multiplyByValue = load("multiplyByValue")
		self.combineRGBAndInvert = load("combineRGBAndInvert")
		self.returnChannelAndInvert = load("returnChannelAndInvert")
		self.blendWithOpacity = load("blendWithOpacity")
		self.calculateTempFromXY = load("calculateTempFromXY")
        self.arriOverlayBlend = load("arriOverlayBlend")
        self.arriSoftLightBlend = load("arriSoftLightBlend")
		
		// Enlarger
		self.enlargerV2 = load("enlargerV2")
        self.enlargerV2Masked = load("enlargerV2Masked")
		self.enlargerBW = load("enlargerBW")
		self.legacyEnlarger = load("legacyEnlarger")
		self.legacyPrintCurve = load("legacyPrintCurve")
		self.legacyGrade0Curve = load("legacyGrade0Curve")
		self.ilfordCurve = load("ilfordCurve")
		self.mapOutputValues = load("mapOutputValues")
		self.enlargerCurves = load("enlargerCurves")
		self.enlargerOffsets = load("enlargerOffsets")
		self.printCurve = load("printCurve")
		self.enlargerFilter = load("enlargerFiltrationKernel")
		
        // Capture one
        self.convertToC1 = load("convertToC1")
        self.c1ToColorForge = load("c1ToColorForge")
        self.filmStandardToLinear = load("filmStandardToLinear")
		self.applyInverseCurve = load("applyInverseCurve")
		self.transformLut = load("transformLut")
		self.scale0to1 = load("scale0to1")
		self.swapCurves = load("swapCurves")
		
		// ColorSpace
		self.RGBtoYUV = load("RGBtoYUV")
		self.YUVtoRGB = load("YUVtoRGB")
        self.UVtoRGB = load("UVtoRGB")
		self.gamutMap = load("gamutMap")
		self.toneMapLinear = load("toneMapLinear")
		self.adobeCRCurve = load("applyAdobeCameraRawCurveKernel")
		self.rgbToSpherical = load("rgbToSpherical")
		self.sphericalToRgb = load("sphericalToRgb")
        
        // Masking
        self.ditherMask = load("ditherMask")
		self.softenMask = load("softenMask")
		
		// Apply sigmoid smoothing to mask image
		self.applySigmoidSmoothing = load("applySigmoidSmoothing")
		
		
		// Gamma
		self.encodeLogC = load("encodeLogC")
		self.decodeLogC = load("decodeLogC")
        
        self.multiplyTwoImages = load("multiplyTwoImages")
        self.addTwoImages = load("addTwoImages")
        self.evenTile = load("evenTile")
        self.mixGrainAndApply = load("mixGrainAndApply")
        
        // Grain new
        self.returnChannelF3 = load("returnChannelF3")
        self.combineChannelsF3 = load("combineChannelsF3")
        self.blendPaper = load("blendPaper")
        self.smoothStepMetal = load("smoothStepMetal")
        
        self.blendWithMaskMetal = load("blendWithMaskMetal")
		
		// Log Space
		
		self.AWG4_to_LinearP3 = load("AWG4_to_LinearP3")
		
		
		// Realistic grain
		self.realisticFilmGrain = loadSampler("realisticFilmGrain")
		self.copyChannel = load("copyChannel")
		
		self.normaliseGrain = load("normaliseGrain")
        
        
        
        self.perlinNoise = load("perlinNoise")
        self.perlinNoiseColorGradient = load("perlinNoiseColorGradient")
        self.maskPerlinNoise = load("maskPerlinNoise")
        
        self.addMask = load("addMask")
        self.subtractMask = load("subtractMask")
        
        // Mask correction
        self.enlargerGamma = load("enlargerGamma")
		
        
        self.printHalationV2 = load("printHalationV2")
        
        self.edgeAwareFilter = load("edgeAwareFilter")
		
		// Renderer
		self.createBorder = load("createBorder")
        
        self.perlinNoiseMix = load("perlinNoiseMix")
        
        self.grainMix = load("grainMix")
        self.maskGrain = load("maskGrain")
		self.perlinNoiseSmall = load("perlinNoiseSmall")
	}
    
}

// MARK: - ColorSpace Kernels For Extensions


public class RGBtoSPH: CIFilter {
    var inputImage: CIImage?
    
    public override var outputImage: CIImage? {
        guard let input = inputImage else { return nil }
        
        let roiCallback: CIKernelROICallback = { index, rect in rect }
		let kernel = CIColorKernelCache.shared.rgbToSpherical
        
        
        // Pass the converted integers to the Metal kernel
        return kernel.apply(extent: input.extent, roiCallback: roiCallback, arguments: [input])
    }
}


public class SPHtoRGB: CIFilter {
    var inputImage: CIImage?
    
	public override var outputImage: CIImage? {
		guard let input = inputImage else { return nil }
		
		let roiCallback: CIKernelROICallback = { index, rect in rect }
		let kernel = CIColorKernelCache.shared.sphericalToRgb
		
		
		// Pass the converted integers to the Metal kernel
		return kernel.apply(extent: input.extent, roiCallback: roiCallback, arguments: [input])
	}
}


// MARK: - Gamma Kernels


public class EncodeLogC: CIFilter {
	var inputImage: CIImage?
	
	public override var outputImage: CIImage? {
		guard let input = inputImage else { return nil }
		
		let roiCallback: CIKernelROICallback = { index, rect in rect }
		let kernel = CIColorKernelCache.shared.encodeLogC
		
		
		// Pass the converted integers to the Metal kernel
		return kernel.apply(extent: input.extent, roiCallback: roiCallback, arguments: [input])
	}
}

public class DecodeLogC: CIFilter {
	var inputImage: CIImage?
	
	public override var outputImage: CIImage? {
		guard let input = inputImage else { return nil }
		
		let roiCallback: CIKernelROICallback = { index, rect in rect }
		let kernel = CIColorKernelCache.shared.decodeLogC
		
		
		// Pass the converted integers to the Metal kernel
		return kernel.apply(extent: input.extent, roiCallback: roiCallback, arguments: [input])
	}
}



