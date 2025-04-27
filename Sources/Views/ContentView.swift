//
//  ContentView.swift
//  MacPad
//

import SwiftUI
import AppKit

struct ContentView: View {

    // now driven by the parent App
    @Binding var text: String
    @Binding var fileName: String

    @EnvironmentObject private var theme: ThemeManager

    // inline rename UI
    @State private var isEditingName = false
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    // MARK: Toolbar
    private var toolbar: some View {
        HStack {
            Button { newFile() }
            label: { Label("New",  systemImage: "doc") }

            Button { openFile() }
            label: { Label("Open", systemImage: "folder") }

            Button { saveAs() }
            label: { Label("Save As", systemImage: "square.and.arrow.down") }

            Spacer()

            Group {
                if isEditingName {
                    TextField("", text: $fileName, onCommit: { isEditingName = false })
                        .textFieldStyle(.plain)
                        .frame(maxWidth: 200)
                        .focused($nameFieldFocused)
                        .onAppear { nameFieldFocused = true }
                } else {
                    Text(fileName)
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

    // MARK: File actions
    private func newFile() {
        let result = FileService.shared.newFile()
        text      = result.text
        fileName  = result.name
    }

    private func openFile() {
        let result = FileService.shared.openFile()
        text      = result.text
        fileName  = result.name
    }

    private func saveAs() {
        if let url = FileService.shared.saveAsModal(initialText: text,
                                                   suggestedName: fileName) {
            fileName = url.lastPathComponent
        }
    }
}

#Preview {
    ContentView(text: .constant(""),
                fileName: .constant("Untitled"))
    .environmentObject(ThemeManager())
}

