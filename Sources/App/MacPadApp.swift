// Sources/App/MacPadApp.swift
import SwiftUI
import AppKit

@main
struct MacPadApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var store: DocumentStore
    private let windowCoordinator: WindowCoordinator
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    init() {
        let s = DocumentStore()
        _ = s.newUntitled()
        _store = StateObject(wrappedValue: s)
        windowCoordinator = WindowCoordinator(store: s)
        appDelegate.store = s
    }
    
    var body: some Scene {
        WindowGroup {
            docWindow(ensureDocBinding())
        }
        .environmentObject(store)
        .commands { fileMenu }
    }
    
    private func ensureDocBinding() -> Binding<Document> {
        if let existing = store.firstDocBinding {
            return existing
        }
        DispatchQueue.main.async {
            _ = store.newUntitled()
        }
        return .constant(Document())
    }
    
    @ViewBuilder
    private func docWindow(_ doc: Binding<Document>) -> some View {
        EditorTabsView(initialDoc: doc.wrappedValue.id)
            .environmentObject(theme)
            .environmentObject(store)
            .preferredColorScheme(theme.colorScheme)
            .background(WindowAccessor { $0.delegate = windowCoordinator })
            .onReceive(NotificationCenter.default.publisher(for: .saveAsRequested)) { note in
                guard let id = note.object as? Document.ID,
                      let target = store.binding(for: id) else { return }
                let closeAfter = (note.userInfo?["closeAfter"] as? Bool) ?? false
                saveAs(target) { didSave in
                    if closeAfter && didSave {
                        DispatchQueue.main.async {
                            store.close(id)
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .saveRequested)) { note in
                guard let id = note.object as? Document.ID,
                      let binding = store.binding(for: id) else { return }
                let doc = binding.wrappedValue
                if let url = doc.fileURL {
                    Task { @MainActor in
                        try? doc.text.write(to: url, atomically: true, encoding: .utf8)
                        binding.wrappedValue.isDirty = false
                    }
                } else {
                    saveAs(binding)
                }
            }
        
            .onAppear {
                appDelegate.createUntitledDoc = { _ = store.newUntitled() }
            }
    }
    
    private var fileMenu: some Commands {
        CommandGroup(after: .newItem) {
            Button("New") {
                store.newUntitled()
            }
            .keyboardShortcut("n")
            
            Divider()
            
            Button("New Tab") {
                store.newUntitled()
            }
            .keyboardShortcut("t")
            
            Button("Open…") {
                Task { await openDoc() }
            }
            .keyboardShortcut("o")
            
            Divider()
            
            Button("Save") {
                if let binding = store.firstDocBinding {
                    NotificationCenter.default.post(
                        name: .saveRequested,
                        object: binding.wrappedValue.id
                    )
                }
            }
            .keyboardShortcut("s", modifiers: [.command])
            
            Button("Save As…") {
                if let binding = store.firstDocBinding {
                    NotificationCenter.default.post(
                        name: .saveAsRequested,
                        object: binding.wrappedValue.id
                    )
                }
            }
            .keyboardShortcut("S", modifiers: [.command, .shift])
        }
    }
    
    private func openDoc() async {
        guard let win = NSApp.keyWindow else { return }
        if let (txt, name) = await FileService.shared.openFile(in: win) {
            _ = store.open(url: URL(fileURLWithPath: name), contents: txt)
        }
    }
    
    private func saveAs(_ doc: Binding<Document>, done: @escaping (Bool) -> Void = { _ in }) {
        Task { @MainActor in
            guard let win = NSApp.keyWindow else { done(false); return }
            if let url = await FileService.shared.saveAs(
                in: win,
                initialText: doc.wrappedValue.text,
                suggestedName: doc.wrappedValue.workingName
            ) {
                doc.wrappedValue.fileURL = url
                doc.wrappedValue.workingName = url.lastPathComponent
                doc.wrappedValue.isDirty = false
                done(true)
            } else {
                done(false)
            }
        }
    }
}


