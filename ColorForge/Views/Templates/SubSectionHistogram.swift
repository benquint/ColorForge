//
//  SubSectionHistogram.swift
//  ColorForge
//
//  Created by Ben Quinton on 09/08/2025.
//

import Foundation
import SwiftUI

struct SubSectionHistogram<Content: View>: View {
    let title: String
    @Binding var isCollapsed: Bool
    let content: () -> Content
    
    

    init(
        title: String,
        isCollapsed: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self._isCollapsed = isCollapsed
        self.content = content
    }

    var body: some View {
        VStack(spacing: 0) {
            
            Spacer()
                .frame(height: 15)
            
            
            HStack {
                
                ZStack {
                    Image(systemName: "mountain.2")
                        .foregroundStyle(Color("SideBarText"))
                    
                    Image(systemName: "mountain.2.fill")
                        .foregroundStyle(Color("SideBarText"))
                }
                
                // Title of the section
                Text(title)
                    .foregroundStyle(Color("SideBarText"))
                

                Spacer()
                

                
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
