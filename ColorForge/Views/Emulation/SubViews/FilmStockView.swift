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


	var body: some View {
		
		CollapsibleSectionView(
			title: "Film Stock:",
			isCollapsed: $isCollapsed,
			content: {
				VStack(alignment: .leading, spacing: 10) {

                    // MARK: - Select Stock
					HStack {
						Text("Select Stock:")
							.foregroundStyle(Color("SideBarText"))
						Spacer()
						
						
						// Select Film Stock
						Picker(selection: filmStockBinding, label: Text("Select Film Stock")) {
							Text("Portra 400").tag(Stock.portra400)
							Text("Portra 400 +1").tag(Stock.portra400plus1)
							Text("Portra 400 +2").tag(Stock.portra400plus2)
							Text("Kodak Gold").tag(Stock.kodakGold)
							Text("T-MAX").tag(Stock.tmax)
						}
						.pickerStyle(MenuPickerStyle())
						.labelsHidden()
						.frame(width: 130)
						
						
						
						Spacer()
						
						
                        // MARK: - Apply Grain
						Toggle("", isOn: $convertToNeg)
							.toggleStyle(SwitchToggleStyle())
							.labelsHidden()
							.padding(.trailing, 0)
						
					}
					.padding(5)
		
				}
				.onAppear {
					focusedField = nil
				}
				.onChange(of: isCollapsed) { newValue in
					AppDataManager.shared.setCollapsed(newValue, for: "FilmStockView")
				}
			},
			resetAction: {
				stockChoice = 0
				convertToNeg = false
                bwMode = false
			}
		)
	}
}
