//
//  CopyEnlarger.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import SwiftUI

struct CopyEnlarger: View {
    @Binding var profile: CopyProfile
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = true

    var body: some View {
        CopySettingsCollapsable(
            title: "Enlarger:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                
                    
                    HStack {
                        Text("Apply Print Mode:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_applyPrintMode) {}
                            .toggleStyle(CopyToggleStyle()) // Custom tint (mid-grey)
                    }
                    
                    .tint(Color("MenuBackground"))
                    .foregroundColor(Color("Cell_Mid"))
                    .font(.caption)
                    

                    HStack {
                        Text("Exposure:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_enlargerExp) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    HStack {
                        Text("F-Stop:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_enlargerFStop) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Cyan:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_cyan) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Magenta:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_magenta) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Yellow:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_yellow) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                }
                .onAppear {
                    focusedField = nil
                }
            },
            trailingControl: AnyView(
                Toggle("", isOn: $profile.copy_allEnlarger)
                    .labelsHidden()
                    .toggleStyle(CopyToggleStyle())
                    .onChange(of: profile.copy_allEnlarger) { newValue in
                        profile.copy_applyPrintMode = newValue
                        profile.copy_enlargerExp = newValue
                        profile.copy_enlargerFStop = newValue
                        profile.copy_cyan = newValue
                        profile.copy_magenta = newValue
                        profile.copy_yellow = newValue
                    }
            ),
            resetAction: {
                profile.copy_applyPrintMode = false
                profile.copy_enlargerExp = false
                profile.copy_enlargerFStop = false
                profile.copy_cyan = false
                profile.copy_magenta = false
                profile.copy_yellow = false
                profile.copy_allEnlarger = false
            }
        )
    }
}
