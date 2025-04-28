// Sources/App/MacPadApp.swift

import SwiftUI
import AppKit

@main
struct MacPadApp: App {
    @StateObject private var theme = ThemeManager()
    @State private var text: String = ""
    @State private var fileName: String = "Untitled"

    @State private var lastSavedText: String = ""
    @State private var isDirty: Bool = false

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(text: $text, fileName: $fileName)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)
                .background(
                    WindowAccessor { window in
                        window.delegate = appDelegate
                    }
                )
                .onChange(of: text) { new in
                    isDirty = (new != lastSavedText)
                }
                .onAppear {
                    // Wire up the dirty-check closure
                    appDelegate.shouldPromptIfDirty = { self.isDirty }
                    // Wire up the Save As–then–quit closure
                    appDelegate.performSave = {
                        Task {
                            if let win = NSApp.keyWindow,
                               let url = await FileService.shared.saveAs(
                                   in: win,
                                   initialText: self.text,
                                   suggestedName: self.fileName
                               ) {
                                self.fileName = url.lastPathComponent
                                self.lastSavedText = self.text
                                self.isDirty = false
                                // After the sheet finishes, terminate without another prompt
                                NSApp.terminate(nil)
                            }
                        }
                    }
                    // Initialize dirty state
                    lastSavedText = text
                    isDirty = false
                }
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
            if let (newText, newName) = await FileService.shared.newFile(in: win) {
                text = newText
                fileName = newName
                lastSavedText = newText
                isDirty = false
            }
        }
    }

    private func openFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            if let (openedText, openedName) = await FileService.shared.openFile(in: win) {
                text = openedText
                fileName = openedName
                lastSavedText = openedText
                isDirty = false
            }
        }
    }

    private func saveAs() {
        appDelegate.performSave?()
    }
}

