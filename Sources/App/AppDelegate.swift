// Sources/App/AppDelegate.swift
import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    var shouldPromptIfDirty: (() -> Bool)?
    var performSave: (() -> Void)?
    var skipNextTerminationPrompt = false
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if skipNextTerminationPrompt {
            skipNextTerminationPrompt = false
            return .terminateNow
        }
        guard shouldPromptIfDirty?() == true else {
            return .terminateNow
        }

        switch runSaveAlert() {
        case .saveAs:
            performSave?()
            return .terminateCancel
        case .dontSave:
            return .terminateNow
        case .cancel:
            return .terminateCancel
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        guard shouldPromptIfDirty?() == true else {
            return true
        }

        switch runSaveAlert() {
        case .saveAs:
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
        alert.informativeText = "Save before closing?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Save As")
        alert.addButton(withTitle: "Don't Save")
        alert.addButton(withTitle: "Cancel")

        switch alert.runModal() {
        case .alertFirstButtonReturn: return .saveAs
        case .alertSecondButtonReturn: return .dontSave
        default: return .cancel
        }
    }
}

