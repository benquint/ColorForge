//
//  ColorForgeApp.swift
//  ColorForge
//
//  Created by Ben Quinton on 21/05/2025.
//

import SwiftUI

@main
struct ColorForgeApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
	@StateObject var pipeline = FilterPipeline()
	@StateObject var dataModel: DataModel
	@StateObject var sam2: SAM2 // Observable object
	let imageViewModel = ImageViewModel.shared
	let thumbnailViewModel = ThumbnailViewModel.shared
	@StateObject var sidebarViewModel = SidebarViewModel()

	init() {
		// Must initialize this before `@StateObject` vars
		let pipeline = FilterPipeline()
		let dataModel = DataModel(pipeline: pipeline)
		let sam2 = SAM2()  // Starts loading CoreML models asynchronously
		

		_dataModel = StateObject(wrappedValue: dataModel)
		_pipeline = StateObject(wrappedValue: pipeline)
		_sam2 = StateObject(wrappedValue: sam2)
        

		// Initialize singletons
		_ = BatchRenderer.shared
		_ = LutModel.shared
		_ = RenderingManager.shared
		_ = CIColorKernelCache.shared
		_ = GrainModel.shared
		_ = WhiteBalanceModel.shared
		_ = AppDataManager.shared
        _ = PaperModel.shared
        _ = SaveModel.shared

		print("LutModel, RenderingManager, and KernelCache initialized.")
	}

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environmentObject(dataModel)
				.environmentObject(pipeline)
				.environmentObject(imageViewModel)
				.environmentObject(thumbnailViewModel)
				.environmentObject(sidebarViewModel)
				.environmentObject(sam2)
                .environmentObject(HistogramModel.shared)
                .environmentObject(ShortcutViewModel.shared)
                .environmentObject(SamModel.shared)
                .background(BackgroundWindowModifier())
		}
	}
}



struct BackgroundWindowModifier: NSViewRepresentable {
    typealias NSViewType = NSView  // Fix 1: declare the NSView type

    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            if let window = view.window {
                window.titlebarAppearsTransparent = true
                window.titleVisibility = .hidden
                window.styleMask.insert(.fullSizeContentView)
//                window.isMovableByWindowBackground = true
            }
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
