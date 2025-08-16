//
//  MTFView.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import SwiftUI

struct MTFView: View {
	@EnvironmentObject var sidebarViewModel: SidebarViewModel
	@EnvironmentObject var viewModel: ImageViewModel
	
	
    @Binding var applyMTF: Bool
    @Binding var mtfBlend: Float
    @Binding var selectedGateWidth: Int // Supplied to both grain and mtf view

	
	@FocusState private var focusedField: String?

	@State private var isCollapsed: Bool = AppDataManager.shared.isCollapsed(for: "MTFView")
	
	@State private var apply: Bool = false
	
    private var gateWidthBinding: Binding<GateWidth> {
        Binding<GateWidth>(
            get: {
                GateWidth(rawValue: selectedGateWidth) ?? .largeFormat54
            },
            set: { newValue in
                selectedGateWidth = newValue.rawValue
            }
        )
    }
    
    enum GateWidth: Int {
        case mediumFormat = 0               // 60.0 mm
        case cropMedium = 1                 // 43.8 mm
        case thirtyFive = 2                 // 36.0 mm
        case halfFrame = 3                  // 18.0 mm
        case motion35Standard = 4           // 21.95 mm
        case motion35Super = 5              // 24.89 mm
        case motion16 = 6                   // 10.26 mm
        case motion8 = 7                    // 4.8 mm
        case motionSuper8 = 8               // 5.79 mm
        case largeFormat54 = 9              // 127 mm
    }

	var body: some View {
		
		SubSection(
			title: "MTF Curve:",
            icon: "drop.triangle",
            checkBoxBinding: $apply,
			isCollapsed: $isCollapsed,
            resetAction: {
                    selectedGateWidth = 0
                    mtfBlend = 50
                    applyMTF = false
                },
			content: {
				VStack() {

					// Format
					HStack {
						// Select Format / Gate Width
                        PopoverGateWidthPicker(selection: gateWidthBinding)
                            
						
					}
					
                    SliderView(
                        label: "Amount:",
                        binding: $mtfBlend,
                        defaultValue: 0,
                        range: 0...100,
                        step: 1,
                        formatter: wholeNumber
                    )

				}
				.onAppear {
					apply = applyMTF
					focusedField = nil
                    
				}
				.onChange(of: isCollapsed) { newValue in
					AppDataManager.shared.setCollapsed(newValue, for: "MTFView")
				}
                .onChange(of: apply) {
                    applyMTF = apply
                }
                .onChange(of: viewModel.currentImgID) {
                    apply = applyMTF
                }
			}
			

		)
	}
    
    private struct PopoverGateWidthPicker: View {
        @Binding var selection: MTFView.GateWidth
        @State private var isPopoverPresented = false

        private struct Option {
            let value: MTFView.GateWidth
            let title: String
            let spec: String
            let pad: CGFloat
            let rowShade: RowShade
            enum RowShade { case dark, light }
        }

        // Display labels/specs derived from your enum comments
        private var options: [Option] {
            [
                .init(value: .largeFormat54,     title: "Large Format",        spec: "5×4 inches",  pad: 0,  rowShade: .dark),
                .init(value: .mediumFormat,      title: "Medium Format",       spec: "60.0 mm",          pad: 2,  rowShade: .light),
                .init(value: .cropMedium,        title: "Crop Medium Format",  spec: "43.8 mm",          pad: 4,  rowShade: .dark),
                .init(value: .thirtyFive,        title: "35mm Still",          spec: "36.0 mm",          pad: 6,  rowShade: .light),
                .init(value: .halfFrame,         title: "Half Frame",          spec: "18.0 mm",          pad: 10, rowShade: .dark),
                .init(value: .motion35Standard,  title: "35mm Std (Motion)",   spec: "21.95 mm",         pad: 8,  rowShade: .light),
                .init(value: .motion35Super,     title: "35mm Super (Motion)", spec: "24.89 mm",         pad: 7,  rowShade: .dark),
                .init(value: .motion16,          title: "16mm (Motion)",       spec: "10.26 mm",         pad: 12, rowShade: .light),
                .init(value: .motion8,           title: "8mm (Motion)",        spec: "4.8 mm",           pad: 14, rowShade: .dark),
                .init(value: .motionSuper8,      title: "Super 8 (Motion)",    spec: "5.79 mm",          pad: 13, rowShade: .light),
            ]
        }

        private var currentLabel: String {
            options.first(where: { $0.value == selection })?.title ?? "Select Format"
        }
        
        private var currentOption: Option? {
            options.first { $0.value == selection }
        }

        var body: some View {
            Button {
                isPopoverPresented.toggle()
            } label: {
                HStack() {
                    Text(currentLabel)
                        .foregroundColor(Color("SideBarText"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)

                    Spacer(minLength: 8)

                    // Selected format icon
                    if let opt = currentOption {
                        Image(systemName: "rectangle")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(opt.pad)
                            .frame(width: 18, height: 18)
                            .foregroundColor(Color("SideBarText"))
                    }

                    Image(systemName: "chevron.down")
                        .foregroundColor(Color("SideBarText").opacity(0.7))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(width: 250)
                .background(Color("MenuAccent"))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.offset) { idx, opt in
                        popoverRow(index: idx, option: opt)
                    }
                }
                .background(Color("MenuAccent"))
                .frame(width: 300)
            }
        }

        @ViewBuilder
        private func popoverRow(index: Int, option: Option) -> some View {
            Button {
                selection = option.value
                isPopoverPresented = false
            } label: {
                HStack(spacing: 8) {
                    Text(option.title)
                        .foregroundColor(Color("SideBarText"))
                    Spacer(minLength: 8)
                    Text(option.spec)
                        .foregroundColor(Color("SideBarText"))
                    Image(systemName: "rectangle")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(option.pad)
                        .frame(width: 30, height: 30)
                        .foregroundColor(Color("SideBarText"))
                }
                .padding(10)
                .background(
                    (option.rowShade == .dark ? Color("MenuAccentDark") : Color("MenuAccentLight"))
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    
    
    
}
