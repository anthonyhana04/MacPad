// Sources/App/AppDelegate.swift
import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var createUntitledDoc: (() -> Void)?
    weak var store: DocumentStore?

    func applicationDidFinishLaunching(_ note: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        createUntitledDoc?()
        return true
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if store?.docs.contains(where: \.hasUnsavedChanges) == true {
            NSApp.windows.forEach { $0.performClose(nil) }
            return .terminateCancel
        }
        return .terminateNow
    }
}

