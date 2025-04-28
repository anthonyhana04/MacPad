// ThemeManager.swift
import SwiftUI
import AppKit

@MainActor
final class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme {
        didSet {
            NSApp.appearance = NSAppearance(
                named: colorScheme == .dark ? .darkAqua : .aqua
            )
            
            UserDefaults.standard.set(
                colorScheme == .dark,
                forKey: "isDarkMode"
            )
        }
    }

    init() {
        // Load persisted theme (default is light)
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.colorScheme = isDarkMode ? .dark : .light
        // Apply it on launch
        NSApp.appearance = NSAppearance(
            named: isDarkMode ? .darkAqua : .aqua
        )
    }

    func toggleTheme() {
        colorScheme = (colorScheme == .dark ? .light : .dark)
    }
}

