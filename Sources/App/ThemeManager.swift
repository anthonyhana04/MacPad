//
//  ThemeManager.swift
//  MacPad
//

import SwiftUI
import AppKit

@MainActor
final class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme = .light

    func toggleTheme() {
        colorScheme = (colorScheme == .dark ? .light : .dark)
        NSApp.appearance = NSAppearance(
            named: colorScheme == .dark ? .darkAqua : .aqua
        )
    }
}

