//
//  AppDataManager.swift
//  ColorForge
//
//  Created by admin on 17/06/2025.
//


/*
 
 This will control the main app data, i.e. remembered UI settings etc, import / export
 
 
 */

import Foundation

struct AppDataManager {
	static let shared = AppDataManager()
	
	private let fileManager = FileManager.default
	
	let baseDirectory: URL
	
	var registryURL: URL {
		baseDirectory.appendingPathComponent("imported-images.json")
	}
	
	private init() {
		let appSupport = try! fileManager.url(for: .applicationSupportDirectory,
											  in: .userDomainMask,
											  appropriateFor: nil,
											  create: true)
		baseDirectory = appSupport.appendingPathComponent("Cache")
		
		try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
	}
	
	
	// Collapsed states
	private var collapsedStateKey: String { "CollapsedSections" }

	// Load collapsed states
	func collapsedStates() -> [String: Bool] {
		UserDefaults.standard.dictionary(forKey: collapsedStateKey) as? [String: Bool] ?? [:]
	}

	// Save a collapsed state for a section
	func setCollapsed(_ collapsed: Bool, for key: String) {
		var states = collapsedStates()
		states[key] = collapsed
		UserDefaults.standard.set(states, forKey: collapsedStateKey)
	}

	// Query a single section
	func isCollapsed(for key: String) -> Bool {
		collapsedStates()[key] ?? false
	}
	
}
