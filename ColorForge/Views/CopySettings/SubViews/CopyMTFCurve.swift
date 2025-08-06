//
//  CopyMTFCurve.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import SwiftUI

struct CopyMTFCurve: View {
    @Binding var profile: CopyProfile
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = true

    var body: some View {
        CopySettingsCollapsable(
            title: "MTF Curve:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    
                    HStack {
                        Text("Apply MTF:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_applyMTF) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    HStack {
                        Text("MTF Blend:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_mtfBlend) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    HStack {
                        Text("Gate Width:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_selectedGateWidth) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                }
                .onAppear {
                    focusedField = nil
                }
            },
            trailingControl: AnyView(
                Toggle("", isOn: $profile.copy_allMTF)
                    .labelsHidden()
                    .toggleStyle(CopyToggleStyle())
                    .onChange(of: profile.copy_allMTF) { newValue in
                        profile.copy_applyMTF = newValue
                        profile.copy_mtfBlend = newValue
                        profile.copy_selectedGateWidth = newValue
                    }
            ),
            resetAction: {
                profile.copy_applyMTF = false
                profile.copy_mtfBlend = false
                profile.copy_selectedGateWidth = false
                profile.copy_allMTF = false
            }
        )
    }
}
