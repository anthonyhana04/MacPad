// Sources/App/MacPadApp.swift
import SwiftUI
import AppKit

@main
struct MacPadApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var store: DocumentStore

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    init() {
        let s = DocumentStore()
        s.newUntitled()
        _store = StateObject(wrappedValue: s)
    }

    var body: some Scene {
        WindowGroup {
            let docBinding = store.firstDocBinding!

            ContentView(doc: docBinding)
                .environmentObject(theme)
                .preferredColorScheme(theme.colorScheme)

                .onAppear {
                    appDelegate.shouldPromptIfDirty = {
                        docBinding.wrappedValue.isDirty
                    }
                    appDelegate.performSave = {
                        saveAs(docBinding)
                    }
                }
                .background(
                    WindowAccessor { window in
                        window.delegate = appDelegate
                    }
                )
        }
        .environmentObject(store)
    }

    private func saveAs(_ docBinding: Binding<Document>) {
        Task { @MainActor in
            guard let win = NSApp.keyWindow else { return }

            if let url = await FileService.shared.saveAs(
                    in: win,
                    initialText: docBinding.wrappedValue.text,
                    suggestedName: docBinding.wrappedValue.workingName
               ) {
                docBinding.wrappedValue.fileURL     = url
                docBinding.wrappedValue.workingName = url.lastPathComponent
                docBinding.wrappedValue.isDirty     = false

                appDelegate.skipNextTerminationPrompt = true
                NSApp.terminate(nil)                
            }
        }
    }
}

