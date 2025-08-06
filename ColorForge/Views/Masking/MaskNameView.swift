//
//  MaskNameView.swift
//  ColorForge
//
//  Created by admin on 05/07/2025.
//

import SwiftUI

struct MaskNameView: View {
	@Binding var name: String
	var onSubmit: (String) -> Void

	@FocusState private var isFocused: Bool
	
	var body: some View {
		VStack {
			HStack {
				Text("Name:")
				Spacer()

				TextField("", text: $name)
					.textFieldStyle(PlainTextFieldStyle())
					.frame(width: 400, height: 30)
					.background(Color("MenuAccent"))
					.foregroundColor(Color("SideBarText"))
					.multilineTextAlignment(.center)
					.focused($isFocused)
					.onSubmit {
						onSubmit(name)
					}
			}
			.padding()
		}
		.frame(width: 500, height: 60) // Sets desired content size
		.frame(maxWidth: .infinity, maxHeight: .infinity) // Fills the sheet window
		.background(Color("MenuBackground")) // Ensures full sheet background is filled
		.ignoresSafeArea() // Prevent system insets from interfering
		.onAppear { isFocused = true }
	}

}
