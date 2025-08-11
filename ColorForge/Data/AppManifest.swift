//
//  AppManifest.swift
//  ColorForge
//
//  Created by Ben Quinton on 06/08/2025.
//




import Foundation

// Main app data manifest
struct Manifest: Codable {
    var app: AppManifest
    var images: [ImageManifest]
}

// Will contain user state info
struct AppManifest: Codable {
}


// Manifest to hold urls to look up image settings
struct ImageManifest: Codable, Equatable {
    let imageURL: URL               // Original image file
    let settingsURL: URL           // JSON for SavedImageItem
    let previewURL: URL?           // Optional preview (e.g. cached thumbnail or JPEG)
    let masks: [MaskManifest]
    
    static func == (lhs: ImageManifest, rhs: ImageManifest) -> Bool {
        lhs.imageURL == rhs.imageURL
    }
}

struct MaskManifest: Codable {
    let maskURL: URL
}


class AppDataManager {
    static let shared = AppDataManager()
    
    private let fileManager = FileManager.default
    
    let baseDirectory: URL
    let registryURL: URL
    let settingsFolder: URL
    let imageCacheFolder: URL
    let maskCacheFolder: URL

    private(set) var manifest: Manifest

    // MARK: - Init
    
    private init() {
        // Step 1: Base Application Support location
        let appSupport = try! fileManager.url(for: .applicationSupportDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: true)

        // Step 2: Define folder structure
        let appFolder = appSupport.appendingPathComponent("ColorForge")
        let appDataFolder = appFolder.appendingPathComponent("AppData")
        let imageDataFolder = appFolder.appendingPathComponent("ImageData")
        let settingsFolder = imageDataFolder.appendingPathComponent("Settings")
        let imageCacheFolder = imageDataFolder.appendingPathComponent("ImageCache")
        let maskCacheFolder = imageDataFolder.appendingPathComponent("MaskCache")

        // Step 3: Create folders only if needed
        if !fileManager.fileExists(atPath: appDataFolder.path) {
            try? fileManager.createDirectory(at: appDataFolder, withIntermediateDirectories: true)
        }

        if !fileManager.fileExists(atPath: settingsFolder.path) {
            try? fileManager.createDirectory(at: settingsFolder, withIntermediateDirectories: true)
        }
        
        if !fileManager.fileExists(atPath: imageCacheFolder.path) {
            try? fileManager.createDirectory(at: imageCacheFolder, withIntermediateDirectories: true)
        }
        
        if !fileManager.fileExists(atPath: maskCacheFolder.path) {
            try? fileManager.createDirectory(at: maskCacheFolder, withIntermediateDirectories: true)
        }

        // Step 4: Store persistent folder locations
        self.baseDirectory = appDataFolder
        self.registryURL = appDataFolder.appendingPathComponent("manifest.json")
        self.settingsFolder = settingsFolder
        self.imageCacheFolder = imageCacheFolder
        self.maskCacheFolder = maskCacheFolder
        
        // Step 5: Load or create manifest
        if fileManager.fileExists(atPath: registryURL.path) {
            do {
                let data = try Data(contentsOf: registryURL)
                let decoder = JSONDecoder()
                self.manifest = try decoder.decode(Manifest.self, from: data)
            } catch {
                print("\n\nFailed to load manifest. Starting fresh: \(error)\n\n")
                self.manifest = Manifest(app: AppManifest(), images: [])
                saveManifest(self.manifest)
            }
        } else {
            self.manifest = Manifest(app: AppManifest(), images: [])
            saveManifest(self.manifest)
        }
    }
    
    
    
    // MARK: - Save / Load Manifest

    func saveManifest(_ manifest: Manifest) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(manifest)
            try data.write(to: registryURL, options: .atomic)
        } catch {
            print("Failed to save manifest: \(error)")
        }
    }

    func loadManifest() {
        guard fileManager.fileExists(atPath: registryURL.path) else {
            print("No manifest found at \(registryURL.path)")
            return
        }

        do {
            let data = try Data(contentsOf: registryURL)
            let decoder = JSONDecoder()
            self.manifest = try decoder.decode(Manifest.self, from: data)
        } catch {
            print("Failed to load manifest: \(error)")
        }
    }
    
    
    func addImageManifestIfNeeded(_ newEntry: ImageManifest) {
        // Don't add if one with the same imageURL already exists
        guard !manifest.images.contains(where: { $0.imageURL == newEntry.imageURL }) else {
            print("Manifest already contains entry for \(newEntry.imageURL.lastPathComponent), skipping append.")
            return
        }

        manifest.images.append(newEntry)
        saveManifest(manifest)
        print("Appended new image manifest for: \(newEntry.imageURL.lastPathComponent)")
    }

   
    
    // MARK: - Save Item
    
    func saveSettings(for item: SaveItem) {

        let fileManager = FileManager.default
        let id = item.id

        do {
            let settingsFileURL = settingsFolder.appendingPathComponent("\(id.uuidString).json")
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(item)
            try data.write(to: settingsFileURL, options: .atomic)

            print("Saved settings to: \(settingsFileURL.path)")
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    
    
    
    // MARK: - Collapsable Sections (will move to view, ignore for now)
    

    private var collapsedStateKey: String { "CollapsedSections" }

    func collapsedStates() -> [String: Bool] {
        UserDefaults.standard.dictionary(forKey: collapsedStateKey) as? [String: Bool] ?? [:]
    }

    func setCollapsed(_ collapsed: Bool, for key: String) {
        var states = collapsedStates()
        states[key] = collapsed
        UserDefaults.standard.set(states, forKey: collapsedStateKey)
    }

    func isCollapsed(for key: String) -> Bool {
        collapsedStates()[key] ?? false
    }
}
