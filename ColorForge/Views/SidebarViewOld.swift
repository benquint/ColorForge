//
//  SidebarView.swift
//  ColorForge Enlarger
//
//  Created by admin on 13/08/2024.
//

import Foundation
import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var imageProcessingModel: ImageProcessingModel
    @EnvironmentObject var maskingModel: MaskingModel
//    @EnvironmentObject var presetModel: PresetModel
    @EnvironmentObject var scopeModel: ScopeModel
    @EnvironmentObject var adobeXMPModel: AdobeXMPModel
	
	@Binding var isMaskViewVisible: Bool
	@Binding var isCropViewVisible: Bool
	@Binding var isPresetViewVisible: Bool

    // State to toggle between views
    @State private var selectedView: SidebarViewType = .raw

    enum SidebarViewType {
        case raw
        case scan
        case print
        case adjust
        case export
    }

    var body: some View {
        
        VStack {
            VStack {
//				Divider().overlay(Color("MenuAccent"))
                
					HistogramGraphView()
					.environmentObject(imageProcessingModel)

				
//                    HistogramView()
//                    .environmentObject(imageProcessingModel)
                
                    Divider().overlay(Color("MenuAccent"))
                    
                    VectorScopeView()
                        .environmentObject(imageProcessingModel)
                        .environmentObject(scopeModel)
						.onAppear{
							scopeModel.vectorScopeVisible = true
						}
						.onDisappear{
							scopeModel.vectorScopeVisible = false
						}
                
                    Divider().overlay(Color("MenuAccent"))
                    
                    
                    // Icons to toggle between views
                    HStack {
                        
                        
                        VStack {
							Button(action: {
								selectedView = .raw
								rawClick()
								isPresetViewVisible = false
							}
							) {
                                Image(systemName: "slider.horizontal.3")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(!isPresetViewVisible && selectedView == .raw ? Color("IconActive") : Color("SideBarText"))
                                    .padding(5)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(PlainButtonStyle())
							.keyboardShortcut("r", modifiers: [])
                            
                            Text("Raw")
                                .font(.caption)
                                .foregroundColor(!isPresetViewVisible && selectedView == .raw ? Color("IconActive") : Color("SideBarText"))
                        }
                        .padding(10)
                        
                        VStack {
							Button(action: {
								selectedView = .scan
								scanClick()
								isPresetViewVisible = false
							}) {
                                Image(systemName: "scanner")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(!isPresetViewVisible && selectedView == .scan ? Color("IconActive") : Color("SideBarText"))
                                    .padding(5)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(PlainButtonStyle())
							.keyboardShortcut("s", modifiers: [])
                            
                            Text("Scan")
                                .font(.caption)
                            .foregroundColor(!isPresetViewVisible && selectedView == .scan ? Color("IconActive") : Color("SideBarText"))                }
                        .padding(10)
                        
                        VStack {
							Button(action: {
								selectedView = .print
								printClick()
								isPresetViewVisible = false
							}) {
                                Image(!isPresetViewVisible && selectedView == .print ? "PrintIconActive" : "PrintIcon") // Conditional icon
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .padding(5)
                            }
                            .buttonStyle(PlainButtonStyle())
							.keyboardShortcut("p", modifiers: [])
                            
                            Text("Print")
                                .font(.caption)
                                .foregroundColor(!isPresetViewVisible && selectedView == .print ? Color("IconActive") : Color("SideBarText"))
                        }
                        .padding(10)
                        
                        
                        VStack {
							Button(action: {
								selectedView = .export
								exportClick()
								isPresetViewVisible = false
							}) {
                                Image(systemName: "arrow.down.square")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(!isPresetViewVisible && selectedView == .export ? Color("IconActive") : Color("SideBarText"))
                                    .padding(5)
                                    .frame(width: 40, height: 40)
                            }
                            .buttonStyle(PlainButtonStyle())
							.keyboardShortcut("e", modifiers: [])
                            
                            Text("Export")
                                .font(.caption)
                                .foregroundColor(!isPresetViewVisible && selectedView == .export ? Color("IconActive") : Color("SideBarText"))
                        }
                        .padding(10)
                    }
                    .frame(height: 60) // Increased height to allow space for text
                    
                    Divider().overlay(Color("MenuAccent"))
				
				if isCropViewVisible {
					
					
					
					CropView()
						.environmentObject(imageProcessingModel)
						.environmentObject(maskingModel)
						.onAppear{
							isPresetViewVisible = false
						}

					
					Divider().overlay(Color("MenuAccent"))
					
				}
				
				
                
				if isMaskViewVisible {
					MaskingView()
						.environmentObject(imageProcessingModel)
						.environmentObject(maskingModel)
						.onAppear{
							isPresetViewVisible = false
						}
					
					Divider().overlay(Color("MenuAccent"))
					
//					EnlargerSectionView()
//						.environmentObject(imageProcessingModel)
//					
//					Divider().overlay(Color("MenuAccent"))
				}
				

				

                    
//                Divider().overlay(Color("MenuAccent"))

            }


            ScrollView(.vertical) {
                VStack {
					
					
					if isPresetViewVisible {
						PresetView()
							.environmentObject(imageProcessingModel)
							.animation(.easeInOut(duration: 0.3), value: isPresetViewVisible)
					} else {
						
						// Conditional Views
						if selectedView == .raw {
							RawView()
								.environmentObject(imageProcessingModel)
						} else if selectedView == .print {
							PrintView()
								.environmentObject(imageProcessingModel)
						} else if selectedView == .scan {
							ScanMainView()
								.environmentObject(imageProcessingModel)
						} else if selectedView == .export {
							ExportView()
								.environmentObject(imageProcessingModel)
								.environmentObject(adobeXMPModel)
						}
						
					}
                    
                }
            }
			.background(isPresetViewVisible ? Color("MenuAccent").opacity(0.5) : Color.clear)
			.border(isPresetViewVisible ? Color("MenuAccent") : Color.clear, width: 1)
			.cornerRadius(isPresetViewVisible ? 5 : 0)

			
			if isPresetViewVisible {
				Spacer()
			}
        }
        .background(Color("MenuBackground"))
        .frame(maxHeight: .infinity)
		.frame(width: 300)
    }
	
	// MARK: - Click functions
	
	
	private func rawClick() {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Small delay to allow the reset
			withAnimation {
				imageProcessingModel.showRawHelperView = true
			}

			// Hide the helper view after 1 second
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
				withAnimation {
					imageProcessingModel.showRawHelperView = false
				}
			}
		}
	}
	
		private func scanClick() {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Small delay to allow the reset
				withAnimation {
					imageProcessingModel.showScanHelperView = true
				}

				// Hide the helper view after 1 second
				DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
					withAnimation {
						imageProcessingModel.showScanHelperView = false
					}
				}
			}
		}
	
			private func printClick() {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Small delay to allow the reset
					withAnimation {
						imageProcessingModel.showPrintHelperView = true
					}

					// Hide the helper view after 1 second
					DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
						withAnimation {
							imageProcessingModel.showPrintHelperView = false
						}
					}
				}
			}
	
				private func exportClick() {
					DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { // Small delay to allow the reset
						withAnimation {
							imageProcessingModel.showExportHelperView = true
						}

						// Hide the helper view after 1 second
						DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
							withAnimation {
								imageProcessingModel.showExportHelperView = false
							}
						}
					}
				}
	
	
	
}

