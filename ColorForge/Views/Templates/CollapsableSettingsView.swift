//
//  CollapsableSettingsView.swift
//  ColorForge Enlarger
//
//  Created by admin on 27/01/2025.
//

import SwiftUI


struct CollapsableSettingsView<Content: View>: View {
	let title: String
	@Binding var isCollapsed: Bool
	let section: String // Section identifier
	let content: () -> Content



	// Computed binding for selectAll based on section
	private var selectAllBinding: Binding<Bool>

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Text(title)
					.foregroundStyle(Color("SideBarText"))
					.padding(.leading, 10)

				Spacer()

				Text("Select All:")
					.foregroundStyle(Color("SideBarText"))

				Toggle(isOn: selectAllBinding) {
					Text("")
						.foregroundStyle(Color("SideBarText"))
				}
				.toggleStyle(.checkbox)
				.padding(.trailing, 10)

				Button(action: {
					isCollapsed.toggle()
				}) {
					Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
						.foregroundColor(Color("SideBarText"))
						.padding(.trailing, 0)
						.background(Color.clear)
						.frame(width: 20)
				}
				.buttonStyle(PlainButtonStyle())
				.padding(.trailing, 18)
			}
			.padding(.vertical, 10)

			if !isCollapsed {
				content()
					.padding(.leading, 10)
					.padding(.trailing, 20)
					.padding(.bottom, 10)
			}
		}
		.background(Color.clear)
	}
}


