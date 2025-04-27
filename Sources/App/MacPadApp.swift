//
//  MacPadApp.swift
//  MacPad
//

import SwiftUI

@main
struct MacPadApp: App {

    // ── app-wide document state ──
    @State private var text     = ""
    @State private var fileName = "Untitled"

    // shared objects
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            // now matches ContentView’s initializer:
            ContentView(text: $text, fileName: $fileName)
                .environmentObject(themeManager)
        }
        .commands {
            CommandMenu("File") {
                Button("New") {
                    let result = FileService.shared.newFile()
                    text     = result.text
                    fileName = result.name
                }
                .keyboardShortcut("n")

                Button("Open…") {
                    let result = FileService.shared.openFile()
                    text     = result.text
                    fileName = result.name
                }
                .keyboardShortcut("o")

                Button("Save As…") {
                    if let url = FileService.shared.saveAsModal(initialText: text,
                                                               suggestedName: fileName) {
                        fileName = url.lastPathComponent
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
        }
    }
}

