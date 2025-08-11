//
//  MaskingView.swift
//  ColorForge
//
//  Created by admin on 27/06/2025.
//


import Foundation
import SwiftUI



struct MaskingView: View {
	@EnvironmentObject var pipeline: FilterPipeline
	@EnvironmentObject var viewModel: ImageViewModel
	@EnvironmentObject var dataModel: DataModel
	@FocusState private var focusedField: String?
	
	
	@Binding var selectedMask: UUID?

    // Linear mask bindings
    @Binding var LinearStartPointBinding: CGPoint
    @Binding var LinearEndPointBinding: CGPoint

    @Binding var aiMaskImageBinding: CIImage?
    
    // Radial mask bindings
    @Binding var radialStartPointBinding: CGPoint
    @Binding var radialEndPointBinding: CGPoint
    @Binding var radialFeatherBinding: Float
    @Binding var radialWidthBinding: CGFloat
    @Binding var radialHeightBinding: CGFloat
    @Binding var radialRotationBinding: Float
    @Binding var radialInvertBinding: Bool
    @Binding var radialOpacityBinding: Float
    
    
    @Binding var mainApplyPrint: Bool
	
    @Binding var selectedTool: SAMTool?
    
    @Binding var aiFeatherBinding: Float
    @Binding var aiOpacityBinding: Float
    @Binding var aiInvertBinding: Bool
	
