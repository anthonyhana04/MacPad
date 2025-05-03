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
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private var toolbar: some View {
        HStack {
            Button { newFile() }  label: { Label("New", systemImage: "doc") }
            Button { openFile() } label: { Label("Open", systemImage: "folder") }
            Button { saveAs() }   label: { Label("Save As", systemImage: "square.and.arrow.down") }
            Spacer()
            Group {
                if isEditingName {
                    TextField("", text: $doc.workingName, onCommit: { isEditingName = false })
                        .textFieldStyle(.plain)
                        .frame(maxWidth: 200)
                        .focused($nameFieldFocused)
                        .onAppear { nameFieldFocused = true }
                } else {
                    Text(doc.displayName)
                        .foregroundStyle(.secondary)
                        .onTapGesture { isEditingName = true }
                }
            }
            Button { theme.toggleTheme() } label: {
                Image(systemName: theme.colorScheme == .dark ? "sun.max.fill" : "moon.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding()
        .background(.background)
    }

    // MARK: – File helpers (single‑doc version)
    private func newFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            guard let (newText, _) = await FileService.shared.newFile(in: win) else { return }
            doc.text = newText
            doc.fileURL = nil
            doc.workingName = "Untitled"
            doc.isDirty = false
        }
    }

    private func openFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            guard let (openedText, openedName) = await FileService.shared.openFile(in: win) else { return }
            doc.text = openedText
            doc.fileURL = nil
            doc.workingName = openedName
            doc.isDirty = false
        }
    }

    private func saveAs() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            if let url = await FileService.shared.saveAs(
                in: win,
                initialText: doc.text,
                suggestedName: doc.workingName
            ) {
                doc.fileURL = url
                doc.workingName = url.lastPathComponent
                doc.isDirty = false
            }
        }
    }
}

#Preview {
    ContentView(doc: .constant(Document()))
        .environmentObject(ThemeManager())
}

