// MacPadApp.swift
import SwiftUI
import AppKit

@main
struct MacPadApp: App {
    @StateObject private var theme = ThemeManager()
    @State private var text: String = ""
    @State private var fileName: String = "Untitled"

    var body: some Scene {
        WindowGroup {
            ContentView(text: $text, fileName: $fileName)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
        }
        .commands {
            CommandMenu("File") {
                Button("New") { newFile() }
                    .keyboardShortcut("n")
                Button("Open…") { openFile() }
                    .keyboardShortcut("o")
                Button("Save As…") { saveAs() }
                    .keyboardShortcut("S", modifiers: [.command, .shift])
            }
        }
    }

    private func newFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            guard let (newText, newName) = await FileService.shared.newFile(in: win) else {
                return
            }
            text = newText
            fileName = newName
        }
    }

    private func openFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            guard let (openedText, openedName) = await FileService.shared.openFile(in: win) else {
                return
            }
            text = openedText
            fileName = openedName
        }
    }

    private func saveAs() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            if let url = await FileService.shared.saveAs(
                in: win,
                initialText: text,
                suggestedName: fileName
            ) {
                fileName = url.lastPathComponent
            }
        }
    }
}

