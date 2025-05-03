// Sources/App/DocumentStore.swift

import SwiftUI

@MainActor
final class DocumentStore: ObservableObject {
    @Published private(set) var docs: [Document] = []
    
    @discardableResult
    func newUntitled() -> Document.ID {
        let doc = Document()
        docs.append(doc)
        return doc.id
    }
    
    @discardableResult
    func open(url: URL, contents: String) -> Document.ID {
        if let existing = docs.first(where: { $0.fileURL == url }) {
            return existing.id
        }
        docs.append(Document(text: contents, fileURL: url, isDirty: false))
        return docs.last!.id
    }
    
    func update(_ id: Document.ID, mutate: (inout Document) -> Void) {
        guard let idx = docs.firstIndex(where: {$0.id == id}) else { return }
        mutate(&docs[idx])
    }
    
    func close(_ id: Document.ID) {
        docs.removeAll { $0.id == id }
    }
    
    func binding(for id: Document.ID -> Binding<Document>? {
        guard let idx = docs.firstIndex(where: { $0.id == id }) else { return nil }
        return Binding(
            get: { self.docs[idx] },
            set: { self.docs[idx] = $0 }
        )
    }
    
    var firstDocBinding: Binding<Document>? {
        guard !docs.isEmpty else { return nil }
        return Binding(
            get: { self.docs[0] },
            set: { self.docs[0] = $0 }
        )
    }
}


