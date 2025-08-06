//
//  DataModelExtensions.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import Foundation
import SwiftUI
import AppKit
import ImageIO

extension DataModel {

	
	func updateItem(id: UUID, mutate: @escaping (inout ImageItem) -> Void) {
		guard let index = items.firstIndex(where: { $0.id == id }) else { return }

		DispatchQueue.main.async {
			self.objectWillChange.send()
			var copy = self.items[index]
			mutate(&copy)
			self.items[index] = copy
		}
	}

    
}
