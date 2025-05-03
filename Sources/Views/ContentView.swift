// Sources/Views/ContentView.swift
import SwiftUI
import AppKit

struct ContentView: View {
    @Binding var doc: Document
    @EnvironmentObject private var theme: ThemeManager

    @FocusState private var nameFieldFocused: Bool
    @State private var isEditingName = false

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    private var fileName: String { doc.displayName }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ZStack(alignment: .topLeading) {
                TextEditor(text: $doc.text)
                    .font(.system(.body, design: .monospaced))
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .onChange(of: doc.text) { _ in doc.isDirty = true }

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
            Text(fileName)
                .foregroundStyle(.secondary)
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
            guard let (newText, _) = await FileService.shared.newFile(in: win) else { return }
            doc.text    = newText
            doc.fileURL = nil
            doc.isDirty = false
        }
    }

    private func openFile() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            guard let (openedText, openedName) = await FileService.shared.openFile(in: win) else { return }
            doc.text    = openedText
            doc.fileURL = URL(fileURLWithPath: openedName)
            doc.isDirty = false
        }
    }

    private func saveAs() {
        guard let win = NSApp.keyWindow else { return }
        Task {
            if let url = await FileService.shared.saveAs(
                in: win,
                initialText: doc.text,
                suggestedName: fileName
            ) {
                doc.fileURL = url
                doc.isDirty = false
            }
        }
    }
}

#Preview {
    // Preview with a dummy document
    ContentView(doc: .constant(Document()))
        .environmentObject(ThemeManager())
}

