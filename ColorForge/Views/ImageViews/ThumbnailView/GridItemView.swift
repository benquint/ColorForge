//
//  GridItemView.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import SwiftUI



struct GridItemView: View {
	@EnvironmentObject var dataModel: DataModel
	@EnvironmentObject var pipeline: FilterPipeline
	
	let size: Double
	let item: ImageItem
//	@Binding var item: ImageItem

	let onDoubleTap: () -> Void

	var body: some View {
		ZStack(alignment: .topTrailing) {
			// Fetch thumbnail image from dataModel using item's id
			let image = item.thumbnailImage ?? NSImage()

			Image(nsImage: image)
				.resizable()
				.scaledToFit()
				.padding(10)
				.frame(width: size, height: size)
				.opacity(0)
				.onTapGesture(count: 2) {
					onDoubleTap()
				}
				.task(priority: .high) {
                    await dataModel.debayerFullRes(for: item)
                    
					try? await Task.sleep(nanoseconds: 500_000_000)

					await dataModel.updateThumbAndCacheForItem(for: item)
				}
                .task(priority: .utility) {
                   
                }
		}
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(Color.clear, lineWidth: 7)
		)
	}
}
	
