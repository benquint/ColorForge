//
//  ShortcutView.swift
//  ColorForge
//
//  Created by Ben Quinton on 06/08/2025.
//

import SwiftUI

class ShortcutViewModel: ObservableObject {
    static let shared = ShortcutViewModel()
    
    @Published var showHelpers: Bool = false
    @Published var showView: Bool = false
    @Published var keys: [String] = []
    @Published var modifiers: [EventModifiers] = []
    private var isInitialLoad = true
   
    func show(_ shortcut: AppShortcut) {
        keys = shortcut.keys
        modifiers = shortcut.modifiers
        
        if isInitialLoad {
            showView = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.showView = true
                self.isInitialLoad = false
                self.autoHide()
            }
        } else {
            showView = true
            autoHide()
        }
    }

    private func autoHide() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.showView = false
        }
    }
    enum AppShortcut {
        case rawAdjustView
        case emulationView
        case textureView
        case showMaskingView
        case toggleImageView
        case hideSidebar
        case newRadialMask
        case newLinearMask
        case showMaskOverlay
        case export
        case copySettings
        case pasteSettings
        case openFiles

        var keys: [String] {
            switch self {
            case .rawAdjustView: return ["R"]
            case .emulationView: return ["E"]
            case .textureView: return ["T"]
            case .showMaskingView: return ["M"]
            case .toggleImageView: return ["G"]
            case .hideSidebar: return ["T"]
            case .newRadialMask: return ["J"]
            case .newLinearMask: return ["G"]
            case .showMaskOverlay: return ["M"]
            case .export: return ["E"]
            case .copySettings: return ["C"]
            case .pasteSettings: return ["V"]
            case .openFiles: return ["O"]
            }
        }

        var modifiers: [EventModifiers] {
            switch self {
            case .hideSidebar, .export, .openFiles, .toggleImageView:
                return [.command]
            case .copySettings, .pasteSettings:
                return [.command, .shift]
            case .showMaskOverlay:
                return [.shift]
            default:
                return []
            }
        }
    }
}


struct ShortcutView: View {
    @EnvironmentObject var viewModel: ShortcutViewModel

    var body: some View {
        HStack(spacing: 20) {
            let modifierSymbols = viewModel.modifiers.map(symbolName(for:))
            let keySymbols = viewModel.keys.map { key -> String in
                let lower = key.lowercased()
                return keySymbolName(for: lower) ?? "\(lower).square"
            }

            let combined = modifierSymbols + keySymbols

            ForEach(Array(combined.enumerated()), id: \.offset) { index, symbol in
                if index != 0 {
                    styledSymbol("plus")
                }
                styledSymbol(symbol)
            }
        }
        .padding(20)
        .background(Color("MenuAccentDark").opacity(0.5))
        .opacity(viewModel.showView ? 1.0 : 0.0)
        .cornerRadius(20)
        .animation(.easeInOut(duration: 0.5), value: viewModel.showView)
    }

    private func styledSymbol(_ name: String) -> some View {
        Image(systemName: name)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 60, height: 60)
            .foregroundStyle(Color("SideBarText"))
    }

    private func symbolName(for modifier: EventModifiers) -> String {
        switch modifier {
        case .command: return "command"
        case .shift: return "shift"
        case .option: return "option"
        case .control: return "control"
        case .capsLock: return "capslock"
        default: return "questionmark"
        }
    }

    private func keySymbolName(for key: String) -> String? {
        switch key {
        case "delete": return "delete.left"
        case "tab": return "arrow.right.to.line"
        case "return": return "return"
        case "escape", "esc": return "escape"
        case "space", "spacebar": return "spacebar"
        default:
            if key.count == 1 && key.range(of: "[a-z]", options: .regularExpression) != nil {
                return "\(key).square"
            }
            return nil
        }
    }
}
