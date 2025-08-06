//
//  File.swift
//  ColorForge Enlarger
//
//  Created by admin on 20/12/2024.
//


import Foundation
import SwiftUI

// Collapsable section with no reset
struct CollapsibleSectionViewNoReset<Content: View>: View {
	let title: String
	@Binding var isCollapsed: Bool
	let content: () -> Content
	let trailingControl: AnyView?  // Optional trailing control, like a toggle


	// Custom initializer
	init(
		title: String,
		isCollapsed: Binding<Bool>,
		@ViewBuilder content: @escaping () -> Content,
		trailingControl: AnyView? = nil  // Default value for optional trailing control
	) {
		self.title = title
		self._isCollapsed = isCollapsed
		self.content = content
		self.trailingControl = trailingControl
	}

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				// Title of the section
				Text(title)
					.foregroundStyle(Color("SideBarText"))
					.padding(.leading, 25)

				Spacer()

				// Optional trailing control (e.g., Toggle), if provided
				if let trailingControl = trailingControl {
					trailingControl
				}
			
				// Collapse/Expand button
				Button(action: {
					isCollapsed.toggle()
				}) {
					Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
						.foregroundColor(Color("SideBarText"))
						.padding(.trailing, 0)
						.background(Color.clear)  // Clear background
				}
				.padding(.trailing, 10)
				.buttonStyle(PlainButtonStyle())
			}
			.padding(.vertical, 10)  // Vertical padding for the header row

			// Content is displayed only when the section is not collapsed
			if !isCollapsed {
				content()  // Render the content
					.padding(.leading, 35)
					.padding(.trailing, 20)
					.padding(.bottom, 10)
			}
		}
		.background(Color.clear)  // Clear background for the whole section
	}
}



