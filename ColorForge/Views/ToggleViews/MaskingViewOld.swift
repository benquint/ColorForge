////
////  MaskingView.swift
////  ColorForge Enlarger
////
////  Created by Ben Quinton on 17/01/2025.
////
//
//import Foundation
//import SwiftUI
//
//
//struct MaskingView: View {
//    @EnvironmentObject var imageProcessingModel: ImageProcessingModel
//    @EnvironmentObject var maskingModel: MaskingModel
//    @State private var isCollapsed = false
//	
//
//    var body: some View {
//        CollapsibleSectionView( // Change as needed to no padding view or no reset view
//            title: "Masking:",
//            isCollapsed: $isCollapsed,
//            content: {
//
//                VStack(spacing: 10) {
//                    
//                    // MARK: - Icons HStack
//                    
//                    HStack{
//                        
//                        // Linear Mask
//                        
//                        VStack {
//                            Button(action: {
//                                maskingModel.drawLinearGradientMask.toggle()
//                            }) {
//                                Image(systemName: "square.bottomhalf.filled")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .foregroundColor(maskingModel.drawLinearGradientMask ? Color("IconActive") : Color("SideBarText"))
//                                    .padding(5)
//                                    .frame(width: 40, height: 40)
//                                    .help("Draw Linear Mask")
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                            
//                            Text("Linear")
//                                .font(.caption)
//                                .foregroundColor(maskingModel.drawLinearGradientMask ? Color("IconActive") : Color("SideBarText"))
//
//                        }
//                        .padding(10)
//                        
//                        // Radial Mask
//                        VStack{
//                        Button(action: {
//							maskingModel.drawRadialGradientMask.toggle()
//						}) {
//                            Image(systemName: "circle.bottomhalf.filled")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .foregroundColor(maskingModel.drawRadialGradientMask ?
//									Color("IconActive") : Color("SideBarText"))
//                                .padding(5)
//                                .frame(width: 40, height: 40)
//                                .help("Draw Linear Mask")
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                            
//                            Text("Radial")
//                                .font(.caption)
//
//                        }
//                        .padding(10)
//                        
//                        
//                        
//                        // Person Mask
//                        VStack {
//                            Button(action: {}) {
//                                Image(systemName: "person.circle")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .foregroundColor(Color("SideBarText"))
//                                    .padding(5)
//                                    .frame(width: 40, height: 40)
//                                    .help("Draw Linear Mask")
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                            
//                            Text("Person")
//                                .font(.caption)
//
//                        }
//                        .padding(10)
//                        
//                        // Sky Mask
//                        VStack {
//                            Button(action: {}) {
//                                Image(systemName: "cloud.sun.circle")
//                                    .resizable()
//                                    .aspectRatio(contentMode: .fit)
//                                    .foregroundColor(Color("SideBarText"))
//                                    .padding(5)
//                                    .frame(width: 40, height: 40)
//                                    .help("Sky")
//                            }
//                            .buttonStyle(PlainButtonStyle())
//                            
//                            Text("Linear")
//                                .font(.caption)
//
//                        }
//                        .padding(10)
//                        
//                    } // End of Icons
//                    
//                    Divider().overlay(Color("MenuAccent"))
//                    
//                    // MARK: - Masking options
//					
////					
////					HStack {
////						Text("Invert Mask:")
////							.foregroundStyle(Color("SideBarText"))
////						Spacer()
////						
////						// Toggle
////						Toggle("", isOn: $maskingModel.isMaskInverted)
////							.toggleStyle(SwitchToggleStyle())
////							.labelsHidden()
////							.padding(.trailing, 0)
////						
////					}
////					.padding(10)
////					
//					
//					HStack {
//						Text("Feather Mask:")
//							.foregroundStyle(Color("SideBarText"))
//						Spacer()
//						
//						Slider(value: $maskingModel.feather, in: 0...100)
//							.tint(Color("MenuAccent"))
//							.controlSize(.mini)
//							.frame(width: 100)
//						TextField("", value: $maskingModel.feather, formatter: NumberFormatter())
//							.textFieldStyle(PlainTextFieldStyle())
//							.frame(width: 35)
//							.background(Color("MenuAccent"))
//							.foregroundColor(Color("SideBarText"))
//							.multilineTextAlignment(.center)
//							.font(.system(.caption, weight: .light))
//							.border(Color.black)
//							.padding(3)
//						
//					}
//					.padding(10)
//					
//					
//					
//				// MARK: - Individual mask options
//					
//					
//					if maskingModel.allMasks.isEmpty {
//						Text("No masks available")
//							.foregroundColor(.gray)
//							.font(.caption)
//							.padding()
//					} else {
//						ForEach(Array(maskingModel.allMasks.enumerated()), id: \.element.id) { index, mask in
//							HStack {
//								// Mask name text field
//								TextField(
//									"",
//									text: Binding(
//										get: { mask.name },
//										set: { newName in
//											maskingModel.renameMask(id: mask.id, newName: newName)
//										}
//									)
//								)
//								.font(.caption)
//								.foregroundColor(.white)
//								.background(Color.clear)
//
//								Spacer()
//
//								// Preview button
//								Button(action: {
//									if maskingModel.selectedMaskID == mask.id {
//										maskingModel.showMask.toggle()
//									} else {
//										maskingModel.selectedMaskID = mask.id // Set the selected mask
//										maskingModel.showMask = true // Enable the preview for the selected mask
//									}
//
//									maskingModel.showSelectedMask(selectedMaskID: mask.id)
//								}) {
//									Image(systemName: (maskingModel.selectedMaskID == mask.id && maskingModel.showMask) ? "eye.fill" : "eye")
//										.foregroundColor((maskingModel.selectedMaskID == mask.id && maskingModel.showMask) ? Color("IconActive") : Color("SideBarText"))
//								}
//								.buttonStyle(PlainButtonStyle())
//								
//								// Invert button
//								Button(action: {
//									if maskingModel.selectedMaskID == mask.id {
//										maskingModel.isMaskInverted.toggle()
//									} else {
//										maskingModel.selectedMaskID = mask.id // Set the selected mask
//										maskingModel.isMaskInverted = true // Enable the preview for the selected mask
//									}
//
//								}) {
//									Image(systemName: (maskingModel.selectedMaskID == mask.id && maskingModel.isMaskInverted) ? "circle.righthalf.filled" : "circle.lefthalf.filled")
//										.foregroundColor((maskingModel.selectedMaskID == mask.id && maskingModel.isMaskInverted) ? Color("IconActive") : Color("SideBarText"))
//								}
//								.buttonStyle(PlainButtonStyle())
//
//
//								// Delete button
//								Button(action: {
//									maskingModel.deleteMask(withID: mask.id)
//								}) {
//									Image(systemName: "trash")
//										.foregroundColor(.red)
//								}
//								.buttonStyle(PlainButtonStyle())
//								
//								
//							}
////							.padding(.horizontal)
//							.padding(5)
//							.background(maskingModel.selectedMaskID == mask.id ? Color("Se;ectedMask") : Color.clear)
////							.onTapGesture {
////								// Update selectedMaskID when the HStack is tapped
////								maskingModel.selectedMaskID = mask.id
////								maskingModel.showMask = true // Ensure the mask is shown when selected
////							}
//						}
//					}
//
//					
//					
//					
//                    
//                }
//            },
//            resetAction: {
//                
//            }
//        )
//    }
//    
//
//}
