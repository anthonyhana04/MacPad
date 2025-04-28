// Sources/ContentView.swift (Swift package target)

import SwiftUI
import AppKit

struct ContentView: View {
    @Binding var text: String
    @Binding var fileName: String
    @EnvironmentObject private var theme: ThemeManager

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

    private var toolbar: some View {
        HStack {
            Button { newFile() } label: { Label("New", systemImage: "doc") }
            Button { openFile() } label: { Label("Open", systemImage: "folder") }
            Button { saveAs() } label: { Label("Save As", systemImage: "square.and.arrow.down") }
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

    private func newFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            guard let (newText, newName) = await FileService.shared.newFile(in: win) else {
                return  // user cancelled
            }
            text     = newText
            fileName = newName
        }
    }
    
    private func openFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            guard let (openedText, openedName) = await FileService.shared.openFile(in: win) else {
                return  // user cancelled
            }
            text     = openedText
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

#Preview {
    ContentView(text: .constant(""), fileName: .constant("Untitled"))
        .environmentObject(ThemeManager())
}

