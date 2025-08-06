//
//  CollapsableSectionViewInfo.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import SwiftUI

struct CollapsableSectionViewInfo<Content: View>: View {
	let title: String
	@Binding var isCollapsed: Bool
	let content: () -> Content
	let trailingControl: AnyView?
	let resetAction: () -> Void
	let infoTitle: String
	let infoText: String
	let infoBackgroundImage: String? // optional image name

	@State private var showInfoPopup = false

	init(
		title: String,
		isCollapsed: Binding<Bool>,
		@ViewBuilder content: @escaping () -> Content,
		trailingControl: AnyView? = nil,
		resetAction: @escaping () -> Void,
		infoTitle: String,
		infoText: String,
		infoBackgroundImage: String? = nil
	) {
		self.title = title
		self._isCollapsed = isCollapsed
		self.content = content
		self.trailingControl = trailingControl
		self.resetAction = resetAction
		self.infoTitle = infoTitle
		self.infoText = infoText
		self.infoBackgroundImage = infoBackgroundImage
	}

	var body: some View {
		VStack(spacing: 0) {
			HStack {
				Text(title)
					.foregroundStyle(Color("SideBarText"))
					.padding(.leading, 25)

				Spacer()

				if let trailingControl = trailingControl {
					trailingControl
				}

				Button(action: {
					showInfoPopup = true
				}) {
					Image(systemName: "questionmark")
						.foregroundColor(Color("SideBarText"))
						.padding(.trailing, 5)
				}
				.buttonStyle(PlainButtonStyle())

				Button(action: {
					resetAction()
				}) {
					Image(systemName: "arrow.circlepath")
						.foregroundColor(Color("SideBarText"))
						.padding(.trailing, 5)
				}
				.buttonStyle(PlainButtonStyle())

				Button(action: {
					isCollapsed.toggle()
				}) {
					Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
						.foregroundColor(Color("SideBarText"))
						.padding(.trailing, 0)
				}
				.buttonStyle(PlainButtonStyle())
			}
			.padding(.vertical, 10)

			if !isCollapsed {
				content()
					.padding(.leading, 25)
					.padding(.trailing, 25)
					.padding(.bottom, 10)
			}
		}
		.sheet(isPresented: $showInfoPopup) {
			InfoPopupView(title: infoTitle, bodyText: infoText, backgroundImage: infoBackgroundImage)
		}
		.background(Color.clear)
	}
}

struct InfoPopupView: View {
	let title: String
	let bodyText: String
	let backgroundImage: String?
	
	@Environment(\.dismiss) var dismiss

	var body: some View {
		ZStack {
			GeometryReader { geo in

				if let bg = backgroundImage {
					Image(bg)
						.resizable()
						.scaledToFill()
						.ignoresSafeArea()
				}
				
				HStack(alignment: .top) {
					VStack(alignment: .leading, spacing: 0) {
						Spacer().frame(height: geo.size.height * 0.15)
						Text("\(title):\n")
							.font(.system(size: 20))
							.foregroundColor(Color("SideBarText"))
						
						Text(bodyText)
							.font(.system(size: 13))
							.foregroundColor(Color("SideBarText"))
							.multilineTextAlignment(.leading)
							.fixedSize(horizontal: false, vertical: true)
					}
					.padding(25)
					.frame(width: geo.size.width * 0.6)
					.cornerRadius(20)
					.padding()
					
					Spacer()
					
					Button(action: { dismiss() }) {
						Image(systemName: "xmark")
							.resizable()
							.frame(width: 20, height: 20)
							.padding(30)
							.foregroundColor(Color("SideBarText"))
					}
					.buttonStyle(PlainButtonStyle())
					.background(Color .clear)
				}
			}
			.background(Color("MenuBackground"))
		}
		.ignoresSafeArea()
		.background(Color .clear)
		.frame(width: 1067, height: 500)
	}
}



