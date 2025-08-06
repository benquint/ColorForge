//
//  Toggles.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import Foundation
import SwiftUI

struct CopyToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                ZStack {
                    Image(systemName: "square.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color("MenuAccentDark"))
                        .frame(width: 15, height: 15)
                    
                    
                    Image(systemName: configuration.isOn ? "checkmark" : "square.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(configuration.isOn ? Color("SideBarText") : Color("MenuBackground"))
                        .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
                        .frame(width: 10, height: 10)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct CopyAllToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            Label {
                configuration.label
            } icon: {
                ZStack {
                    Image(systemName: "square.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color("MenuAccentDark"))
                        .frame(width: 15, height: 15)
                    
                    
                    Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(configuration.isOn ? Color("SideBarText").opacity(0.75) : Color("MenuAccentDark"))
                        .accessibility(label: Text(configuration.isOn ? "Checked" : "Unchecked"))
                        .frame(width: 15, height: 15)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
