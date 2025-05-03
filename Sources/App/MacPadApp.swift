// Sources/App/MacPadApp.swift
import SwiftUI
import AppKit

@main
struct MacPadApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var store = DocumentStore()

    init() {
        _store = StateObject(wrappedValue: DocumentStore())
        _ = store.newUntitled()
    }

    var body: some Scene {
        WindowGroup {
            if let docBinding = store.firstDocBinding {
                ContentView(doc: docBinding)
                    .environmentObject(theme)
                    .preferredColorScheme(theme.colorScheme)
            } else {
                Text("No document open")
            }
        }
        .environmentObject(store)
    }
}

