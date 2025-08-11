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


struct CheckBox: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack {
            Image(systemName: "square.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundStyle(Color("MenuAccentDark"))
                .frame(width: 18)

            Image(systemName: "checkmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .background(Color.clear)
                .foregroundStyle(Color("IconActive"))
                .frame(width: 10)
                .opacity(isOn ? 1.0 : 0.0)
        }
        .contentShape(Rectangle()) // Makes whole ZStack tappable
        .onTapGesture {
            isOn.toggle()
        }
    }
}
