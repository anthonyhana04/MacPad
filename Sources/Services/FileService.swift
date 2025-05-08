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
                        
                        if let detectedEncoding = self.detectFileEncoding(data, encodingManager: encodingManager) {
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
                        DispatchQueue.main.async {
                            self.showEncodingSelectionAlert(
                                window: window,
                                data: data,
                                url: url,
                                encodingManager: encodingManager
                            ) { selectedEncoding in
                                if let encoding = selectedEncoding,
                                   let text = String(data: data, encoding: encoding) {
                                    cont.resume(returning: (
                                        text: text,
                                        name: url.lastPathComponent,
                                        url: url,
                                        encoding: encoding
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
                    if let data = initialText.data(using: encoding, allowLossyConversion: false) {
                        try? data.write(to: url)
                    } else {
                        DispatchQueue.main.async {
                            let alert = NSAlert()
                            alert.messageText = "Encoding Warning"
                            alert.informativeText = "The current text contains characters that cannot be represented in the selected encoding. Saving may result in data loss."
                            alert.alertStyle = .warning
                            alert.addButton(withTitle: "Save Anyway (with substitutions)")
                            alert.addButton(withTitle: "Cancel")
                            
                            if alert.runModal() == .alertFirstButtonReturn {
                                if let data = initialText.data(using: encoding, allowLossyConversion: true) {
                                    try? data.write(to: url)
                                    cont.resume(returning: url)
                                } else {
                                    try? initialText.write(to: url, atomically: true, encoding: .utf8)
                                    cont.resume(returning: url)
                                }
                            } else {
                                cont.resume(returning: nil)
                            }
                        }
                        return
                    }
                }

                cont.resume(returning: url)
            }
        }
    }
    
    private func detectFileEncoding(_ data: Data, encodingManager: EncodingManager) -> String.Encoding? {
        if data.count >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF {
            return .utf8
        }
        
        if data.count >= 2 {
            if data[0] == 0xFF && data[1] == 0xFE {
                return .utf16LittleEndian
            }
            
            if data[0] == 0xFE && data[1] == 0xFF {
                return .utf16BigEndian
            }
        }
        
        if let _ = String(data: data, encoding: .utf8) {
            return .utf8
        }
        
        let currentEncoding = encodingManager.currentEncoding.encoding
        if let _ = String(data: data, encoding: currentEncoding) {
            return currentEncoding
        }
        
        if let _ = String(data: data, encoding: .utf16) {
            return .utf16
        }
        let languageCode = Locale.current.language.languageCode?.identifier ?? ""
        let scriptCode = Locale.current.language.script?.identifier ?? ""
        
        var prioritizedEncodings: [String.Encoding] = []
        
        // Arabic
        if languageCode.hasPrefix("ar") || scriptCode == "Arab" {
            prioritizedEncodings.append(.init(rawValue: 0x0505)) // windowsArabic (1256)
            prioritizedEncodings.append(.init(rawValue: 0x0606)) // isoArabic
        }
        // Hebrew
        else if languageCode.hasPrefix("he") || scriptCode == "Hebr" {
            prioritizedEncodings.append(.init(rawValue: 0x0505)) // windowsHebrew (1255)
        }
        // Hindi and other South Asian languages
        else if languageCode.hasPrefix("hi") || languageCode.hasPrefix("pa") ||
                scriptCode == "Deva" || scriptCode == "Gujr" || scriptCode == "Guru" {
            prioritizedEncodings.append(.utf8)
        }
        // Chinese
        else if languageCode.hasPrefix("zh") {
            if Locale.current.region?.identifier == "CN" {
                prioritizedEncodings.append(.init(rawValue: 0x80000632))
            } else {
                prioritizedEncodings.append(.init(rawValue: 0x80000A03))
            }
        }
        // Japanese
        else if languageCode.hasPrefix("ja") {
            prioritizedEncodings.append(.shiftJIS)
            prioritizedEncodings.append(.japaneseEUC)
        }
        // Korean
        else if languageCode.hasPrefix("ko") {
            prioritizedEncodings.append(.init(rawValue: 0x80000630))
        }
        // Eastern European
        else if ["cs", "hu", "pl", "ro", "hr", "sk", "sl"].contains(where: { languageCode.hasPrefix($0) }) {
            prioritizedEncodings.append(.windowsCP1250)
            prioritizedEncodings.append(.isoLatin2)
        }
        // Cyrillic
        else if ["ru", "uk", "bg", "sr", "mk"].contains(where: { languageCode.hasPrefix($0) }) {
            prioritizedEncodings.append(.windowsCP1251)
            prioritizedEncodings.append(.init(rawValue: 0x0205)) // iso8859_5
        }
        // Western European (default)
        else {
            prioritizedEncodings.append(.windowsCP1252)
            prioritizedEncodings.append(.isoLatin1)
            prioritizedEncodings.append(.macOSRoman)
        }
        for encoding in prioritizedEncodings {
            if let _ = String(data: data, encoding: encoding) {
                return encoding
            }
        }
        for option in encodingManager.availableEncodings {
            if !prioritizedEncodings.contains(option.encoding) {
                if let _ = String(data: data, encoding: option.encoding) {
                    return option.encoding
                }
            }
        }
        return nil
    }
    
    private func showEncodingSelectionAlert(
        window: NSWindow,
        data: Data,
        url: URL,
        encodingManager: EncodingManager,
        completion: @escaping (String.Encoding?) -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "Choose Encoding"
        alert.informativeText = "The file encoding couldn't be detected automatically. Please select an encoding:"
        
        let popupView = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 200, height: 25))
        
        let groupedEncodings = Dictionary(grouping: encodingManager.availableEncodings) { $0.region }
        
        for region in EncodingRegion.allCases {
            if let encodings = groupedEncodings[region], !encodings.isEmpty {
                let menuItem = NSMenuItem(title: region.rawValue, action: nil, keyEquivalent: "")
                menuItem.isEnabled = false
                popupView.menu?.addItem(menuItem)
                
                for encoding in encodings {
                    let item = NSMenuItem(title: encoding.name, action: nil, keyEquivalent: "")
                    item.representedObject = encoding
                    popupView.menu?.addItem(item)
                }
                
                popupView.menu?.addItem(NSMenuItem.separator())
            }
        }
        
        if let utf8Index = popupView.itemTitles.firstIndex(of: "UTF-8") {
            popupView.selectItem(at: utf8Index)
        }
        
        alert.accessoryView = popupView
        alert.addButton(withTitle: "Open")
        alert.addButton(withTitle: "Cancel")
        
        alert.beginSheetModal(for: window) { response in
            if response == .alertFirstButtonReturn {
                if let selectedItem = popupView.selectedItem,
                   let selectedEncoding = selectedItem.representedObject as? EncodingOption {
                    completion(selectedEncoding.encoding)
                } else {
                    completion(.utf8)
                }
            } else {
                completion(nil)
            }
        }
    }
}
