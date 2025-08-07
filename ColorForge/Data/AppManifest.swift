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
    
    static func == (lhs: ImageManifest, rhs: ImageManifest) -> Bool {
        lhs.imageURL == rhs.imageURL
    }
}



class AppDataManager {
    static let shared = AppDataManager()
    
    private let fileManager = FileManager.default
    
    let baseDirectory: URL
    let registryURL: URL
    private(set) var manifest: Manifest

    // MARK: - Init
    
    private init() {
        // Step 1: Set up base directory
        let appSupport = try! fileManager.url(for: .applicationSupportDirectory,
                                              in: .userDomainMask,
                                              appropriateFor: nil,
                                              create: true)

        let appFolder = appSupport.appendingPathComponent("ColorForge")
        let appDataFolder = appFolder.appendingPathComponent("AppData")
        try? fileManager.createDirectory(at: appDataFolder, withIntermediateDirectories: true)

        self.baseDirectory = appDataFolder
        self.registryURL = appDataFolder.appendingPathComponent("manifest.json")

        // Step 2: Load or create manifest
        if fileManager.fileExists(atPath: registryURL.path) {
            do {
                let data = try Data(contentsOf: registryURL)
                let decoder = JSONDecoder()
                self.manifest = try decoder.decode(Manifest.self, from: data)
            } catch {
                print("Failed to load manifest. Starting fresh: \(error)")
                self.manifest = Manifest(app: AppManifest(), images: [])
                saveManifest(self.manifest)
            }
        } else {
            self.manifest = Manifest(app: AppManifest(), images: [])
            saveManifest(self.manifest)
        }
        
        // Step 3: Restore security-scoped directories
        let restoredDirectories = restoreAllWorkingDirectories()
        print("Restored \(restoredDirectories.count) security-scoped directories.")
    }
    
    // MARK: - Security Scoped Bookmarks
    
    
    // Saves url as security scoped bookmark
    func addBookmark(for directory: URL) {
        do {
            let data = try directory.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            var existing = Preferences.bookmarkedDirectories

            // Avoid duplicates by checking against existing bookmark data (if needed)
            if !existing.contains(data) {
                existing.append(data)
                Preferences.bookmarkedDirectories = existing
            }
        } catch {
            print("Failed to create bookmark for directory \(directory): \(error)")
        }
    }
    
    @discardableResult
    func restoreAllWorkingDirectories() -> [URL] {
        var urls: [URL] = []

        for bookmarkData in Preferences.bookmarkedDirectories {
            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: bookmarkData,
                                  options: [.withSecurityScope],
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &isStale)
                if url.startAccessingSecurityScopedResource() {
                    urls.append(url)
                } else {
                    print("Failed to access security scoped resource at \(url)")
                }
            } catch {
                print("Failed to resolve bookmark: \(error)")
            }
        }

        return urls
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
    

   
    
    // MARK: - Save Item

    /*
     Example usage:
     
     let saveItem = SaveImageItem(...)  // however you generate it
     saveSettings(for: saveItem)
     
     */
    
    func saveSettings(for item: SaveItem) {
        let fileManager = FileManager.default
        
        let id = item.id
        
        
        // Step 1: Parent folder (where the image came from)
        let imageFolder = item.url.deletingLastPathComponent()
        
        // Step 2: ColorForge folder structure
        let colorForgeFolder = imageFolder.appendingPathComponent("ColorForge")
        let settingsFolder = colorForgeFolder.appendingPathComponent("SettingsCache")
        let sessionFolder = colorForgeFolder.appendingPathComponent("SessionCache")
        let imageCacheFolder = colorForgeFolder.appendingPathComponent("ImageCache")
        
        do {
            // Step 3: Ensure folders exist
            try fileManager.createDirectory(at: settingsFolder, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: sessionFolder, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: imageCacheFolder, withIntermediateDirectories: true)
            
            // Step 4: Build save path
            let settingsFileURL = settingsFolder.appendingPathComponent("\(id.uuidString).json")
            
            // Step 5: Save the file
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