	// MARK: - BODY
	
	
	var body: some View {
		
		
			
			VStack() {
				
				// MARK: - Icons HStack
				
//                MaskIcons(
//                    selectedMask: $selectedMask,
//                    LinearStartPointBinding: $LinearStartPointBinding,
//                    LinearEndPointBinding: $LinearEndPointBinding,
//
//                    radialStartPointBinding: $radialStartPointBinding,
//                    radialEndPointBinding: $radialEndPointBinding,
//                    radialFeatherBinding: $radialFeatherBinding,
//                    radialWidthBinding: $radialWidthBinding,
//                    radialHeightBinding: $radialHeightBinding,
//                    radialRotationBinding: $radialRotationBinding,
//                    radialInvertBinding: $radialInvertBinding,
//                    radialOpacityBinding: $radialOpacityBinding
//                )
				
				
//				Divider().overlay(Color("MenuAccent"))
				
                MaskInfoView(
                    aiMaskImageBinding: $aiMaskImageBinding,
                    selectedMask: $selectedMask,
                    LinearStartPointBinding: $LinearStartPointBinding,
                    LinearEndPointBinding: $LinearEndPointBinding,

                    radialStartPointBinding: $radialStartPointBinding,
                    radialEndPointBinding: $radialEndPointBinding,
                    radialFeatherBinding: $radialFeatherBinding,
                    radialWidthBinding: $radialWidthBinding,
                    radialHeightBinding: $radialHeightBinding,
                    radialRotationBinding: $radialRotationBinding,
                    radialInvertBinding: $radialInvertBinding,
                    radialOpacityBinding: $radialOpacityBinding,
                    
                    selectedTool: $selectedTool,
                    
                    aiFeatherBinding: $aiFeatherBinding,
                    aiOpacityBinding: $aiOpacityBinding,
                    aiInvertBinding: $aiInvertBinding
                )
				
				
				Divider().overlay(Color("MenuAccent"))

				
				// Content to go here wrapped in scrollview
				ScrollView {
					
					// Pass mask bindings
					WhiteBalanceMaskView(
						temp: temp,
						tint: tint,
						initTemp: initTemp,
						initTint: initTint
					)
					
					Divider().overlay(Color("MenuAccent"))

					// Raw Adjustment Section
					RawAdjustMaskView(
						exposure: exposure,
						contrast: contrast,
						saturation: saturation
					)
                    
                    
                    Divider().overlay(Color("MenuAccent"))
                    
                    EnlargerMaskView(
                        applyPrintMode: applyPrintMode,
                        enlargerExp: enlargerExp,
                        enlargerFStop: enlargerFStop,
                        bwMode: bwMode,
                        cyan: cyan,
                        magenta: magenta,
                        yellow: yellow,
                        applyFlash: applyFlash,
                        useLegacy: useLegacy,
                        mainApplyPrint: $mainApplyPrint
                    )

					Divider().overlay(Color("MenuAccent"))

	
					// HDR Adjustment Section
					HDRMaskView(
						hdrWhite: hdrWhite,
						hdrHighlight: hdrHighlight,
						hdrShadow: hdrShadow,
						hdrBlack: hdrBlack
					)
					
					Divider().overlay(Color("MenuAccent"))

					// HSL Adjustment Section
					HSDMaskView(
						redHue: redHue,
						redSat: redSat,
						redDen: redDen,
						greenHue: greenHue,
						greenSat: greenSat,
						greenDen: greenDen,
						blueHue: blueHue,
						blueSat: blueSat,
						blueDen: blueDen,
						cyanHue: cyanHue,
						cyanSat: cyanSat,
						cyanDen: cyanDen,
						magentaHue: magentaHue,
						magentaSat: magentaSat,
						magentaDen: magentaDen,
						yellowHue: yellowHue,
						yellowSat: yellowSat,
						yellowDen: yellowDen
					)
					
					
//					Divider().overlay(Color("MenuAccent"))
//
//					PrintHalationMaskView(
//						applyPrintHalation: applyPrintHalation,
//						radiusMultiplier: radiusMultiplier,
//						radiusExponent: radiusExponent,
//						opacityMultiplier: opacityMultiplier
//					)
					
					

					
					Divider().overlay(Color("MenuAccent"))
					
				}
			
				Spacer()
				
				
			}
//			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.onAppear {
                selectedMask = nil
                viewModel.showMaskPoints = true
                viewModel.selectedMask = nil
				viewModel.maskingActive = true
				focusedField = nil
			}
			.onDisappear {
				selectedMask = nil
				viewModel.showMask = false
				viewModel.selectedMask = nil
                viewModel.maskingActive = false
                viewModel.showMaskPoints = false
			}
		
	}
	
    // MARK: - Private funcs
    
    
    
	
	// MARK: - Mask Bindings
	private var temp: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(5500.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.temp, defaultValue: 5500.0)
	}

	private var tint: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.tint, defaultValue: 0.0)
	}

	private var initTemp: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(5500.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.initTemp, defaultValue: 5500.0)
	}

	private var initTint: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.initTint, defaultValue: 0.0)
	}
	
	
	
	// MARK: - Raw Adjust
	private var exposure: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.exposure, defaultValue: 0.0)
	}

	private var contrast: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.contrast, defaultValue: 0.0)
	}

	private var saturation: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.saturation, defaultValue: 0.0)
	}
	
	
	// MARK: - HDR
	private var hdrWhite: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.hdrWhite, defaultValue: 0.0)
	}

	private var hdrHighlight: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.hdrHighlight, defaultValue: 0.0)
	}

	private var hdrShadow: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.hdrShadow, defaultValue: 0.0)
	}

	private var hdrBlack: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.hdrBlack, defaultValue: 0.0)
	}
	
	

	// MARK: - HSD Values (Mask-Specific)
	private var redHue: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.redHue, defaultValue: 0.0)
	}

	private var redSat: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.redSat, defaultValue: 0.0)
	}

	private var redDen: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.redDen, defaultValue: 0.0)
	}

	private var greenHue: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.greenHue, defaultValue: 0.0)
	}

	private var greenSat: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.greenSat, defaultValue: 0.0)
	}

	private var greenDen: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.greenDen, defaultValue: 0.0)
	}

	private var blueHue: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.blueHue, defaultValue: 0.0)
	}

	private var blueSat: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.blueSat, defaultValue: 0.0)
	}

	private var blueDen: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.blueDen, defaultValue: 0.0)
	}

	private var cyanHue: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.cyanHue, defaultValue: 0.0)
	}

	private var cyanSat: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.cyanSat, defaultValue: 0.0)
	}

	private var cyanDen: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.cyanDen, defaultValue: 0.0)
	}

	private var magentaHue: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.magentaHue, defaultValue: 0.0)
	}

	private var magentaSat: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.magentaSat, defaultValue: 0.0)
	}

	private var magentaDen: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.magentaDen, defaultValue: 0.0)
	}

	private var yellowHue: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.yellowHue, defaultValue: 0.0)
	}

	private var yellowSat: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.yellowSat, defaultValue: 0.0)
	}

	private var yellowDen: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.yellowDen, defaultValue: 0.0)
	}


	
	// MARK: - Enlarger (Mask-Specific)
	private var applyPrintMode: Binding<Bool> {
		guard let maskId = viewModel.selectedMask else { return .constant(false) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.applyPrintMode, defaultValue: false)
	}

	private var convertToNeg: Binding<Bool> {
		guard let maskId = viewModel.selectedMask else { return .constant(false) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.convertToNeg, defaultValue: false)
	}

	private var enlargerExp: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.enlargerExp, defaultValue: 0.0)
	}

	private var enlargerFStop: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(11.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.enlargerFStop, defaultValue: 11.0)
	}

	private var cyan: Binding<Float> {
		guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.cyan, defaultValue: 0.0)
	}

	private var magenta: Binding<Float> {
        guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
        return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.magenta, defaultValue: 0.0)
	}

	private var yellow: Binding<Float> {
        guard let maskId = viewModel.selectedMask else { return .constant(0.0) }
        return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.yellow, defaultValue: 0.0)
	}

	private var bwMode: Binding<Bool> {
		guard let maskId = viewModel.selectedMask else { return .constant(false) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.bwMode, defaultValue: false)
	}

	private var useLegacy: Binding<Bool> {
		guard let maskId = viewModel.selectedMask else { return .constant(true) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.useLegacy, defaultValue: true)
	}

	private var applyFlash: Binding<Bool> {
		guard let maskId = viewModel.selectedMask else { return .constant(false) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.applyFlash, defaultValue: false)
	}
	
	
	// MARK: - Print Halation (Mask-Specific)
	private var printHalation_size: Binding<Float> {
        guard let maskId = viewModel.selectedMask else { return .constant(10.0) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.printHalation_size, defaultValue: 50.0)
	}

	private var printHalation_amount: Binding<Float> {
        guard let maskId = viewModel.selectedMask else { return .constant(50.0) }
        return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.printHalation_amount, defaultValue: 50.0)
	}

    private var printHalation_darkenMode: Binding<Bool> {
        guard let maskId = viewModel.selectedMask else { return .constant(true) }
        return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.printHalation_darkenMode, defaultValue: false)
    }

	private var printHalation_apply: Binding<Bool> {
		guard let maskId = viewModel.selectedMask else { return .constant(false) }
		return dataModel.bindingToMaskValue(maskId: maskId, keyPath: \.printHalation_apply, defaultValue: false)
	}

	

	
	
}
