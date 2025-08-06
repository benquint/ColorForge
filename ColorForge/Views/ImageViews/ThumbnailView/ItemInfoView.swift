//
//  ItemInfoView.swift
//  ColorForge
//
//  Created by Ben Quinton on 06/08/2025.
//

import SwiftUI

struct ItemInfoView: View {
    let item: ImageItem
    
    var body: some View {
        // Placeholder for now
        VStack (alignment: .leading, spacing: 5) {
            Spacer()
                .frame(height: 10)
            // Title:
            Text("\(item.url.lastPathComponent):")
                .foregroundStyle(Color("SideBarText"))
            
            Spacer()
                .frame(height: 10)
            
            let (shutter, aperture, iso, focalLength) = getExifData()
            
            Text("Shutter speed: \(shutter)")
                .foregroundStyle(Color("SideBarText"))
            
            Text("Aperture: \(aperture)")
                .foregroundStyle(Color("SideBarText"))
            
            Text("ISO: \(iso)")
                .foregroundStyle(Color("SideBarText"))
            
            Text("Focal length: \(focalLength)")
                .foregroundStyle(Color("SideBarText"))
            
            
            Spacer()
            
            HStack {
                Spacer()
                
                Text("Full metadata")
                    .foregroundStyle(Color("SideBarText"))
                
                Spacer()
                    .frame(width: 10)
                
                Image(systemName: "arrow.forward")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .foregroundColor(Color("SideBarText"))
                
                
            }
        }
        .padding(20)
    }
    
    private func getExifData() -> (String, String, String, String) {
        guard let exif = item.exifDict else {
            return ("", "", "", "")
        }

        // Shutter speed (extracted from ExposureTime, e.g. 0.008 -> "1/125")
        let shutter: String = {
            if let exposureTime = exif[kCGImagePropertyExifExposureTime] as? Double, exposureTime > 0 {
                let denominator = Int(round(1.0 / exposureTime))
                return "1/\(denominator)"
            }
            return ""
        }()

        // Aperture (f-number)
        let aperture: String = {
            if let fNumber = exif[kCGImagePropertyExifFNumber] as? Double {
                return String(format: "f/%.1f", fNumber)
            }
            return ""
        }()

        // ISO
        let iso: String = {
            if let isoValue = exif[kCGImagePropertyExifISOSpeed] as? [Int], let firstISO = isoValue.first {
                return "ISO \(firstISO)"
            }
            return ""
        }()

        // Focal Length
        let focalLength: String = {
            if let focal = exif[kCGImagePropertyExifFocalLength] as? Double {
                return "\(Int(round(focal)))mm"
            }
            return ""
        }()

        return (shutter, aperture, iso, focalLength)
    }
    
}
