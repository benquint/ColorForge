//
//  CopyScan.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import SwiftUI

struct CopyScan: View {
    @Binding var profile: CopyProfile
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = true

    var body: some View {
        CopySettingsCollapsable(
            title: "Scan:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    
                    HStack {
                        Text("Apply Scan Mode:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_applyScanMode) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Apply LUT:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_applyPFE) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    HStack {
                        Text("LUT Blend:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_lutBlend) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Scan Contrast:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_scanContrast) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Offset RGB:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_offsetRGB) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Offset Red:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_offsetRed) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Offset Green:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_offsetGreen) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Offset Blue:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_offsetBlue) {}
                            .toggleStyle(CopyToggleStyle())
                    }


                }
                .onAppear {
                    focusedField = nil
                }
            },
            trailingControl: AnyView(
                Toggle("", isOn: $profile.copy_allScan)
                    .labelsHidden()
                    .toggleStyle(CopyToggleStyle())
                    .onChange(of: profile.copy_allScan) { newValue in
                        profile.copy_applyScanMode = newValue
                        profile.copy_applyPFE = newValue
                        profile.copy_offsetRGB = newValue
                        profile.copy_offsetRed = newValue
                        profile.copy_offsetGreen = newValue
                        profile.copy_offsetBlue = newValue
                        profile.copy_scanContrast = newValue
                        profile.copy_lutBlend = newValue
                    }
            ),
            resetAction: {
                profile.copy_applyScanMode = false
                profile.copy_applyPFE = false
                profile.copy_offsetRGB = false
                profile.copy_offsetRed = false
                profile.copy_offsetGreen = false
                profile.copy_offsetBlue = false
                profile.copy_scanContrast = false
                profile.copy_lutBlend = false
                profile.copy_allScan = false
            }
        )
    }
}
