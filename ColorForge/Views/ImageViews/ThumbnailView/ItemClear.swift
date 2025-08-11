//
//  ItemClear.swift
//  ColorForge
//
//  Created by admin on 17/07/2025.
//

import SwiftUI

struct ItemClear: View {
	@EnvironmentObject var dataModel: DataModel
	@EnvironmentObject var pipeline: FilterPipeline
	@EnvironmentObject var thumbModel: ThumbnailViewModel
    @EnvironmentObject var viewModel: ImageViewModel
	
	let size: Double
    let item: ImageItem
	let isSelected: Bool
	let onDoubleTap: () -> Void
    
    @State private var tempImage: NSImage? = nil
    @State private var showInfo: Bool = false
    @State private var showVersions: Bool = false
    @State private var isHovering = false
    
    @State private var tomMode: Bool = false
	
	var body: some View {
        
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let backingScaleFactor = screen.backingScaleFactor
        
		ZStack {
            
            ZStack {
                
                if let image = item.thumbnailImage {
                    
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(thumbModel.padding)
                        .frame(width: size, height: size)
                        .opacity(1)
                        .onTapGesture(count: 2) {
                            onDoubleTap()
                        }
                        .onAppear{
                            tempImage = nil
                            updateItem()
                        }
                        .scaleEffect(showInfo ? 1.5 : 1.0)
                        .blur(radius: showInfo ? size / 10 : 0)
                        .animation(.easeInOut(duration: 0.5), value: showInfo)
                    
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: size, height: size)
                        .opacity(showInfo ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: showInfo)
                    
                    ItemInfoView(item: item)
                        .frame(width: size, height: size)
                        .opacity(showInfo ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: showInfo)
                    
                    
                    if thumbModel.saveIDs.contains(item.id) && tomMode {
                        ZStack {

                            Image(item.isSaved ? "tom_saveComplete" : "tom_saving")
                                .resizable()
                                .scaledToFit()
                                .frame(width: size, height:  size)
                                .opacity(1)
                                .animation(.easeInOut(duration: 0.5), value: item.isSaved)
                                .overlay(alignment: .bottomTrailing) {
                                    
                                    ProgressView()
                                        .opacity(item.isSaved ? 0 : 1)
                                        .animation(.easeInOut(duration: 0.3), value: item.isSaved)
                                        .frame(width: 20, height:  20)
                                        .offset(x: -30, y: -20)
                                }
                            
                            
                        }
                        .padding(5)
                        .opacity(viewModel.saveToggled ? 1 : 0)
                        .animation(.easeInOut(duration: 0.75), value: viewModel.saveToggled)
                        
                    }
                    
                    
                }  else if let temp = tempImage {
                    
                    Image(nsImage: temp)
                        .resizable()
                        .scaledToFit()
                        .padding(thumbModel.padding / backingScaleFactor)
                        .frame(width: size, height: size)
                        .opacity(1)
                        .onTapGesture(count: 2) {
                            onDoubleTap()
                        }
                    
                } else {
                    
                    ProgressView()
                        .padding(thumbModel.padding / backingScaleFactor)
                        
                    
                }

                
            } // Inner ZStack
            .frame(width: size - (thumbModel.padding / 2.0), height: size - (thumbModel.padding / 2.0))
            .background(Color(red: 0.22, green: 0.22, blue: 0.22))
            .cornerRadius(8)
            
            
            // MARK: - Save Overlay
            .overlay(alignment: .bottomTrailing) {
                if thumbModel.saveIDs.contains(item.id) && !tomMode {
                    ZStack {
                        ProgressView()
                            .scaleEffect(0.5)
                            .opacity(item.isSaved ? 0 : 1)
                            .animation(.easeInOut(duration: 0.3), value: item.isSaved)
                            .frame(width: 15, height:  15)

                        Image(systemName: "checkmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 15, height:  15)
                            .foregroundColor(.green.opacity(0.75))
                            .opacity(item.isSaved ? 1 : 0)
                            .animation(.easeInOut(duration: 0.3), value: item.isSaved)
                    }
                    .padding(5)
                    .frame(width: 15, height:  15)
                    .opacity(viewModel.saveToggled ? 1 : 0)
                    .animation(.easeInOut(duration: 0.75), value: viewModel.saveToggled)

                }
            }
            
            // MARK: - Info Overlay
            .overlay(alignment: .topLeading) {
                Button(action: {
                    showInfo.toggle()
                }){
                    Image(systemName: showInfo ? "info.circle.fill" : "info.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height:  15)
                        .foregroundColor(showInfo ? Color("IconActive") : Color("SideBarText"))
                        
                }
                .contentShape(Rectangle())
                .opacity(showInfo ? 1.0 : 0.5)
                .buttonStyle(PlainButtonStyle())
                .padding(5)
            }
            
            // MARK: - Versions Overlay
            .overlay(alignment: .topTrailing) {
                Button(action: {
                    showVersions.toggle()
                }){
                    Image(systemName: showVersions || isHovering ? "square.on.square" : "square")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 15, height:  15)
                        .foregroundColor(showVersions  ? Color("IconActive") : Color("SideBarText"))
                        
                }
                .onHover { hovering in
                    isHovering = hovering
                }
                .contentShape(Rectangle())
                .opacity(showVersions || isHovering ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.4), value: isHovering)
                .animation(.easeInOut(duration: 0.4), value: showVersions)
                .buttonStyle(PlainButtonStyle())
                .padding(5)
            }

		}
        .frame(width: size, height: size)
		.overlay(
			RoundedRectangle(cornerRadius: 8)
				.stroke(isSelected ? Color.gray : Color.clear, lineWidth: 4)
		)
        
