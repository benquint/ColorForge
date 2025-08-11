//
//  FilmStockView.swift
//  ColorForge
//
//  Created by admin on 27/06/2025.
//

import SwiftUI

struct FilmStockView: View {
    @EnvironmentObject var pipeline: FilterPipeline
    @Binding var convertToNeg: Bool
    @Binding var stockChoice: Int
    @Binding var bwMode: Bool
	@FocusState private var focusedField: String?
	
	
	// Add view name
	@State private var isCollapsed: Bool = AppDataManager.shared.isCollapsed(for: "FilmStockView")

	
    private var filmStockBinding: Binding<Stock> {
        Binding<Stock>(
            get: {
                Stock(rawValue: stockChoice) ?? .portra400
            },
            set: { newValue in
                stockChoice = newValue.rawValue

                let isBW = (newValue == .tmax)
                pipeline.bwMode = isBW
                bwMode = isBW
            }
        )
    }
	
	enum Stock: Int {
		case portra400 = 0
		case portra400plus1 = 1
		case portra400plus2 = 2
		case kodakGold = 3
		case tmax = 4
	}
    
    @State private var isPopoverPresented = false

    private func popoverOption(index: Int, option: StockOption) -> some View {
        Button {
            if let id = option.id {
                stockChoice = id        // <- set pipeline ID, not menu index
                isPopoverPresented = false
            }
        } label: {
            HStack {
                Text(option.name)
                    .foregroundColor(Color("SideBarText"))
                    .opacity(option.isPlaceholder ? 0.8 : 1.0)
                Spacer()
                option.icon
                    .opacity(option.isPlaceholder ? 0.8 : 1.0)
            }
            .padding(10)
            .background(index.isMultiple(of: 2) ? Color("MenuAccentDark") : Color("MenuAccentLight"))
        }
        .buttonStyle(.plain)
        .disabled(option.id == nil) // placeholders not selectable
    }

    private struct StockOption {
        let id: Int?                 // pipeline ID (matches Stock.rawValue); nil for placeholder
        let name: String
        let icon: AnyView
        let isPlaceholder: Bool
    }
    
    private var stockOptions: [StockOption] {
        [
            .init(id: nil,                        name: "Kodak Portra 160",            icon: AnyView(KodakPortra()), isPlaceholder: true),
            .init(id: Stock.portra400.rawValue,   name: "Kodak Portra 400",            icon: AnyView(KodakPortra()), isPlaceholder: false),
            .init(id: Stock.portra400plus1.rawValue, name: "Kodak Portra 400 +1",      icon: AnyView(KodakPortra()), isPlaceholder: false),
            .init(id: Stock.portra400plus2.rawValue, name: "Kodak Portra 400 +2",      icon: AnyView(KodakPortra()), isPlaceholder: false),
            .init(id: nil,                        name: "Kodak Portra 800",            icon: AnyView(KodakPortra()), isPlaceholder: true),
            .init(id: Stock.kodakGold.rawValue,   name: "Kodak Gold",                  icon: AnyView(KodakGold()),   isPlaceholder: false),
            .init(id: Stock.tmax.rawValue,        name: "Kodak TMax",                  icon: AnyView(KodakTMax()),   isPlaceholder: false),
            .init(id: nil,                        name: "Kodak TMax + 1",              icon: AnyView(KodakTMax()),   isPlaceholder: true),
            .init(id: nil,                        name: "Kodak TMax + 2",              icon: AnyView(KodakTMax()),   isPlaceholder: true),
            .init(id: nil,                        name: "Kodak Tri-X",                 icon: AnyView(KodakTrix()),   isPlaceholder: true),
            .init(id: nil,                        name: "Kodak Tri-X + 1",             icon: AnyView(KodakTrix()),   isPlaceholder: true),
            .init(id: nil,                        name: "Kodak Tri-X + 2",             icon: AnyView(KodakTrix()),   isPlaceholder: true),
            .init(id: nil,                        name: "Kodak E100",                  icon: AnyView(KodakE100()),   isPlaceholder: true),
            .init(id: nil,                        name: "Kodak E100 Cross Process",    icon: AnyView(KodakE100()),   isPlaceholder: true),
            .init(id: nil,                        name: "Fujifilm Velvia 100",         icon: AnyView(FujiVelvia()),  isPlaceholder: true),
            .init(id: nil,                        name: "Fujifilm Provia 100",         icon: AnyView(FujiProvia()),  isPlaceholder: true)
        ]
    }
    
    private func labelOption(for id: Int) -> StockOption? {
        stockOptions.first { $0.id == id }
    }

    private func stockName(for id: Int) -> String {
        labelOption(for: id)?.name ?? "Unknown"
    }

    private func stockIcon(for id: Int) -> AnyView {
        labelOption(for: id)?.icon ?? AnyView(EmptyView())
    }


    @State private var apply: Bool = false

	var body: some View {
		
		SubSection(
			title: "Film Stock",
            icon: "film",
            checkBoxBinding: $apply,
			isCollapsed: $isCollapsed,
            resetAction: {
                stockChoice = 0
                convertToNeg = false
                bwMode = false
            },
			content: {
				VStack() {

                    // MARK: - Select Stock
					HStack {

                        Button {
                            isPopoverPresented.toggle()
                        } label: {
                            HStack {
                                Text(stockName(for: stockChoice))
                                    .foregroundColor(Color("SideBarText"))
                                Spacer()
                                stockIcon(for: stockChoice)
                                Image(systemName: "chevron.down")
                                    .foregroundColor(Color("SideBarText"))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .frame(width: 250)
                            .background(Color("MenuAccent"))
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $isPopoverPresented, arrowEdge: .bottom) {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(stockOptions.indices, id: \.self) { idx in
                                    popoverOption(index: idx, option: stockOptions[idx])
                                }
                            }
                            .background(Color("MenuAccent"))
                            .frame(width: 250)
                        }
						
					}
					.padding(5)
		
				}
				.onAppear {
                    apply = convertToNeg
					focusedField = nil
				}
                .onChange(of: convertToNeg) {
                    apply = convertToNeg
                }
                .onChange(of: apply) {
                    convertToNeg = apply
                }
				.onChange(of: isCollapsed) { newValue in
					AppDataManager.shared.setCollapsed(newValue, for: "FilmStockView")
				}
			}

		)
	}
}
