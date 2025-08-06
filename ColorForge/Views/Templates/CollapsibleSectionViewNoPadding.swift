//
//  CollapsibleSectionViewNoPadding.swift
//  ColorForge Enlarger
//
//  Created by admin on 26/09/2024.
//

import Foundation
import SwiftUI

struct CollapsibleSectionViewNoPadding<Content: View>: View {
	let title: String
	@Binding var isCollapsed: Bool
	let content: () -> Content
	let trailingControl: AnyView?  // Optional trailing control, like a toggle
	
	// Reset action that is passed into the view
	let resetAction: () -> Void

	// Custom initializer
	init(
		title: String,
		isCollapsed: Binding<Bool>,
		@ViewBuilder content: @escaping () -> Content,
		trailingControl: AnyView? = nil,  // Default value for optional trailing control
		resetAction: @escaping () -> Void  // Reset action to handle reset functionality
	) {
		self.title = title
		self._isCollapsed = isCollapsed
		self.content = content
		self.trailingControl = trailingControl
		self.resetAction = resetAction
	}

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				// Title of the section
				Text(title)
					.foregroundStyle(Color("SideBarText"))

				Spacer()

				// Optional trailing control (e.g., Toggle), if provided
				if let trailingControl = trailingControl {
					trailingControl
				}
				
				// Reset button (arrow.circlepath)
				Button(action: {
					resetAction()  // Invoke the reset action when the button is pressed
				}) {
					Image(systemName: "arrow.circlepath")
						.foregroundColor(Color("SideBarText"))  // Modify color for SideBarText
				}
				.buttonStyle(PlainButtonStyle())  // Ensures no default button styling is applied

				// Collapse/Expand button
				Button(action: {
					isCollapsed.toggle()
				}) {
					Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
						.foregroundColor(Color("SideBarText"))
						.background(Color.clear)  // Clear background
				}
				.buttonStyle(PlainButtonStyle())
			}
			.padding(.vertical, 10) // Retain vertical padding only

			// Content is displayed only when the section is not collapsed
			if !isCollapsed {
				content()  // Render the content
					.padding(.vertical, 10) // Retain vertical padding
					.frame(maxWidth: .infinity, alignment: .leading) // Remove horizontal padding
			}
		}
		.background(Color.clear)  // Clear background for the whole section
	}
}
