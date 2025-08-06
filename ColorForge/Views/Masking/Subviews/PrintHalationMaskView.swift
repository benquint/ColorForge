////
////  PrintHalationMaskView.swift
////  ColorForge
////
////  Created by admin on 05/07/2025.
////
//
//
//import SwiftUI
//
//struct PrintHalationMaskView: View {
//	@Binding var applyPrintHalation: Bool
//	@Binding var radiusMultiplier: CGFloat
//	@Binding var radiusExponent: CGFloat
//	@Binding var opacityMultiplier: Float
//
//	@FocusState private var focusedField: String?
//	@State private var isCollapsed: Bool = false
//
//	var body: some View {
//		CollapsibleSectionView(
//			title: "Print Halation:",
//			isCollapsed: $isCollapsed,
//			content: {
//				VStack(alignment: .leading, spacing: 10) {
//					HStack {
//						Text("Apply:")
//							.foregroundStyle(Color("SideBarText"))
//						Spacer()
//						Toggle("", isOn: $applyPrintHalation)
//							.toggleStyle(SwitchToggleStyle())
//							.labelsHidden()
//							.padding(.trailing, 0)
//					}
//
//					// Radius
//					SliderView(
//						label: "Radius:",
//						binding: $radiusMultiplier,
//						defaultValue: 50,
//						range: 0...100,
//						step: 1,
//						formatter: twoDecimal
//					)
//					.focused($focusedField, equals: "radiusMultiplier")
//
//					// Fade
//					SliderView(
//						label: "Fade:",
//						binding: $opacityMultiplier,
//						defaultValue: 50,
//						range: 0...100,
//						step: 1,
//						formatter: wholeNumber
//					)
//					.focused($focusedField, equals: "opacityMultiplier")
//				}
//				.onAppear {
//					focusedField = nil
//				}
//				.onChange(of: isCollapsed) { newValue in
//					AppDataManager.shared.setCollapsed(newValue, for: "EnlargerView")
//				}
//			},
//			resetAction: {
//				applyPrintHalation = false
//				radiusMultiplier = 50
//				opacityMultiplier = 50
//			}
//		)
//	}
//}
