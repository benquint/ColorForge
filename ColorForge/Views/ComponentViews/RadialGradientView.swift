//
//  RadialGradientView.swift
//  ColorForge
//
//  Created by admin on 08/07/2025.
//


import SwiftUI

struct RadialGradientView: View {
    @EnvironmentObject private var viewModel: ImageViewModel
    
    
    @Binding var start: CGPoint
    @Binding var end: CGPoint
    @Binding var size: CGSize
    @Binding var width: CGFloat
    @Binding var height: CGFloat
    @Binding var feather: CGFloat
	@Binding var invert: Bool
	let viewWidth: CGFloat
	let viewHeight: CGFloat
	

	


	var body: some View {
		if viewModel.drawingRadialMask {
			
			//			let offset = calculatePaddingOffset()
			
			ZStack {
				// MARK: - Elliptical Gradient
				let backingScale = NSScreen.main?.backingScaleFactor ?? 1.0
				
				
				
				// MARK: - V2
				let rectRadius = min(width, height) / 2.0
				let clampedFeather = max(min(feather, 100), 0.001) // never lower than 0.001%
				let radius0 = rectRadius * (1 - CGFloat(clampedFeather / 100))
				let radius1 = rectRadius
				let scaleX = width / (radius1 * 2)
				let scaleY = height / (radius1 * 2)
				
				
				Circle()
					.fill(
						RadialGradient(
							colors: invert
							? [.clear, .red.opacity(0.75)]
							: [.red.opacity(0.75), .clear],
							center: .center,
							startRadius: radius0,
							endRadius: rectRadius
						)
					)
					.frame(width: radius1 * 2, height: radius1 * 2)
					.scaleEffect(CGSize(width: scaleX, height: scaleY))
					.position(x: start.x, y: start.y)
				
				
				
			}
			.frame(width: viewWidth, height: viewHeight)
			.allowsHitTesting(false)
		}
	}
}
