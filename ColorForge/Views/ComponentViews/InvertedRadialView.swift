//
//  InvertedRadialView.swift
//  ColorForge
//
//  Created by Ben Quinton on 26/07/2025.
//

import SwiftUI


struct ElipseView: View {
    @EnvironmentObject var viewModel: ImageViewModel
    let viewWidth: CGFloat
    let viewHeight: CGFloat
    let imgSizeUI: CGSize
    

    var body: some View {
        ZStack {
            Ellipse()
                .frame(width: viewModel.radialUiWidth, height: viewModel.radialUiHeight)
                .position(viewModel.radialUiStart)
                .mask(Rectangle()
                    .frame(width: imgSizeUI.width, height: imgSizeUI.height)
                )
        }
        .frame(width: viewWidth, height: viewHeight)
    }
}

extension View {
    @inlinable
    public func reverseMask<Mask: View>(
        alignment: Alignment = .center,
        @ViewBuilder _ mask: () -> Mask
    ) -> some View {
        self.mask {
            ZStack {
                // Base rectangle acts as solid destination for subtraction
                Rectangle()
                    .overlay(alignment: alignment) {
                        mask()
                            .blendMode(.destinationOut)
                    }
            }
            // Force local compositing so .destinationOut only affects this layer
            .compositingGroup()
        }
    }
}


struct InvertedRadialView: View {
    @EnvironmentObject var viewModel: ImageViewModel
    let viewWidth: CGFloat
    let viewHeight: CGFloat
    let imgSizeUI: CGSize

    var body: some View {
        ZStack {
            // Render everything on a transparent background first
            Color.clear
                .overlay {
                    ZStack {
                        // Red fill clipped to image rect
                        Rectangle()
                            .fill(Color.red.opacity(0.75))
                            .frame(width: viewWidth, height: viewHeight)

                        // Subtractive ellipse
                        Ellipse()
                            .frame(width: viewModel.radialUiWidth, height: viewModel.radialUiHeight)
                            .position(viewModel.radialUiStart)
                            .blendMode(.destinationOut)
                    }
                    // Force this whole composition to flatten to a texture
                    .compositingGroup()
                }
        }
        // Apply mask *after* the flatten, so nothing outside leaks or interacts
        .mask(Rectangle()
            .frame(width: imgSizeUI.width, height: imgSizeUI.height)
        )
        .frame(width: viewWidth, height: viewHeight)
    }
}
