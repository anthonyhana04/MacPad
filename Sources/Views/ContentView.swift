// Sources/Views/ContentView.swift
import SwiftUI
import AppKit

struct ContentView: View {
    @Binding var doc: Document
    @EnvironmentObject private var theme: ThemeManager
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
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private var toolbar: some View {
        HStack {
            Button { newFile() } label: { Label("New", systemImage: "doc") }
            Button { openFile() } label: { Label("Open", systemImage: "folder") }
            Button { saveAs() } label: { Label("Save", systemImage: "square.and.arrow.down") }
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

    private var filenameField: some View {
        Group {
            if isEditingName {
                TextField("", text: $doc.workingName, onCommit: { isEditingName = false })
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .focused($nameFieldFocused)
                    .onAppear { nameFieldFocused = true }
            } else {
                Button { isEditingName = true } label: {
                    Text(doc.workingName)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(theme.colorScheme == .dark ? .white : .black)
                }
            }
        }
    }

    private func newFile() {
        doc.text = ""
        doc.fileURL = nil
        doc.workingName = "Untitled"
        doc.isDirty = false
    }

    private func openFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            guard let (text, name) = await FileService.shared.openFile(in: win) else { return }
            doc.text = text
            doc.fileURL = nil
            doc.workingName = name
            doc.isDirty = false
        }
    }

    private func saveAs() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            if let url = await FileService.shared.saveAs(in: win, initialText: doc.text, suggestedName: doc.workingName) {
                doc.fileURL = url
                doc.workingName = url.lastPathComponent
                doc.isDirty = false
            }
        }
    }
}

