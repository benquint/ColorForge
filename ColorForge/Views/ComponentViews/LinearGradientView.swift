//
//  LinearGradientView.swift
//  ColorForge
//
//  Created by admin on 04/07/2025.
//

import SwiftUI

struct LinearGradientView: View {
	@EnvironmentObject private var viewModel: ImageViewModel

	
	@Binding var size: CGSize
	let viewWidth: CGFloat
	let viewHeight: CGFloat
    @Binding var origin: CGPoint
	
	var body: some View {
		ZStack {
			let gradient = LinearGradient(
				gradient: Gradient(colors: [.red.opacity(0.75), .clear]),
                startPoint: UnitPoint(x: (viewModel.uiStartPoint.x - origin.x) / size.width, y: (viewModel.uiStartPoint.y - origin.y) / size.height),
				endPoint: UnitPoint(x: (viewModel.uiEndPoint.x - origin.x) / size.width, y: (viewModel.uiEndPoint.y - origin.y) / size.height)

			)
			
			Rectangle()
				.fill(gradient)
				.frame(width: size.width, height: size.height)
				.allowsHitTesting(false)
			
		}
		.frame(width: viewWidth, height: viewHeight)
		
		
	}
}

