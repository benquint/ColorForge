//
//  ImportedRecord.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import Foundation

struct ImportedImageRecord: Codable, Equatable {
	let url: URL
	let captureDate: Date
	let id: UUID
}
