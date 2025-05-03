// Sources/App/MacPadApp.swift
import SwiftUI
import AppKit

@main
struct MacPadApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var store: DocumentStore
    
    init() {
        let s = DocumentStore()
        s.newUntitled()          // first blank doc (not created before)
        _store = StateObject(wrappedValue: s)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(doc: store.firstDocBinding!)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
        }
        .environmentObject(store)
    }
}

