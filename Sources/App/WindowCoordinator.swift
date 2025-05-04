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
            store.docs
                .filter(\.hasUnsavedChanges)
                .forEach { NotificationCenter.default.post(name: .saveAsRequested,
                                                           object: $0.id) }
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
}

