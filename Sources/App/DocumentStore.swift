// Sources/App/DocumentStore.swift
import SwiftUI

@MainActor
final class DocumentStore: ObservableObject {
    @Published private(set) var docs: [Document] = []

    @discardableResult
    func newUntitled() -> Document.ID {
        let prefix = "Untitled - "
        let next   = (docs.compactMap { Int($0.workingName.replacingOccurrences(of: prefix, with: "")) }.max() ?? 0) + 1
        let doc    = Document(workingName: "\(prefix)\(next)")
        docs.append(doc)
        return doc.id
    }

    @discardableResult
    func open(url: URL, contents: String) -> Document.ID {
        if let existing = docs.first(where: { $0.fileURL == url }) { return existing.id }
        docs.append(
            Document(text: contents,
                     fileURL: url,
                     isDirty: false,
                     workingName: url.lastPathComponent)
        )
        return docs.last!.id
    }

    func close(_ id: Document.ID) { docs.removeAll { $0.id == id } }
    
    func binding(for id: Document.ID) -> Binding<Document>? {
        Binding(
            get: { self.docs.first { $0.id == id } ?? Document() },
            set: { newVal in
                guard let idx = self.docs.firstIndex(where: { $0.id == id }) else { return }
                var updated = newVal
                if updated.text != self.docs[idx].text { updated.isDirty = true }
                self.docs[idx] = updated
            }
        )
    }

    var firstDocBinding: Binding<Document>? { docs.first.flatMap { binding(for: $0.id) } }
}

extension DocumentStore {
    func discardUnsaved() {
        docs.removeAll(where: \.hasUnsavedChanges)
    }
}

