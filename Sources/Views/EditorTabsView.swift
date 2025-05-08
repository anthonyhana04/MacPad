// Sources/Views/EditorTabsView.swift
import SwiftUI
import AppKit

struct EditorTabsView: View {
    @EnvironmentObject private var store: DocumentStore
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var encodingManager: EncodingManager
    @State private var selection: Document.ID

    init(initialDoc id: Document.ID) {
        _selection = State(initialValue: id)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Spacer()
                ForEach(store.docs) { doc in
                    TabTile(
                        doc: doc,
                        selected: selection == doc.id,
                        select: {
                            selection = doc.id
                            store.setActiveDocument(doc.id)
                        },
                        close: { self.close(doc) }
                    )
                    .id(doc.id)
                }
                Spacer()
                Button {
                    let id = store.newUntitled()
                    selection = id
                    store.setActiveDocument(id)
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .focusable(false)
                .padding(.trailing, 8)
            }
            .padding(.vertical, 4)

            Divider()

            if let binding = store.binding(for: selection) {
                ContentView(doc: binding)
                    .environmentObject(encodingManager)
                    .id(selection)
            }
        }
        .preferredColorScheme(theme.colorScheme)
        .frame(minWidth: 600, minHeight: 400)
        .onChange(of: store.docs) { oldDocs, newDocs in
            if !newDocs.contains(where: { $0.id == selection }),
               let first = newDocs.first {
                selection = first.id
                store.setActiveDocument(first.id)
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            store.setActiveDocument(newValue)
        }
        .onAppear {
            store.setActiveDocument(selection)

            DispatchQueue.main.async {
                if let window = NSApp.keyWindow,
                   let tabView = window.contentViewController?.view.subviews.first(where: { $0 is NSTabView }) as? NSTabView {
                    for (index, doc) in store.docs.enumerated() {
                        if index < tabView.tabViewItems.count {
                            tabView.tabViewItems[index].identifier = doc.id.uuidString
                        }
                    }
                }
            }
        }
    }

    private func close(_ doc: Document) {
        guard doc.hasUnsavedChanges else { performClose(doc.id); return }

        let alert = NSAlert()
        alert.messageText = "The document \"" + doc.displayName + "\" has unsaved changes."
        alert.informativeText = "Save before closing?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            NotificationCenter.default.post(
                name: .saveAsRequested,
                object: doc.id,
                userInfo: ["closeAfter": true]
            )
        case .alertSecondButtonReturn:
            performClose(doc.id)
        default:
            break
        }
    }

    private func performClose(_ id: Document.ID) {
        store.close(id)
        if store.docs.isEmpty {
            selection = store.newUntitled()
            store.setActiveDocument(selection)
        } else if !store.docs.contains(where: { $0.id == selection }) {
            selection = store.docs.first!.id
            store.setActiveDocument(selection)
        }
    }
}

private struct TabTile: View {
    let doc: Document
    let selected: Bool
    let select: () -> Void
    let close: () -> Void
    @State private var hover = false

    var body: some View {
        HStack(spacing: 4) {
            Button(action: select) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selected ? Color.accentColor.opacity(0.2) : Color.clear)
                        .frame(width: 90, height: 22)
                    Text(doc.displayName)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .offset(y: 3)
            }
            .buttonStyle(.plain)
            .focusable(false)

            Button(action: close) {
                Image(systemName: "xmark")
                    .imageScale(.small)
                    .opacity(hover ? 1 : 0)
            }
            .buttonStyle(.plain)
            .focusable(false)
        }
        .onHover { hover = $0 }
    }
}
