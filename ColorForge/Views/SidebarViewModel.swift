//
//  SidebarViewModel.swift
//  ColorForge
//
//  Created by admin on 26/06/2025.
//

import Foundation
import SwiftUI

class SidebarViewModel: ObservableObject {
	
	
	@Published var whiteBalanceCollapsed: Bool = false
	@Published var rawAdjustCollapsed: Bool = false
	@Published var hdrCollapsed: Bool = false
	@Published var hsdCollapsed: Bool = false
	
	@Published var mtfCollapsed: Bool = false
	@Published var grainCollapsed: Bool = false
	
	
	
	
}
