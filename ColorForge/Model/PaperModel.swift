//
//  PaperModel.swift
//  ColorForge
//
//  Created by Ben Quinton on 10/07/2025.
//


import CoreImage
import CoreImage.CIFilterBuiltins
import CoreGraphics
import CoreVideo
import SwiftUI
import AppKit

class PaperModel {
    static let shared = PaperModel()
    
    public var paperEdge: CIImage
    public var blackPaper: CIImage
    public var rebateLarge: CIImage
    public var rebateSmall: CIImage
    
    init() {
        // Load and initialise the textures below
        let textures = Self.loadTextures()
        self.paperEdge = textures.paperEdge
        self.blackPaper = textures.blackPaper
        self.rebateLarge = textures.rebateLarge
        self.rebateSmall = textures.rebateSmall
    }
    
    // MARK: - Load the plates
    
    private static func loadImage(named name: String) -> CIImage {
        guard let url = Bundle.main.url(forResource: name, withExtension: "png"),
              let ciImage = CIImage(contentsOf: url, options: [.applyOrientationProperty: true]) else {
            fatalError("Failed to load texture named \(name).png")
        }
        return ciImage
    }
    
    private static func loadTextures() -> (
        paperEdge: CIImage,
        blackPaper: CIImage,
        rebateLarge: CIImage,
        rebateSmall: CIImage
    ) {
        return (
            paperEdge: loadImage(named: "mask_small"),
            blackPaper: loadImage(named: "blackPaper_noDust"),
            rebateLarge: loadImage(named: "rebate_Large"),
            rebateSmall: loadImage(named: "rebate_Small")
        )
    }
    
    
}
