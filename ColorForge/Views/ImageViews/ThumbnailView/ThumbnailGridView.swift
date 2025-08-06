//
//  ThumbnailGridView.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import SwiftUI

struct ThumbnailGridView: View {
	@EnvironmentObject var dataModel: DataModel
	@EnvironmentObject var pipeline: FilterPipeline
	@EnvironmentObject var viewModel: ImageViewModel
	@EnvironmentObject var thumbModel: ThumbnailViewModel

	@Binding var imageViewActive: Bool
	private static let initialColumns = 3
	@State private var isAddingPhoto = false
	@State private var isEditing = false

	@State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)
	@State private var numColumns = initialColumns

	
	@State var counter = 0
	@Binding var selectedMask: UUID?
	
	private let spacing: CGFloat = 10
	
    var body: some View {
		if dataModel.loading && !dataModel.thumbsFullyLoaded {
			ProgressView()
		} else {
			GeometryReader { geo in
				let cellSize = (geo.size.width - thumbModel.padding * CGFloat(thumbModel.colCount + 1)) / CGFloat(thumbModel.colCount)
				ScrollView {
					LazyVGrid(columns: gridColumns) {
						ForEach(dataModel.items) { item in
							


									GridItemView(size: cellSize, item: item) {
										onDoubleTapID(item)
									}
									.cornerRadius(8.0)
									.aspectRatio(1, contentMode: .fit)

//								.cornerRadius(8.0)
//								.aspectRatio(1, contentMode: .fit)
							
						}
					}
					.padding()
				}
				.onAppear{
                    viewModel.thumbViewSize = geo.size
                    recalculateImageFrameSize()
                    
				}
                .onChange(of: geo.size) {
                    viewModel.thumbViewSize = geo.size
                    recalculateImageFrameSize()
                }
			}
		}
			
	}
	


	func onDoubleTapID(_ item: ImageItem) {
		viewModel.currentImage = item.debayeredInit
		viewModel.calculateUIImageSize()
		viewModel.currentImgID = item.id

        dataModel.currentThumb = item.thumbnailImage
		dataModel.currentPreview = item.previewImage
        pipeline.currentURL = item.url
        
        viewModel.nativeWidth = item.nativeWidth
        viewModel.nativeHeight = item.nativeHeight
        viewModel.currentExtent = item.debayeredInit?.extent ?? CGRect.zero
        pipeline.currentHR = item.debayeredFull
        recalculateImageFrameSize() 
		
		if let id = viewModel.currentImgID {
			Task(priority: .userInitiated) {
				await FilterPipeline.shared.applyPipelineV2(id, dataModel)
			}
		}
		
		let width = item.nativeWidth
		let height = item.nativeHeight
		
		viewModel.renderingComplete = false
		
//		DispatchQueue.global(qos: .utility).async {
//			GrainModel.shared.scaleFullSizeGrainPlates(width, height)
//		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			imageViewActive = true
		}
	}
	
	func binding(for id: UUID) -> Binding<ImageItem>? {
		guard let index = dataModel.items.firstIndex(where: { $0.id == id }) else { return nil }
		return $dataModel.items[index]
	}
    
    private func recalculateImageFrameSize() {
        let width = calculateImageWidth()
        let height = calculateImageHeight()
        viewModel.imageFrameSize = CGSize(width: width, height: height)
    }
    
    private func calculateImageWidth() -> CGFloat {
        let width = viewModel.thumbViewSize.width
        let height = viewModel.thumbViewSize.height
        
        guard let img = viewModel.currentImage else {return 0.0}
        
        let imgWidth = img.extent.width
        let imgHeight = img.extent.height
        
        
        let aspectRatio = imgWidth / imgHeight
        let viewAspect = height / height
        
        var scaledWidth: CGFloat = 0
        
        if viewAspect >= 1.0 {
            scaledWidth = ((imgHeight / height) - (2 * viewModel.padding)) * aspectRatio
        } else {
            scaledWidth = (imgWidth / width) - (2 * viewModel.padding)
        }

        return scaledWidth
    }
    
    
    private func calculateImageHeight() -> CGFloat {
        let width = viewModel.thumbViewSize.width
        let height = viewModel.thumbViewSize.height
        
        guard let img = viewModel.currentImage else {return 0.0}
        
        let imgWidth = img.extent.width
        let imgHeight = img.extent.height
        
        
        let aspectRatio = imgWidth / imgHeight
        let viewAspect = height / height
        
        var scaledHeight: CGFloat = 0
        
        if viewAspect >= 1.0 {
            scaledHeight = (imgHeight / height) - (2 * viewModel.padding)
        } else {
            scaledHeight = ((imgHeight / width) - (2 * viewModel.padding)) / aspectRatio
        }
        
        return scaledHeight
    }
    
    
}

/*
 struct GridItemView: View {
	 let size: Double
	 let id: UUID
	 @ObservedObject var model: ContentViewModel
	 let onDoubleTap: () -> Void

	 var body: some View {
		 ZStack {
			 if let item = model.items.first(where: { $0.id == id }) {
				 let image = item.imageObjects.thumbnailImage
				 if image.size.width < 40 {
					 ProgressView()
						 .frame(width: size, height: size)
				 } else {
					 Image(nsImage: image)
						 .resizable()
						 .scaledToFit()
						 .padding(10)
						 .frame(width: size, height: size)
						 .onTapGesture(count: 2) {
							 onDoubleTap()
						 }
				 }
			 }
		 }
	 }
 }
 */
