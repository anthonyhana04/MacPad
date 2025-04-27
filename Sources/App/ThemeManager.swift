//
//  ThemeManager.swift
//  MacPad
//

import SwiftUI
import AppKit

/// App-wide state (dark/light mode + high-level file commands).
@MainActor
final class ThemeManager: ObservableObject {

    // ───────────────────────────────────────────────
    //                 Appearance
    // ───────────────────────────────────────────────
    @AppStorage("isDarkMode") private var isDarkMode = false {
        didSet { objectWillChange.send() }
    }

    var colorScheme: ColorScheme { isDarkMode ? .dark : .light }
    func toggleTheme() { isDarkMode.toggle() }

    // ───────────────────────────────────────────────
    //                 File commands
    // ───────────────────────────────────────────────

    func newDocument() {
        _ = FileService.shared.newFile()            // nothing else yet
    }

    func openDocument() {
        _ = FileService.shared.openFile()
    }

    /// Save As … (always modal so the panel is guaranteed to appear)
    func saveDocument(initialText: String,
                      suggestedName: String,
                      in window: NSWindow?) {

        if let url = FileService.shared.saveAsModal(initialText: initialText,
                                                    suggestedName: suggestedName) {
            // You could broadcast the new URL here if other views care.
            print("Saved to \(url.path)")
        }
    }
}

