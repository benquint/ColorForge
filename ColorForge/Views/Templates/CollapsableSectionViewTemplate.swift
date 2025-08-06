//
//  CollapsableSectionViewTemplate.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import Foundation
import SwiftUI



struct CollapsableSectionViewTemplate: View {
	@EnvironmentObject var pipeline: FilterPipeline
	@EnvironmentObject var dataModel: DataModel
	@FocusState private var focusedField: String?
	
	/*
	 Search and change "ViewName" for view name
	 */
	
	// Add view name
	@State private var isCollapsed: Bool = AppDataManager.shared.isCollapsed(for: "ViewName")
	
	var bindings: Bindings {
		Bindings(dataModel: dataModel, pipeline: pipeline)
	}
	
	


	var body: some View {
		
		CollapsibleSectionView(
			title: "Exposure:",
			isCollapsed: $isCollapsed,
			content: {
				VStack(alignment: .leading, spacing: 10) {

//					// Exposure Slider
//					HStack {
//						Text("Exposure:")
//							.foregroundStyle(Color("SideBarText"))
//						Spacer()
//						Slider(value: bindings.exposure?.undoable(using: dataModel) ?? .constant(0), in: -4.0...4.0, step: 0.1)
//							.tint(Color("MenuAccent"))
//							.controlSize(.mini)
//							.frame(width: 100)
//
//						
//						TextField("", value: bindings.exposure?.undoable(using: dataModel) ?? .constant(0), formatter: twoDecimal)
//							.textFieldStyle(PlainTextFieldStyle())
//							.frame(width: 35)
//							.background(Color("MenuAccent"))
//							.foregroundColor(Color("SideBarText"))
//							.multilineTextAlignment(.center)
//							.font(.system(.caption, weight: .light))
//							.border(Color.black)
//							.padding(3)
//							.focused($focusedField, equals: "exposure")
//							.onSubmit { focusedField = nil }
//
//						
//						// Reset
//						Button(action: {
//							bindings.exposure?.setUndoable(to: 0, using: dataModel, label: "Reset Exposure")
//						}) {
//							Image(systemName: "arrow.circlepath")
//								.resizable() // Make it resizable
//								.scaledToFit() // Maintain aspect ratio
//								.frame(width: 10, height: 10) // Define an explicit size
//								.foregroundColor(Color("SideBarText"))
//						}
//						.buttonStyle(PlainButtonStyle())
//						.frame(width: 12, height: 12) // Adjust frame size as needed
//					}
//					.padding(5)

				


				}
				.onAppear {
					focusedField = nil
				}
				.onChange(of: isCollapsed) { newValue in
					AppDataManager.shared.setCollapsed(newValue, for: "ViewName")
				}
			},
			resetAction: {
//				bindings.exposure?.setUndoable(to: 0, using: dataModel, label: "Reset Exposure")
			}
		)
	}
}
