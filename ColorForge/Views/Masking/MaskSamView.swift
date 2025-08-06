//
//  MaskSamView.swift
//  ColorForge
//
//  Created by Ben Quinton on 04/08/2025.
//

import SwiftUI

struct MaskSamView: View {
    @Binding var selectedTool: SAMTool?
    var tools: [SAMTool] = [pointTool, boundingBoxTool]
    
    var body: some View {
        
        // Tool selection
        HStack {
            Text("Select Tool:")
            Spacer()
            Picker(selection: $selectedTool, content: {
                ForEach(tools, id: \.self) { tool in
                    Label(tool.name, systemImage: tool.iconName)
                        .tag(tool)
                        .labelStyle(.titleAndIcon)
                }
            }, label: {
            })
            .pickerStyle(.menu)
            .frame(width: 150)
        }
        
        HStack {
            Spacer()
            
            Text("Add")
            
            Spacer()
            
            Text("Subtract")
            
            Spacer()
        }
    }
}

