// Sources/Services/FileService.swift
import AppKit
import UniformTypeIdentifiers

@MainActor
final class FileService {
    static let shared = FileService()
    private init() {}

    func newFile(in window: NSWindow) async -> (text: String, name: String)? {
        guard let url = await saveAs(
            in: window,
            initialText: "",
            suggestedName: "Untitled",
            encoding: .utf8
        ) else {
            return nil
        }
        return ("", url.lastPathComponent)
    }

    func openFile(in window: NSWindow, encodingManager: EncodingManager) async -> (text: String, name: String, url: URL, encoding: String.Encoding)? {
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
                    cont.resume(returning: (
                        text: attr.string,
                        name: url.lastPathComponent,
                        url: url,
                        encoding: .utf8
                    ))
                } else {
                    do {
                        let data = try Data(contentsOf: url)

                        if let detectedEncoding = encodingManager.detectEncoding(from: data) {
                            if let text = String(data: data, encoding: detectedEncoding) {
                                cont.resume(returning: (
                                    text: text,
                                    name: url.lastPathComponent,
                                    url: url,
                                    encoding: detectedEncoding
                                ))
                                return
                            }
                        }
                        if let text = String(data: data, encoding: .utf8) {
                            cont.resume(returning: (
                                text: text,
                                name: url.lastPathComponent,
                                url: url,
                                encoding: .utf8
                            ))
                        } else {
                            let currentEncoding = encodingManager.currentEncoding.encoding
                            if let text = String(data: data, encoding: currentEncoding) {
                                cont.resume(returning: (
                                    text: text,
                                    name: url.lastPathComponent,
                                    url: url,
                                    encoding: currentEncoding
                                ))
                            } else {
                                cont.resume(returning: (
                                    text: "",
                                    name: url.lastPathComponent,
                                    url: url,
                                    encoding: .utf8
                                ))
                            }
                        }
                    } catch {
                        cont.resume(returning: (
                            text: "",
                            name: url.lastPathComponent,
                            url: url,
                            encoding: .utf8
                        ))
                    }
                }
            }
        }
    }

    func saveAs(
        in window: NSWindow,
        initialText: String,
        suggestedName: String = "Untitled",
        encoding: String.Encoding = .utf8
    ) async -> URL? {
        await withCheckedContinuation { cont in
            let panel = NSSavePanel()
            panel.allowedContentTypes = [UTType.plainText, UTType.rtf]
            panel.allowsOtherFileTypes = true
            panel.nameFieldStringValue = suggestedName
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
                    if let data = initialText.data(using: encoding) {
                        try? data.write(to: url)
                    } else {
                        try? initialText.write(to: url, atomically: true, encoding: .utf8)
                    }
                }

                cont.resume(returning: url)
            }
        }
    }
}
