//
//  TextureView.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import SwiftUI

struct TextureView: View {
	@EnvironmentObject var dataModel: DataModel
	
    @Binding var applyMTF: Bool
    @Binding var mtfBlend: Float

    @Binding var applyGrain: Bool
    @Binding var grainAmount: Float
    @Binding var selectedGateWidth: Int // Supplied to both grain and mtf view
    @Binding var scaleGrainToFormat: Bool

    @Binding var printHalation_size: Float
    @Binding var printHalation_amount: Float
    @Binding var printHalation_darkenMode: Bool
    @Binding var printHalation_apply: Bool

	
	var body: some View {
		VStack {
            
            Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)

            
            Spacer()
                .frame(height: 20)
            
//            TomView(applyTom: applyTom)
//            
//            Divider().overlay(Color("MenuAccent"))
            


            MTFView(
                applyMTF: $applyMTF,
                mtfBlend: $mtfBlend,
                selectedGateWidth: $selectedGateWidth
            )

            Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)

//            GrainView(
//                applyGrain: $applyGrain,
//                grainAmount: $grainAmount,
//                selectedGateWidth: $selectedGateWidth,
//                scaleGrainToFormat: $scaleGrainToFormat
//            )
//
//            Divider().overlay(Color("MenuAccent"))

            PrintHalationView(
                printHalation_size: $printHalation_size,
                printHalation_amount: $printHalation_amount,
                printHalation_darkenMode: $printHalation_darkenMode,
                printHalation_apply: $printHalation_apply
            )
            
            
            Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)
			
//			BordersView(
//				showPaperMask: showPaperMask,
//				borderImgScale: borderImgScale,
//				borderScale: borderScale,
//				borderXshift: borderXshift,
//				borderYshift: borderYshift
//			)
//			
//			
//            Divider().overlay(Color("MenuAccent"))
//                .frame(height: 3)

			Spacer()
		}
	}
	
	
	// Border bindings
	
	private var showPaperMask: Binding<Bool> {
		dataModel.bindingToItem(keyPath: \.showPaperMask, defaultValue: false)
	}
	
	private var borderImgScale: Binding<CGFloat> {
		dataModel.bindingToItem(keyPath: \.borderImgScale, defaultValue: 1.0)
	}
	
	private var borderScale: Binding<CGFloat> {
		dataModel.bindingToItem(keyPath: \.borderScale, defaultValue: 1.0)
	}
	
	private var borderXshift: Binding<CGFloat> {
		dataModel.bindingToItem(keyPath: \.borderXshift, defaultValue: 0.0)
	}
	
	private var borderYshift: Binding<CGFloat> {
		dataModel.bindingToItem(keyPath: \.borderYshift, defaultValue: 0.0)
	}
    
    private var applyTom: Binding<Bool> {
        dataModel.bindingToItem(keyPath: \.applyTom, defaultValue: false)
    }
	

	
}
