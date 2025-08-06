//
//  ImageRegistry.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//

import Foundation


final class ImageRegistry {
	static let shared = ImageRegistry()
	
	private(set) var records: [ImportedImageRecord] = []
	
	private let url = AppDataManager.shared.registryURL
	
	private init() {
		load()
	}
	
	func load() {
		guard let data = try? Data(contentsOf: url) else { return }
		if let decoded = try? JSONDecoder().decode([ImportedImageRecord].self, from: data) {
			records = decoded
		}
	}
	
	func save() {
		do {
			let data = try JSONEncoder().encode(records)
			try data.write(to: url)
		} catch {
			print("Failed to save imported image registry: \(error)")
		}
	}
	
	func contains(_ url: URL) -> Bool {
		records.contains(where: { $0.url == url })
	}
	
	func register(url: URL, captureDate: Date, id: UUID) {
		let record = ImportedImageRecord(url: url, captureDate: captureDate, id: id)
		if !records.contains(where: { $0.url == url }) {
			records.append(record)
			save()
		}
	}
}
