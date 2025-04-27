import AppKit
import UniformTypeIdentifiers   // UTType.plainText / .rtf

/// All document I/O lives here.
@MainActor
final class FileService {

    // MARK: Singleton
    static let shared = FileService()
    private init() {}

    // MARK: Blank / New
    func newFile() -> (text: String, name: String) {
        ("", "Untitled")
    }

    // MARK: Open
    func openFile() -> (text: String, name: String) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes      = [UTType.item]     // allow any file
        panel.allowsMultipleSelection  = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return newFile()
        }

        // RTF → plain string
        if url.pathExtension.lowercased() == "rtf",
           let attr = try? NSAttributedString(url: url,
                                              options: [:],
                                              documentAttributes: nil) {
            return (attr.string, url.lastPathComponent)
        }

        // everything else → try UTF-8 text
        let txt = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        return (txt, url.lastPathComponent)
    }

    // MARK: Save As (modal ⇒ always appears)
    func saveAsModal(initialText: String,
                     suggestedName: String = "Untitled") -> URL? {

        let panel = NSSavePanel()
        panel.allowedContentTypes      = [UTType.plainText, UTType.rtf]
        panel.allowsOtherFileTypes     = true
        panel.nameFieldStringValue     = suggestedName
        panel.canSelectHiddenExtension = true

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        if url.pathExtension.lowercased() == "rtf" {
            let attr = NSAttributedString(string: initialText)
            if let data = try? attr.data(
                    from: NSRange(location: 0, length: attr.length),
                    documentAttributes: [.documentType:
                        NSAttributedString.DocumentType.rtf]) {
                try? data.write(to: url)
            }
        } else {
            try? initialText.write(to: url,
                                   atomically: true,
                                   encoding: .utf8)
        }
        return url
    }
}

