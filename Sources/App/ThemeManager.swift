// ThemeManager.swift
import SwiftUI
import AppKit

@MainActor
final class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme {
        didSet {
            // Apply the chosen appearance
            NSApp.appearance = NSAppearance(
                named: colorScheme == .dark ? .darkAqua : .aqua
            )
            // Persist the current theme
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
        // Swap light ↔ dark
        colorScheme = (colorScheme == .dark ? .light : .dark)
    }
}

