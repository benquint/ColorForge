import SwiftUI

struct CopyExposure: View {
    @Binding var profile: CopyProfile
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = true

    var body: some View {
        CopySettingsCollapsable(
            title: "Exposure:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Exposure:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_exposure) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Contrast:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_contrast) {}
                            .toggleStyle(CopyToggleStyle())
                    }

                    HStack {
                        Text("Saturation:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_saturation) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                }
                .onAppear {
                    focusedField = nil
                }
            },
            trailingControl: AnyView(
                Toggle("", isOn: $profile.copy_allExposure)
                    .labelsHidden()
                    .toggleStyle(CopyToggleStyle())
                    .onChange(of: profile.copy_allExposure) { newValue in
                        profile.copy_exposure = newValue
                        profile.copy_contrast = newValue
                        profile.copy_saturation = newValue
                    }
            ),
            resetAction: {
                profile.copy_exposure = false
                profile.copy_contrast = false
                profile.copy_saturation = false
                profile.copy_allExposure = false
            }
        )
    }
}
