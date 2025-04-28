// Sources/App/AppDelegate.swift

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    /// Called by MacPadApp to check for unsaved edits
    var shouldPromptIfDirty: (() -> Bool)?

    /// Called by MacPadApp to perform a save-as & then terminate
    var performSave: (() -> Void)?

    /// Skip next prompt when quitting after a save-as
    private var skipNextTerminationPrompt = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Become each window’s delegate so we intercept the red “X”
        NSApp.windows.forEach { $0.delegate = self }
    }

    // MARK: – Quit (Cmd-Q)
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if skipNextTerminationPrompt {
            return .terminateNow
        }
        guard shouldPromptIfDirty?() == true else {
            return .terminateNow
        }
        switch runSaveAlert() {
        case .saveAs:
            performSave?()
            return .terminateNow
        case .dontSave:
            return .terminateNow
        case .cancel:
            return .terminateCancel
        }
    }

    // MARK: – Red “X” / window-close
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard shouldPromptIfDirty?() == true else {
            return true
        }
        switch runSaveAlert() {
        case .saveAs:
            skipNextTerminationPrompt = true
            performSave?()
            return false
        case .dontSave:
            skipNextTerminationPrompt = true
            NSApp.terminate(nil)
            return false
        case .cancel:
            return false
        }
    }

    private enum AlertResult { case saveAs, dontSave, cancel }

    private func runSaveAlert() -> AlertResult {
        let alert = NSAlert()
        alert.messageText = "You have unsaved changes."
        alert.informativeText = "Do you want to save your document before closing?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save As")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn: return .saveAs
        case .alertSecondButtonReturn: return .dontSave
        default:                   return .cancel
        }
    }
}

