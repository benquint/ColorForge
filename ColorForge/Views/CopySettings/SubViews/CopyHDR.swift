//
//  CopyHDR.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import SwiftUI

struct CopyHDR: View {
    @Binding var profile: CopyProfile
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = true

    var body: some View {
        CopySettingsCollapsable(
            title: "HDR:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("White:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_hdrWhite) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Highlight:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_hdrHighlight) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Shadow:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_hdrShadow) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Black:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_hdrBlack) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                }
                .onAppear {
                    focusedField = nil
                }
            },
            trailingControl: AnyView(
                Toggle("", isOn: $profile.copy_allHDR)
                    .labelsHidden()
                    .toggleStyle(CopyToggleStyle())
                    .onChange(of: profile.copy_allHDR) { newValue in
                        profile.copy_hdrWhite = newValue
                        profile.copy_hdrHighlight = newValue
                        profile.copy_hdrShadow = newValue
                        profile.copy_hdrBlack = newValue
                    }
            ),
            resetAction: {
                profile.copy_hdrWhite = false
                profile.copy_hdrHighlight = false
                profile.copy_hdrShadow = false
                profile.copy_hdrBlack = false
                profile.copy_allHDR = false
            }
        )
    }
}
