import SwiftUI

struct CopyWhiteBalance: View {
    @Binding var profile: CopyProfile
    @FocusState private var focusedField: String?
    @State private var isCollapsed: Bool = true

    var body: some View {
        CopySettingsCollapsable(
            title: "White Balance:",
            isCollapsed: $isCollapsed,
            content: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Temp:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_temp) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                    
                    HStack {
                        Text("Tint:")
                            .foregroundStyle(Color("SideBarText"))
                            .font(.caption)
                        Spacer()
                        Toggle(isOn: $profile.copy_tint) {}
                            .toggleStyle(CopyToggleStyle())
                    }
                }
                .onAppear {
                    focusedField = nil
                }
            },
            trailingControl: AnyView(
                Toggle("", isOn: $profile.copy_allWhiteBalance)
                    .labelsHidden()
                    .toggleStyle(CopyToggleStyle())
                    .onChange(of: profile.copy_allWhiteBalance) { newValue in
                        profile.copy_temp = newValue
                        profile.copy_tint = newValue
                    }
            ),
            resetAction: {
                profile.copy_temp = false
                profile.copy_tint = false
                profile.copy_allWhiteBalance = false
            }
        )
    }
}
