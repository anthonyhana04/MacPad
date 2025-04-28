// FileService.swift
import AppKit
import UniformTypeIdentifiers

@MainActor
final class FileService {
    static let shared = FileService()
    private init() {}

    /// Create a brand-new file; return nil if the user cancels.
    func newFile(in window: NSWindow) async -> (text: String, name: String)? {
        if let url = await saveAs(in: window, initialText: "", suggestedName: "Untitled") {
            return ("", url.lastPathComponent)
        } else {
            return nil
        }
    }

    /// Open an existing document; return nil if the user cancels.
    func openFile(in window: NSWindow) async -> (text: String, name: String)? {
        await withCheckedContinuation { cont in
            let panel = NSOpenPanel()
            panel.allowedContentTypes  = [UTType.plainText, UTType.rtf]
            panel.allowsOtherFileTypes = true

            panel.beginSheetModal(for: window) { resp in
                guard resp == .OK, let url = panel.url else {
                    cont.resume(returning: nil)
                    return
                }

                if url.pathExtension.lowercased() == "rtf",
                   let attr = try? NSAttributedString(
                       url: url,
                       options: [:],
                       documentAttributes: nil
                   ) {
                    cont.resume(returning: (attr.string, url.lastPathComponent))
                } else {
                    let txt = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
                    cont.resume(returning: (txt, url.lastPathComponent))
                }
            }
        }
    }

    /// “Save As” sheet: show a Save panel, and if the user picks a URL, write the text out.
    func saveAs(
        in window: NSWindow,
        initialText: String,
        suggestedName: String = "Untitled"
    ) async -> URL? {
        await withCheckedContinuation { cont in
            let panel = NSSavePanel()
            panel.allowedContentTypes      = [UTType.plainText, UTType.rtf]
            panel.allowsOtherFileTypes     = true
            panel.nameFieldStringValue     = suggestedName
            panel.canSelectHiddenExtension = true

            panel.beginSheetModal(for: window) { resp in
                guard resp == .OK, let url = panel.url else {
                    cont.resume(returning: nil)
                    return
                }

                if url.pathExtension.lowercased() == "rtf" {
                    let attr = NSAttributedString(string: initialText)
                    if let data = try? attr.data(
                        from: NSRange(location: 0, length: attr.length),
                        documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
                    ) {
                        try? data.write(to: url)
                    }
                } else {
                    try? initialText.write(to: url, atomically: true, encoding: .utf8)
                }

                cont.resume(returning: url)
            }
        }
    }
}

