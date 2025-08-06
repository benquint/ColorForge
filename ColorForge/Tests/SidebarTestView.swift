//
//  SidebarTestView.swift
//  ColorForge
//
//  Created by admin on 01/07/2025.
//

import Foundation
import SwiftUI

struct SidebarTestView: View {
	@State private var selected: Int = 0
	
	var body: some View {
		VStack {
			Button("Switch View") {
				selected = selected == 0 ? 1 : 0
			}
			
			if selected == 0 {
				RawTestView()
			} else {
				TextureTestView()
			}
		}
		.frame(width: 300)
	}
}
