//
//  CopyHSD.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import SwiftUI

struct CopyHSD: View {
    @Binding var profile: CopyProfile
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = true

    var body: some View {
        CopySettingsCollapsable(
            title: "HSD:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    
                    // Red
                    HStack {
                        Text("Red Hue:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_redHue) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Red Sat:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_redSat) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Red Den:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_redDen) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    // Green
                    HStack {
                        Text("Green Hue:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_greenHue) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Green Sat:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_greenSat) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Green Den:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_greenDen) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    // Blue
                    HStack {
                        Text("Blue Hue:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_blueHue) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Blue Sat:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_blueSat) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Blue Den:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_blueDen) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    // Cyan
                    HStack {
                        Text("Cyan Hue:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_cyanHue) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Cyan Sat:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_cyanSat) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Cyan Den:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_cyanDen) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    // Magenta
                    HStack {
                        Text("Magenta Hue:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_magentaHue) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Magenta Sat:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_magentaSat) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Magenta Den:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_magentaDen) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    // Yellow
                    HStack {
                        Text("Yellow Hue:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_yellowHue) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Yellow Sat:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_yellowSat) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    HStack {
                        Text("Yellow Den:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_yellowDen) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                }
                .onAppear {
                    focusedField = nil
                }
            },
            trailingControl: AnyView(
                Toggle("", isOn: $profile.copy_allHSD)
                    .labelsHidden()
                    .toggleStyle(CopyToggleStyle())
                    .onChange(of: profile.copy_allHSD) { newValue in
                        profile.copy_redHue = newValue
                        profile.copy_redSat = newValue
                        profile.copy_redDen = newValue
                        profile.copy_greenHue = newValue
                        profile.copy_greenSat = newValue
                        profile.copy_greenDen = newValue
                        profile.copy_blueHue = newValue
                        profile.copy_blueSat = newValue
                        profile.copy_blueDen = newValue
                        profile.copy_cyanHue = newValue
                        profile.copy_cyanSat = newValue
                        profile.copy_cyanDen = newValue
                        profile.copy_magentaHue = newValue
                        profile.copy_magentaSat = newValue
                        profile.copy_magentaDen = newValue
                        profile.copy_yellowHue = newValue
                        profile.copy_yellowSat = newValue
                        profile.copy_yellowDen = newValue
                    }
            ),
            resetAction: {
                profile.copy_redHue = false
                profile.copy_redSat = false
                profile.copy_redDen = false
                profile.copy_greenHue = false
                profile.copy_greenSat = false
                profile.copy_greenDen = false
                profile.copy_blueHue = false
                profile.copy_blueSat = false
                profile.copy_blueDen = false
                profile.copy_cyanHue = false
                profile.copy_cyanSat = false
                profile.copy_cyanDen = false
                profile.copy_magentaHue = false
                profile.copy_magentaSat = false
                profile.copy_magentaDen = false
                profile.copy_yellowHue = false
                profile.copy_yellowSat = false
                profile.copy_yellowDen = false
                profile.copy_allHSD = false
            }
        )
    }
}
