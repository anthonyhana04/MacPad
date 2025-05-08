// Sources/App/WindowCoordinator.swift
import Cocoa
import SwiftUI

@MainActor
final class WindowCoordinator: NSObject, NSWindowDelegate {
    private unowned let store: DocumentStore
    init(store: DocumentStore) { self.store = store }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard store.docs.contains(where: \.hasUnsavedChanges) else { return true }

        let alert = NSAlert()
        alert.messageText = "You have unsaved changes."
        alert.informativeText = "Save your work before closing?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save All")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn:
            let docsWithChanges = store.docs.filter(\.hasUnsavedChanges)
            var savedCount = 0
            
            for doc in docsWithChanges {
                if let fileURL = doc.fileURL {
                    NotificationCenter.default.post(
                        name: .saveRequested,
                        object: doc.id
                    )
                    savedCount += 1
                    if savedCount == docsWithChanges.count {
                        DispatchQueue.main.async {
                            NSApp.terminate(nil)
                        }
                    }
                } else {
                    NotificationCenter.default.post(
                        name: .saveAsRequested,
                        object: doc.id,
                        userInfo: ["shouldExit": true]
                    )
                }
            }
            if docsWithChanges.isEmpty {
                NSApp.terminate(nil)
            }
            
            return false
        case .alertSecondButtonReturn:
            store.discardUnsaved()
            NSApp.terminate(nil)
            return true
        default:
            return false
        }
    }
}

extension Notification.Name {
    static let saveAsRequested = Notification.Name("MacPadSaveAsRequested")
    static let saveRequested = Notification.Name("MacPadSaveRequested")
}
