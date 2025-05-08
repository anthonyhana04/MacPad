// Sources/App/MacPadApp.swift
import SwiftUI
import AppKit

@main
struct MacPadApp: App {
    @StateObject private var theme = ThemeManager()
    @StateObject private var encodingManager = EncodingManager()
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
                .frame(minWidth: 680, minHeight: 460)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .environmentObject(store)
        .commands {
            fileMenu
            editMenu
        }
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
            .environmentObject(encodingManager)
            .environmentObject(store)
            .preferredColorScheme(theme.colorScheme)
            .background(WindowAccessor { window in
                window.delegate = windowCoordinator
                window.minSize = NSSize(width: 680, height: 460)
                
                if let identifier = Bundle.main.bundleIdentifier {
                    window.setFrameAutosaveName("\(identifier).mainWindow")
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: .saveAsRequested)) { note in
                guard let id = note.object as? Document.ID,
                      let target = store.binding(for: id) else { return }
                let closeAfter = (note.userInfo?["closeAfter"] as? Bool) ?? false
                let shouldExit = (note.userInfo?["shouldExit"] as? Bool) ?? false
                saveAs(target) { didSave in
                    if closeAfter && didSave {
                        DispatchQueue.main.async {
                            store.close(id)
                        }
                    }
                    
                    if shouldExit && didSave {
                        DispatchQueue.main.async {
                            NSApp.terminate(nil)
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .saveRequested)) { note in
                guard let id = note.object as? Document.ID,
                      let binding = store.binding(for: id) else { return }
                let doc = binding.wrappedValue
                let shouldExit = (note.userInfo?["shouldExit"] as? Bool) ?? false
                
                if let url = doc.fileURL {
                    Task { @MainActor in
                        do {
                            try doc.text.write(to: url, atomically: true, encoding: doc.encoding)
                            binding.wrappedValue.isDirty = false
                            
                            if shouldExit {
                                NSApp.terminate(nil)
                            }
                        } catch {
                            let alert = NSAlert(error: error)
                            alert.runModal()
                        }
                    }
                } else {
                    saveAs(binding) { didSave in
                        if shouldExit && didSave {
                            DispatchQueue.main.async {
                                NSApp.terminate(nil)
                            }
                        }
                    }
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
                if let activeWindow = NSApp.keyWindow,
                   let tabView = activeWindow.contentViewController?.view.subviews.first(where: { $0 is NSTabView }) as? NSTabView,
                   let selectedTabViewItem = tabView.selectedTabViewItem,
                   let tabIdentifier = selectedTabViewItem.identifier as? String,
                   let docID = UUID(uuidString: tabIdentifier) {
                    
                    NotificationCenter.default.post(
                        name: .saveRequested,
                        object: docID
                    )
                } else {
                    if let activeDoc = store.activeDocBinding?.wrappedValue {
                        NotificationCenter.default.post(
                            name: .saveRequested,
                            object: activeDoc.id
                        )
                    } else if let firstDoc = store.firstDocBinding?.wrappedValue {
                        NotificationCenter.default.post(
                            name: .saveRequested,
                            object: firstDoc.id
                        )
                    }
                }
            }
            .keyboardShortcut("s", modifiers: [.command])
            
            Button("Save As…") {
                if let activeWindow = NSApp.keyWindow,
                   let tabView = activeWindow.contentViewController?.view.subviews.first(where: { $0 is NSTabView }) as? NSTabView,
                   let selectedTabViewItem = tabView.selectedTabViewItem,
                   let tabIdentifier = selectedTabViewItem.identifier as? String,
                   let docID = UUID(uuidString: tabIdentifier) {
                    
                    NotificationCenter.default.post(
                        name: .saveAsRequested,
                        object: docID
                    )
                } else {
                    if let activeDoc = store.activeDocBinding?.wrappedValue {
                        NotificationCenter.default.post(
                            name: .saveAsRequested,
                            object: activeDoc.id
                        )
                    } else if let firstDoc = store.firstDocBinding?.wrappedValue {
                        NotificationCenter.default.post(
                            name: .saveAsRequested,
                            object: firstDoc.id
                        )
                    }
                }
            }
            .keyboardShortcut("S", modifiers: [.command, .shift])
        }
    }
    
    private var editMenu: some Commands {
        CommandMenu("Encoding") {
            ForEach(encodingManager.availableEncodings) { option in
                if option.name == "UTF-8" {
                    Button(option.name) {
                        encodingManager.setEncoding(option)
                    }
                    .keyboardShortcut("e", modifiers: [.command, .option])
                } else {
                    Button(option.name) {
                        encodingManager.setEncoding(option)
                    }
                }
            }
        }
    }
    
    private func openDoc() async {
        guard let win = NSApp.keyWindow else { return }
        if let (txt, _, url, encoding) = await FileService.shared.openFile(in: win, encodingManager: encodingManager) {
            _ = store.open(url: url, contents: txt, encoding: encoding)

            if let option = encodingManager.availableEncodings.first(where: { $0.encoding == encoding }) {
                encodingManager.setEncoding(option)
            }
        }
    }
    
    private func saveAs(_ doc: Binding<Document>, done: @escaping (Bool) -> Void = { _ in }) {
        Task { @MainActor in
            guard let win = NSApp.keyWindow else { done(false); return }
            if let url = await FileService.shared.saveAs(
                in: win,
                initialText: doc.wrappedValue.text,
                suggestedName: doc.wrappedValue.workingName,
                encoding: doc.wrappedValue.encoding
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
