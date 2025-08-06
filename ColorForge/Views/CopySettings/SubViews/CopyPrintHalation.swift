//
//  CopyPrintHalation.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import SwiftUI

struct CopyPrintHalation: View {
    @Binding var profile: CopyProfile
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = true

    var body: some View {
        CopySettingsCollapsable(
            title: "Print Halation:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    
                    HStack {
                        Text("Apply:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_printHalation_apply) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    HStack {
                        Text("Darken:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_printHalation_darkenMode) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    HStack {
                        Text("Size:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_printHalation_size) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    HStack {
                        Text("Amount:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_printHalation_amount) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    


                }
                .onAppear {
                    focusedField = nil
                }
            },
            trailingControl: AnyView(
                Toggle("", isOn: $profile.copy_allPrintHalation)
                    .labelsHidden()
                    .toggleStyle(CopyToggleStyle())
                    .onChange(of: profile.copy_allPrintHalation) { newValue in
                        profile.copy_printHalation_size = newValue
                        profile.copy_printHalation_amount = newValue
                        profile.copy_printHalation_darkenMode = newValue
                        profile.copy_printHalation_apply = newValue
                    }
            ),
            resetAction: {
                profile.copy_printHalation_size = false
                profile.copy_printHalation_amount = false
                profile.copy_printHalation_darkenMode = false
                profile.copy_printHalation_apply = false
                profile.copy_allPrintHalation = false
            }
        )
    }
}
