//
//  ImageView2.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import SwiftUI

struct ImageView: View {
	@EnvironmentObject var pipeline: FilterPipeline
	@EnvironmentObject var dataModel: DataModel
	@EnvironmentObject var viewModel: ImageViewModel
	
	@Binding var image: CIImage?
	@State private var renderer: Renderer?
	
	@State private var linearStart: CGPoint = .zero
	@State private var linearEnd: CGPoint = .zero
	
	private var url: URL? {
		guard let url = pipeline.currentURL else {return nil}
		return url
	}

	@Binding var selectedMask: UUID?
	@Binding var LinearStartPointBinding: CGPoint
	@Binding var LinearEndPointBinding: CGPoint
	
    // Radial mask bindings
    @Binding var radialStartPointBinding: CGPoint
    @Binding var radialEndPointBinding: CGPoint
    @Binding var radialFeatherBinding: Float
    @Binding var radialWidthBinding: CGFloat
    @Binding var radialHeightBinding: CGFloat
    @Binding var radialRotationBinding: Float
    @Binding var radialInvertBinding: Bool
    @Binding var radialOpacityBinding: Float
	
	@Binding var selectedTool: SAMTool?
	
	var body: some View {
		GeometryReader { geo in
			ZStack {
				if let renderer = renderer {
					MetalView(renderer: renderer)
						.contentShape(Rectangle())
						.onChange(of: geo.size) { size in
							renderer.requestRedraw()
						}
				} else {
					Text("Renderer not available")
						.foregroundColor(.red)
						.onAppear {
							print("ImageView2: renderer is nil!")
						}
				}
				
                
                if viewModel.sam2MaskMode {
                    
                    SamView(viewWidth: geo.size.width, viewHeight: geo.size.height,
                            selectedTool: $selectedTool)
                    
                } else {
                    
                    // Overlay view for normal masks
                    ImageOverlayView(
                        viewWidth: geo.size.width,
                        viewHeight: geo.size.height,
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
                        radialOpacityBinding: $radialOpacityBinding
                    )
                }
				
				
			}// End of ZStack
		}
		.padding(0)
		.background(Color .white)
		.onAppear {
            
            viewModel.imageViewActive = true
            
			// Reuse the shared renderer if it exists, otherwise create a new one
			if let sharedRenderer = RenderingManager.shared.renderer {
				renderer = sharedRenderer
			} else {
				let newRenderer = Renderer()
				renderer = newRenderer
				RenderingManager.shared.renderer = newRenderer
			}
            
            guard let id = viewModel.currentImgID else {return}
            guard let item = dataModel.items.first(where: { $0.id == id }) else {
                return
            }
            
            if item.debayeredInit != nil {
                FilterPipeline.shared.applyPipelineV2Sync(id, dataModel)
            } else {
                print("No ID for image view")
            }
            

            Task(priority: .utility) {
                await debayerFullRes()
            }
 
		}
		.onDisappear{
            viewModel.imageViewActive = true
            viewModel.drawingLinearMask = false
			dataModel.currentId = nil
            
//            GrainModel.shared.grain54 = nil // Need to handle this better
		}
//        .onChange(of: viewModel.batchProcessComplete) {
//            if viewModel.batchProcessComplete {
//                Task(priority: .utility) {
//                    await debayerFullRes()
//                }
//            }
//        }
	}
	
    
    func debayerFullRes() async {
        
        guard let id = viewModel.currentImgID else { return }
        guard let item = dataModel.items.first(where: { $0.id == id }) else {return}
        let url = item.url
        
        guard item.debayeredFullBuffer == nil else {
            return
        }
        
        let node = DebayerFullNode(rawFileURL: url, scale: 1.0)
        let debayered = node.apply()
        
        let context = RenderingManager.shared.cacheContext
        
        let buffer = await debayered.convertDebayeredToBuffer(context)
        
        await MainActor.run {
            dataModel.updateItem(id: id) { item in
                item.debayeredFullBuffer = buffer
            }
            print("Succesfully assigned full res buffer")
        }
    }

	
	
	private func scalePlatesForExport() {
        guard let id = viewModel.currentImgID else { return }
		
		guard let item = dataModel.items.first(where: { $0.id == id }) else {
			print("savePipeline: No item found for URL \(url)")
			return
		}
		
		let width = item.nativeWidth
		let height = item.nativeHeight
		
		DispatchQueue.global(qos: .utility).async {
			GrainModel.shared.scaleFullSizeGrainPlates(width, height)
		}
	}
    
    
    @State private var tomFlashWorkItem: DispatchWorkItem? = nil
    @State private var tomMode = false

    private func startRandomTomFlashes() {
        cancelRandomTomFlashes()
        
        func scheduleFlash() {
            let workItem = DispatchWorkItem {
                var applyTom = false
                
                // Turn ON
                applyTom = true
                flash(applyTom)
                
                // Turn OFF after 0.2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    applyTom = false
                    flash(applyTom)
                    
                    // After this flash cycle, schedule the next one
                    scheduleFlash()
                }
            }
            
            tomFlashWorkItem = workItem
            
            // Trigger after a random delay
            let randomDelay = Double.random(in: 10...20)
            DispatchQueue.main.asyncAfter(deadline: .now() + randomDelay, execute: workItem)
        }
        
        // Start the first scheduled flash
        scheduleFlash()
    }

    private func cancelRandomTomFlashes() {
        tomFlashWorkItem?.cancel()
        tomFlashWorkItem = nil
    }
    
    private func flash(_ apply: Bool) {
        guard let id = viewModel.currentImgID,
              let item = dataModel.items.first(where: { $0.id == id }),
              let image = item.processImage else {
            return
        }
        var result = image
        
      result = TomJamiesonFilter(applyTom: apply).apply(to: result)
        
        
        if let renderer = RenderingManager.shared.renderer {
            renderer.updateImage(result)
        }
    }


    
    

	
}
