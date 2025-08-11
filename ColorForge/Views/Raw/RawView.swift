//
//  RawView.swift
//  ColorForge
//
//  Created by admin on 24/06/2025.
//

import Foundation
import SwiftUI


struct RawView: View {
	
    @Binding var temp: Float
    @Binding var tint: Float
    @Binding var initTemp: Float
    @Binding var initTint: Float

    @Binding var exposure: Float
    @Binding var contrast: Float
    @Binding var saturation: Float

    @Binding var hdrWhite: Float
    @Binding var hdrHighlight: Float
    @Binding var hdrShadow: Float
    @Binding var hdrBlack: Float

    @Binding var redHue: Float
    @Binding var redSat: Float
    @Binding var redDen: Float

    @Binding var greenHue: Float
    @Binding var greenSat: Float
    @Binding var greenDen: Float

    @Binding var blueHue: Float
    @Binding var blueSat: Float
    @Binding var blueDen: Float

    @Binding var cyanHue: Float
    @Binding var cyanSat: Float
    @Binding var cyanDen: Float

    @Binding var magentaHue: Float
    @Binding var magentaSat: Float
    @Binding var magentaDen: Float

    @Binding var yellowHue: Float
    @Binding var yellowSat: Float
    @Binding var yellowDen: Float
    
    @Binding var isRawAdjustCollapsed: Bool
	
	var body: some View {
		VStack {
            Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)

            
            Spacer()
                .frame(height: 20)
            
			// White balance / matching view
			WhiteBalanceView(
				temp: $temp,
				tint: $tint,
				initTemp: $initTemp,
				initTint: $initTint
			)

			Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)

			// Raw Adjustment Section
			RawAdjustView(
                exposure: $exposure,
                contrast: $contrast,
                saturation: $saturation,
                isRawAdjustCollapsed: $isRawAdjustCollapsed
            )

				
			
			Divider().overlay(Color("MenuAccent"))
                .frame(height: 3)
//
//			MatchImageView()
//				.environmentObject(imageProcessingModel)
//			
//			Divider().overlay(Color("MenuAccent"))
//
			// HDR Adjustment Section
            HDRView(
                hdrWhite: $hdrWhite,
                hdrHighlight: $hdrHighlight,
                hdrShadow: $hdrShadow,
                hdrBlack: $hdrBlack
            )


			Divider().overlay(Color("MenuAccent"))

			// HSL Adjustment Section
            HSDview(
                redHue: $redHue,
                redSat: $redSat,
                redDen: $redDen,
                greenHue: $greenHue,
                greenSat: $greenSat,
                greenDen: $greenDen,
                blueHue: $blueHue,
                blueSat: $blueSat,
                blueDen: $blueDen,
                cyanHue: $cyanHue,
                cyanSat: $cyanSat,
                cyanDen: $cyanDen,
                magentaHue: $magentaHue,
                magentaSat: $magentaSat,
                magentaDen: $magentaDen,
                yellowHue: $yellowHue,
                yellowSat: $yellowSat,
                yellowDen: $yellowDen
            )

            Divider().overlay(Color("MenuAccent"))

			

			Spacer()
		}
	}
}
