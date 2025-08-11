//
//  SubSection.swift
//  ColorForge
//
//  Created by Ben Quinton on 08/08/2025.
//

import SwiftUI

struct SubSection<Content: View>: View {
    let title: String
    let icon: String
    let checkBoxBinding: Binding<Bool>? // optional binding
    @Binding var isCollapsed: Bool
    let resetAction: () -> Void
    let content: () -> Content
    
    

    init(
        title: String,
        icon: String,
        checkBoxBinding: Binding<Bool>? = nil, // default to nil
        isCollapsed: Binding<Bool>,
        resetAction: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.checkBoxBinding = checkBoxBinding
        self._isCollapsed = isCollapsed
        self.resetAction = resetAction
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            
            Spacer()
                .frame(height: 15)
            
            
            HStack {
                
                Image(systemName: icon)
                    .foregroundStyle(Color("SideBarText"))
                
                
                // Title of the section
                Text(title)
                //                    .font(.title3)
                    .foregroundStyle(Color("SideBarText"))
                
                
                Spacer()
                    .frame(width: 10)
                
                if let binding = checkBoxBinding {
                    CheckBox(isOn: binding)
                }
                
                Spacer()
                
                
                // Reset button (arrow.circlepath)
                Button(action: {
                    resetAction()  // Invoke the reset action when the button is pressed
                }) {
                    Image(systemName: "arrow.uturn.left")
                        .foregroundColor(Color("SideBarText"))  // Modify color for SideBarText
                    //                        .font(.title3)
                }
                .buttonStyle(PlainButtonStyle())  // Ensures no default button styling is applied
                
                // Collapse/Expand button
                Button(action: {
                    isCollapsed.toggle()
                }) {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .foregroundColor(Color("SideBarText"))
                    //                        .font(.title3)
                    
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
                .frame(height: 15)
            
            // Content is displayed only when the section is not collapsed
            if !isCollapsed {
                content()  // Render the content
            }
            
            Spacer()
                .frame(height: 15)
        }
        .background(Color.clear)  // Clear background for the whole section
        .padding(.horizontal, 20)
    }
}
