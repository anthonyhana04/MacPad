// Sources/App/EncodingManager.swift
import Foundation
import SwiftUI

struct EncodingOption: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let encoding: String.Encoding
    
    static let common: [EncodingOption] = [
        EncodingOption(name: "UTF-8", encoding: .utf8),
        EncodingOption(name: "UTF-16", encoding: .utf16),
        EncodingOption(name: "ASCII", encoding: .ascii),
        EncodingOption(name: "ISO Latin 1", encoding: .isoLatin1),
        EncodingOption(name: "Japanese (EUC)", encoding: .japaneseEUC),
        EncodingOption(name: "Japanese (Shift JIS)", encoding: .shiftJIS),
        EncodingOption(name: "Chinese Simplified", encoding: .init(rawValue: 0x80000632)), // macChineseSimp
        EncodingOption(name: "Chinese Traditional", encoding: .init(rawValue: 0x80000A03)), // macChineseTrad
        EncodingOption(name: "Central/East European", encoding: .windowsCP1250),
        EncodingOption(name: "Cyrillic", encoding: .windowsCP1251),
        EncodingOption(name: "CP-1252 (Single Byte)", encoding: .windowsCP1252)
    ]
}

@MainActor
final class EncodingManager: ObservableObject {
    @Published var currentEncoding: EncodingOption {
        didSet {
            UserDefaults.standard.set(currentEncoding.encoding.rawValue, forKey: "defaultEncoding")
        }
    }
    
    let availableEncodings = EncodingOption.common
    
    init() {
        let rawValue = UserDefaults.standard.integer(forKey: "defaultEncoding")
        let encoding = String.Encoding(rawValue: UInt(rawValue))
        if let option = EncodingOption.common.first(where: { $0.encoding == encoding }) {
            self.currentEncoding = option
        } else {
            self.currentEncoding = EncodingOption.common.first(where: { $0.encoding == .utf8 })!
        }
    }
    
    func setEncoding(_ encoding: EncodingOption) {
        currentEncoding = encoding
    }
    
    func detectEncoding(from data: Data) -> String.Encoding? {
        if let _ = String(data: data, encoding: .utf8) {
            return .utf8
        }
        for option in availableEncodings {
            if let _ = String(data: data, encoding: option.encoding) {
                return option.encoding
            }
        }
        
        return nil
    }
}
