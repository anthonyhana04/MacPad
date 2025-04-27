import SwiftUI

struct ContentView: View {
    // Injected once at start-up
    @EnvironmentObject private var theme: ThemeManager
    
    @State private var text     = ""
    @State private var fileName = "Untitled"
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
        .task {                      // load a blank doc on first launch first launch
            (text, fileName) = FileService.shared.newFile()
        }
    }
    
    // MARK: - Top toolbar
    private var toolbar: some View {
        HStack {
            Button { newFile() }  label: { Label("New",  systemImage: "doc") }
            Button { openFile() } label: { Label("Open", systemImage: "folder") }

            // ➊  **Save As** button (new text)
            Button { saveAs() }   label: { Label("Save As", systemImage: "square.and.arrow.down") }

            Spacer()

            // ➋  Click-to-edit file name
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
                        .onTapGesture { isEditingName = true }   // <-- makes it clickable
                }
            }

            Button { theme.toggleTheme() } label: {
                Image(systemName: theme.colorScheme == .dark ? "sun.max.fill"
                                                             : "moon.fill")
                    .imageScale(.large)
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)
        }
        .padding()
        .background(.background)
    }

    
    // MARK: - File actions
    private func newFile()  { (text, fileName) = FileService.shared.newFile()  }
    private func openFile() { (text, fileName) = FileService.shared.openFile() }
    private func saveAs() {
        if let url = FileService.shared.saveAs(initialText: text,
                                               suggestedName: fileName) {
            fileName = url.lastPathComponent       // update title if user renamed
        }
    }
}

#Preview { ContentView().environmentObject(ThemeManager()) }

