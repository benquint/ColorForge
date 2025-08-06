//
//  RendererExtensions.swift
//  ColorForge
//
//  Created by admin on 29/07/2025.
//

import CoreImage
import Foundation


extension CIImage {
	
	
	func addBorders(_ originX: Float, _ originY: Float, _ width: Float, _ height: Float) -> CIImage {
		let border = self
		
		let kernel = CIColorKernelCache.shared.createBorder
		return kernel.apply(
			extent: self.extent,
			roiCallback: {$1},
			arguments: [self, originX, originY, width, height]
		) ?? self
	}
	
	
}
