//
//  InfoView.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import SwiftUI

struct InfoView: View {
	var body: some View {
		ZStack {
			GeometryReader { geo in
				Image("mtfGrad")
					.resizable() // Make it resizable
					.scaledToFill() // Maintain aspect ratio
					.zIndex(0)
				
				HStack (alignment: .top) {
					
					VStack(alignment: .leading, spacing: 0) {
						
						Spacer()
							.frame(height: geo.size.height * 0.15)
						
						Group {
							Text("MTF Curve:\n")
								.font(.system(size: 20))
								.foregroundColor(Color("SideBarText"))
						}
						
						
						// Main Text
						Text("""
	  This filter emulates the Modulation Transfer Function (MTF) of film negatives — a curve that describes how well fine detail is preserved from scene to negative. Rather than artificially sharpening or blurring the image, the MTF curve models the natural sharpness falloff found in analog film, where fine textures lose detail more quickly than coarse ones.
	  
	  Applying the MTF curve restores the characteristic soft roll-off of real film negatives.
	  
	  The Format setting changes the curve shape to match the resolving power of different film formats:
	  • Larger formats (like Medium Format or 35mm still) maintain contrast in finer detail,
	  • Smaller formats (like 8mm or Super 8) fall off more rapidly, producing a softer, more organic look.
	  """)
						.font(.system(size: 13))
						.foregroundColor(Color("SideBarText"))
						.multilineTextAlignment(.leading)
						.fixedSize(horizontal: false, vertical: true)
					}
					.padding(25)
					.frame(width: geo.size.width * 0.6)
					
					Spacer()
					
					Image(systemName: "xmark")
						.resizable()
						.frame(width: 20, height: 20) // Define an explicit size
						.padding(30)
						.foregroundColor(Color("SideBarText"))
						
					
				}
			}
			.background(Color("MenuBackground"))
			.cornerRadius(20)
		}
		.background(Color .white)
		.frame(width: 1067, height: 500)
		
	}
}

#Preview {
    InfoView()
}
