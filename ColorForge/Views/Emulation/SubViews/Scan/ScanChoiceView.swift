//
//  ScanChoiceView.swift
//  ColorForge
//
//  Created by Ben Quinton on 09/08/2025.
//

import SwiftUI

struct ScanChoiceView: View {
    @Binding var isOn: Bool
    @Binding var isCineon: Bool
    @Binding var isLut: Bool
    @Binding var isImacon: Bool
    @Binding var isMiniLab: Bool

    var body: some View {
        VStack() {
            HStack {
                Spacer()

                ChoiceView(
                    label: "cineon",
                    icon: "film.circle",
                    isOn: $isOn,
                    main: $isCineon,
                    other1: $isLut,
                    other2: $isImacon,
                    other3: $isMiniLab
                )

                Spacer()

                ChoiceView(
                    label: "LUT",
                    icon: "cube",
                    isOn: $isOn,
                    main: $isLut,
                    other1: $isCineon,
                    other2: $isImacon,
                    other3: $isMiniLab
                )

                Spacer()
            }
            
            Spacer()
                .frame(height: 10)

            HStack {
                Spacer()

                ChoiceView(
                    label: "Imacon",
                    icon: "plus.app",
                    isOn: $isOn,
                    main: $isImacon,
                    other1: $isCineon,
                    other2: $isLut,
                    other3: $isMiniLab
                )

                Spacer()

                ChoiceView(
                    label: "Mini Lab",
                    icon: "minus.square",
                    isOn: $isOn,
                    main: $isMiniLab,
                    other1: $isCineon,
                    other2: $isLut,
                    other3: $isImacon
                )

                Spacer()
            }
        }
    }
}


struct ChoiceView: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool
    @Binding var main: Bool
    @Binding var other1: Bool
    @Binding var other2: Bool
    @Binding var other3: Bool
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                if main {
                    // Already selected, so turn it off
                    main = false
                    isOn = false
                } else {
                    // Select this one, turn off others
                    main = true
                    isOn = true
                    other1 = false
                    other2 = false
                    other3 = false
                }
            }
        }) {
            
            Spacer()
                .frame(width: 5)
            
            Image(systemName: icon)
                .font(.caption)
            
            Spacer()
            
            Text(label)
                .foregroundStyle(Color("SideBarText"))
            
            Spacer()
        }
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
        .frame(width: 100)
        .padding(5)
        .background(Color("MenuAccent"))
        .border(main ? Color("IconActive").opacity(0.8) : Color.gray, width: 1)
    }
}
