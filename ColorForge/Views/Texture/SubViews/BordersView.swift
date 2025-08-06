//
//  BordersView.swift
//  ColorForge
//
//  Created by admin on 13/07/2025.
//

import SwiftUI

struct BordersView: View {
	@EnvironmentObject var viewModel: ImageViewModel
	
	@EnvironmentObject var pipeline: FilterPipeline
	@EnvironmentObject var dataModel: DataModel
	
	@Binding var showPaperMask: Bool
	@Binding var borderImgScale: CGFloat
	@Binding var borderScale: CGFloat
	@Binding var borderXshift: CGFloat
	@Binding var borderYshift: CGFloat
	
//	private var showPaperMask: Binding<Bool> {
//		dataModel.bindingToItem(keyPath: \.showPaperMask, defaultValue: false)
//	}
//	
//	private var borderImgScale: Binding<CGFloat> {
//		dataModel.bindingToItem(keyPath: \.borderImgScale, defaultValue: 1.0)
//	}
//	
//	private var borderScale: Binding<CGFloat> {
//		dataModel.bindingToItem(keyPath: \.borderScale, defaultValue: 1.0)
//	}
//	
//	private var borderXshift: Binding<CGFloat> {
//		dataModel.bindingToItem(keyPath: \.borderXshift, defaultValue: 0.0)
//	}
//	
//	private var borderYshift: Binding<CGFloat> {
//		dataModel.bindingToItem(keyPath: \.borderYshift, defaultValue: 0.0)
//	}
	
	
	@FocusState private var focusedField: String?
	@State private var isCollapsed: Bool = false
	@State private var apply: Bool = false

	var body: some View {
		CollapsibleSectionView(
			title: "Borders:",
			isCollapsed: $isCollapsed,
			content: {
				VStack(alignment: .leading, spacing: 10) {
					HStack {
						Text("Show:")
							.foregroundStyle(Color("SideBarText"))
						Spacer()
						
						Toggle("", isOn: $apply)
							.toggleStyle(SwitchToggleStyle())
							.labelsHidden()
							.padding(.trailing, 0)
							.onChange(of: apply) {
								showPaperMask = apply
							}
							.onChange(of: viewModel.currentImgID) {
								apply = showPaperMask
							}
					}
			


					SliderView(
						label: "Image Scale:",
						binding: $borderImgScale,
						defaultValue: 1,
						range: 0...2,
						step: 0.001,
						formatter: twoDecimal
					)
					.focused($focusedField, equals: "$pipeline.imageScale")

					
					
					SliderView(
						label: "Mask Scale:",
						binding: $borderScale,
						defaultValue: 1,
						range: 0...2,
						step: 0.001,
						formatter: twoDecimal
					)
					.focused($focusedField, equals: "$pipeline.maskScale")

					
					SliderView(
						label: "Mask X Shift:",
						binding: $borderXshift,
						defaultValue: 0,
						range: -1...1,
						step: 0.001,
						formatter: wholeNumber
					)
					.focused($focusedField, equals: "pipeline.maskXshift")
					
					SliderView(
						label: "Mask Y Shift:",
						binding: $borderYshift,
						defaultValue: 0,
						range: -1...1,
						step: 0.001,
						formatter: wholeNumber
					)
					.focused($focusedField, equals: "pipeline.maskXshift")
					
				}
				.onAppear {
					focusedField = nil
				}
				.onChange(of: isCollapsed) { newValue in
					AppDataManager.shared.setCollapsed(newValue, for: "EnlargerView")
				}
			},
			resetAction: {
//				applyPrintHalation = false
//				radiusMultiplier = 50
//				opacityMultiplier = 50
			}
		)
	}
}
