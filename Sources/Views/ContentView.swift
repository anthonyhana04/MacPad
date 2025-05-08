// Sources/Views/ContentView.swift
import SwiftUI
import AppKit

struct ContentView: View {
    @Binding var doc: Document
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var encodingManager: EncodingManager
    @State private var isEditingName = false
    @FocusState private var nameFieldFocused: Bool

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ZStack(alignment: .topLeading) {
                TextEditor(text: $doc.text)
                    .font(.system(.body, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .onChange(of: doc.text) { _, _ in
                        doc.isDirty = true
                    }
                if doc.text.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("|> Type here!")
                        Text("|> MacPad Ver. \(version)")
                        Text("|> Thanks for using MacPad Feedback is Appreciated!")
                    }
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
                    .allowsHitTesting(false)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
            statusBar
        }
        .frame(minWidth: 600, minHeight: 400)
        .onChange(of: encodingManager.currentEncoding) { oldValue, newValue in
            if doc.encoding != newValue.encoding {
                if !doc.text.isEmpty && doc.fileURL != nil {
                    promptForEncodingChange(from: oldValue, to: newValue)
                } else {
                    doc.encoding = newValue.encoding
                }
            }
        }
    }

    private var toolbar: some View {
        HStack {
            Button { newFile() } label: { Label("New", systemImage: "doc") }
            Button { openFile() } label: { Label("Open", systemImage: "folder") }
            Button { save() } label: { Label("Save", systemImage: "square.and.arrow.down") }
            Spacer()
            filenameField
            Button {
                theme.toggleTheme()
            } label: {
                Image(systemName: theme.colorScheme == .dark ? "sun.max.fill" : "moon.fill")
            }
            .buttonStyle(.plain)
            .help("Toggle Light/Dark Mode")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private var statusBar: some View {
        HStack {
            Spacer()
            EncodingSelector()
                .environmentObject(encodingManager)
                .frame(height: 24)
        }
        .frame(height: 24)
        .padding(.horizontal, 4)
    }

    private var filenameField: some View {
        Group {
            if doc.fileURL != nil {
                HStack(spacing: 4) {
                    Text(doc.workingName)
                        .font(.system(.body, design: .monospaced))
                    if doc.hasUnsavedChanges {
                        Circle()
                            .frame(width: 8, height: 8)
                            .foregroundStyle(.red)
                            .help("Unsaved changes")
                    }
                }
                .foregroundColor(.secondary)
            } else if isEditingName {
                TextField("", text: $doc.workingName, onCommit: { isEditingName = false })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .focused($nameFieldFocused)
                    .onAppear { nameFieldFocused = true }
            } else {
                Button { isEditingName = true } label: {
                    HStack(spacing: 4) {
                        Text(doc.workingName)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(theme.colorScheme == .dark ? .white : .black)
                        if doc.hasUnsavedChanges {
                            Circle()
                                .foregroundStyle(.red)
                                .frame(width: 8, height: 8)
                                .help("Unsaved changes")
                        }
                    }
                }
            }
        }
    }

    private func newFile() {
        doc.text = ""
        doc.fileURL = nil
        doc.workingName = "Untitled"
        doc.isDirty = false
        doc.encoding = encodingManager.currentEncoding.encoding
    }

    private func openFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            guard let (text, name, url, encoding) = await FileService.shared.openFile(in: win, encodingManager: encodingManager) else { return }
            doc.text = text
            doc.fileURL = url
            doc.workingName = name
            doc.isDirty = false
            doc.encoding = encoding
            
            if let encodingOption = encodingManager.availableEncodings.first(where: { $0.encoding == encoding }) {
                encodingManager.setEncoding(encodingOption)
            }
        }
    }
    
    private func save() {
        if let url = doc.fileURL {
            do {
                try doc.text.write(to: url, atomically: true, encoding: doc.encoding)
                doc.isDirty = false
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        } else {
            saveAs()
        }
    }

    private func saveAs() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            if let url = await FileService.shared.saveAs(
                in: win,
                initialText: doc.text,
                suggestedName: doc.workingName,
                encoding: doc.encoding
            ) {
                doc.fileURL = url
                doc.workingName = url.lastPathComponent
                doc.isDirty = false
            }
        }
    }
    
    private func promptForEncodingChange(from oldValue: EncodingOption, to newValue: EncodingOption) {
        let alert = NSAlert()
        alert.messageText = "Change document encoding?"
        alert.informativeText = "Changing from \(oldValue.name) to \(newValue.name) might cause data loss if the document contains characters not supported by the new encoding."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Change Encoding")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            doc.encoding = newValue.encoding
            
            if !doc.text.isEmpty && doc.fileURL != nil {
                if let data = doc.text.data(using: oldValue.encoding),
                   let reencoded = String(data: data, encoding: newValue.encoding) {
                    doc.text = reencoded
                    doc.isDirty = true
                }
            }
        } else {
            DispatchQueue.main.async {
                encodingManager.setEncoding(oldValue)
            }
        }
    }
}
