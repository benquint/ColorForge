//
//  CopySettingsView.swift
//  ColorForge
//
//  Created by Ben Quinton on 05/08/2025.
//

import SwiftUI


struct CopySettingsView: View {
    @Binding var profile: CopyProfile
    
    
    var body: some View {
        
        VStack {
            Spacer()
                .frame(height: 10)
            
            HStack{
                Text("Copy settings:")
                    .foregroundStyle(Color("SideBarText"))
                Spacer()
            }
            .frame(width: 250)
            
            Spacer()
                .frame(height: 20)
            
            
            HStack {
                Text("Select all:")
                    .foregroundStyle(Color("SideBarText"))
                Spacer()
                
                Toggle(isOn: Binding(
                    get: {
                        profile.copy_allWhiteBalance &&
                        profile.copy_allExposure &&
                        profile.copy_allHDR &&
                        profile.copy_allHSD &&
                        profile.copy_allMTF &&
                        profile.copy_allPrintHalation &&
                        profile.copy_allNegConversion &&
                        profile.copy_allEnlarger &&
                        profile.copy_allScan
                    },
                    set: { _ in
                        toggleAllCopySettings()
                    }
                )) {}
                    .toggleStyle(CopyAllToggleStyle())
                    .padding(.trailing, 10)
            }
            .frame(width: 250)
            
            Spacer()
                .frame(height: 20)
            
            
            ScrollView {
                VStack(spacing: 0) {
                    CopyWhiteBalance(profile: $profile)
                        .background(Color("MenuAccentLight"))
                    CopyExposure(profile: $profile)
                        .background(Color("MenuAccentDark"))
                    CopyHDR(profile: $profile)
                        .background(Color("MenuAccentLight"))
                    CopyHSD(profile: $profile)
                        .background(Color("MenuAccentDark"))
                    CopyMTFCurve(profile: $profile)
                        .background(Color("MenuAccentLight"))
                    CopyPrintHalation(profile: $profile)
                        .background(Color("MenuAccentDark"))
                    CopyFilmStock(profile: $profile)
                        .background(Color("MenuAccentLight"))
                    CopyEnlarger(profile: $profile)
                        .background(Color("MenuAccentDark"))
                    CopyScan(profile: $profile)
                        .background(Color("MenuAccentDark"))
                    
                    Spacer()
                }
                .frame(width: 250)
                .frame(maxHeight: .infinity)
                //            .background(Color("BG_Dark"))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        
    }
    
    
    func toggleAllCopySettings() {
        let allSelected =
            profile.copy_allWhiteBalance &&
            profile.copy_allExposure &&
            profile.copy_allHDR &&
            profile.copy_allHSD &&
            profile.copy_allMTF &&
            profile.copy_allPrintHalation &&
            profile.copy_allNegConversion &&
            profile.copy_allEnlarger &&
            profile.copy_allScan

        let newValue = !allSelected

        profile.copy_allWhiteBalance = newValue
        profile.copy_allExposure = newValue
        profile.copy_allHDR = newValue
        profile.copy_allHSD = newValue
        profile.copy_allMTF = newValue
        profile.copy_allPrintHalation = newValue
        profile.copy_allNegConversion = newValue
        profile.copy_allEnlarger = newValue
        profile.copy_allScan = newValue
    }
}