        .onAppear {
            if item.thumbnailImage == nil {
                Task(priority: .userInitiated) {
                    if let index = dataModel.items.firstIndex(where: { $0.id == item.id }) {
                        // Delay
                        let secs = 0.01 * Double(index)
                        try? await Task.sleep(nanoseconds: UInt64(secs * 1_000_000_000))

                        // Skip if thumbnail now loaded
                        if dataModel.items[index].thumbnailImage != nil {
                            return
                        }

                        let img = await extractThumbTemp()
                        await MainActor.run {
                            tempImage = img
                        }
                    }
                }
            }
        }
	}
	
    

//    

//
    
    private func extractThumbTemp() async -> NSImage? {
        
        let id = item.id
        let url = item.url
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: 500,
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldCacheImmediately: false
        ]
        
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            print("❌ Failed to extract thumbnail for \(url)")
            return nil
        }
        
        let previewImage = NSImage(cgImage: cgImage, size: .zero)
        
        return previewImage
    }

    
    private func updateItem() {
        if viewModel.currentImgID == item.id {
            
            guard let item = dataModel.items.first(where: { $0.id == item.id }) else {return}
            
            guard let processed = item.processImage else {return}
            
            Task (priority: .userInitiated) {
                
                let scale = 500.0 / max(processed.extent.width, processed.extent.height)
                let scaled = processed.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
                
                
                guard let nsImage = await self.convertCIImage_CG(scaled) else {return}
                
                await MainActor.run {
                    dataModel.updateItem(id: item.id) { item in
                        item.thumbnailImage = nsImage
                    }
                }

            }
            
            
        } else {
            return
        }
    }
    
	
	// MUCH QUICKER
	private func convertCIImage_CG(_ input: CIImage) async -> NSImage? {
		let context = RenderingManager.shared.mainImageContext
		
		// Create a CGImage from the CIImage
		guard let cgImage = context.createCGImage(input, from: input.extent) else {
			return nil
		}
		
		// Wrap it in an NSImage
		let size = NSSize(width: cgImage.width, height: cgImage.height)
		let nsImage = NSImage(cgImage: cgImage, size: size)
		return nsImage
	}
    
    

	

	
}

