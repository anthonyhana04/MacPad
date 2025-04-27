import AppKit
import UniformTypeIdentifiers

/// All file-I/O lives here.
/// `FileService.shared` is a simple singleton the rest of the app can call.
final class FileService {

    // MARK: - Singleton
    static let shared = FileService()
    private init() {}

    // MARK: - New
    /// Returns a blank untitled document.
    func newFile() -> (text: String, name: String) {
        ("", "Untitled")
    }

    // MARK: - Open
    /// Opens a `.txt` file and returns its contents + display name.
    func openFile() -> (text: String, name: String) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .rtf]     // use UTType values
        panel.allowsOtherFileTypes = true                  // still keep “any” extension
        panel.canChooseDirectories = false

        guard panel.runModal() == .OK, let url = panel.url else {
            return newFile()
        }

        // Very small RTF → plain-text converter
        if url.pathExtension.lowercased() == "rtf",
           let attr = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
            return (attr.string, url.lastPathComponent)
        }

        let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        return (text, url.lastPathComponent)
    }

    // MARK: - Save (legacy wrapper)
    /// Called by `ThemeManager.saveDocument()`.  Simply forwards to `saveAs()`.
    func saveFile(initialText: String = "", suggestedName: String = "Untitled") -> URL? {
        saveAs(initialText: initialText, suggestedName: suggestedName)
    }

    // MARK: - Save As
    /// Lets the user choose **any** extension. Writes plain text except for `.rtf`.
    func saveAs(initialText: String, suggestedName: String = "Untitled") -> URL? {

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText, .rtf]     // use UTType values
        panel.allowsOtherFileTypes = true                  // still keep “any” extension
        panel.allowsOtherFileTypes     = true             // user may type *.md etc.
        panel.nameFieldStringValue     = suggestedName
        panel.canSelectHiddenExtension = true

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        if url.pathExtension.lowercased() == "rtf" {
            let attr = NSAttributedString(string: initialText)
            if let data = try? attr.data(from: NSRange(location: 0, length: attr.length),
                                         documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
                try? data.write(to: url)
            }
        } else {
            try? initialText.write(to: url, atomically: true, encoding: .utf8)
        }
        return url
    }
}

