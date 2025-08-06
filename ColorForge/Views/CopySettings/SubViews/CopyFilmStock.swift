//
//  CopyFilmStock.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import SwiftUI

struct CopyFilmStock: View {
    @Binding var profile: CopyProfile
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = true

    var body: some View {
        CopySettingsCollapsable(
            title: "Film Stock:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    
                    HStack {
                        Text("Convert to Neg:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_convertToNeg) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    HStack {
                        Text("Stock Choice:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_stockChoice) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                }
                .onAppear {
                    focusedField = nil
                }
            },
            trailingControl: AnyView(
                Toggle("", isOn: $profile.copy_allNegConversion)
                    .labelsHidden()
                    .toggleStyle(CopyToggleStyle())
                    .onChange(of: profile.copy_allNegConversion) { newValue in
                        profile.copy_convertToNeg = newValue
                        profile.copy_stockChoice = newValue
                    }
            ),
            resetAction: {
                profile.copy_convertToNeg = false
                profile.copy_stockChoice = false
                profile.copy_allNegConversion = false
            }
        )
    }
}
