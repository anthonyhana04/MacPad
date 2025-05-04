// Sources/App/ThemeManager.swift
import SwiftUI
import AppKit

@MainActor
final class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme {
        didSet {
            applyAppearance(to: colorScheme)
            UserDefaults.standard.set(colorScheme == .dark, forKey: "isDarkMode")
        }
    }

    init() {
        let isDarkMode = UserDefaults.standard.bool(forKey: "isDarkMode")
        self.colorScheme = isDarkMode ? .dark : .light
        applyAppearance(to: colorScheme)
    }

    func toggleTheme() {
        colorScheme = (colorScheme == .dark ? .light : .dark)
    }

    private func applyAppearance(to scheme: ColorScheme) {
        NSApp.appearance = NSAppearance(
            named: scheme == .dark ? .darkAqua : .aqua
        )
    }
}
