// Sources/App/DocumentStore.swift
import SwiftUI

@MainActor
final class DocumentStore: ObservableObject {
    @Published private(set) var docs: [Document] = []
    @Published private(set) var activeDocId: Document.ID?
    
    private var lastUntitledNumber: Int = 0

    @discardableResult
    func newUntitled() -> Document.ID {
        let prefix = "Untitled"
        
        lastUntitledNumber += 1
        
        let newName = lastUntitledNumber == 1 ? prefix : "\(prefix) - \(lastUntitledNumber)"
        
        let doc = Document(workingName: newName)
        docs.append(doc)
        activeDocId = doc.id
        return doc.id
    }

    @discardableResult
    func open(url: URL, contents: String, encoding: String.Encoding = .utf8) -> Document.ID {
        if let existing = docs.first(where: { $0.fileURL == url }) {
            activeDocId = existing.id
            return existing.id
        }
        docs.append(
            Document(text: contents,
                     fileURL: url,
                     isDirty: false,
                     workingName: url.lastPathComponent,
                     encoding: encoding)
        )
        activeDocId = docs.last!.id
        return docs.last!.id
    }

    func close(_ id: Document.ID) {
        docs.removeAll { $0.id == id }
        if activeDocId == id {
            activeDocId = docs.first?.id
        }
        resetUntitledCounterIfEmpty()
    }
    
    func setActiveDocument(_ id: Document.ID) {
        guard docs.contains(where: { $0.id == id }) else { return }
        activeDocId = id
    }
    
    var activeDocBinding: Binding<Document>? {
        guard let id = activeDocId else { return firstDocBinding }
        return binding(for: id)
    }
    
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
    
    func resetUntitledCounterIfEmpty() {
        if docs.isEmpty {
            lastUntitledNumber = 0
        }
    }
}

extension DocumentStore {
    func discardUnsaved() {
        docs.removeAll(where: \.hasUnsavedChanges)
        if docs.isEmpty {
            lastUntitledNumber = 0
        }
    }
}
