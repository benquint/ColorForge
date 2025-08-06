//
//  Buttons.swift
//  ColorForge
//
//  Created by Ben Quinton on 30/07/2025.
//

import Foundation
import SwiftUI


struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.5 : 1.0)
            .foregroundColor(configuration.isPressed ? Color("SideBarText") : Color("SideBarText"))
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
        
    }
}


