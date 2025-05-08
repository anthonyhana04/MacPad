// Sources/App/EncodingManager.swift
import Foundation
import SwiftUI

struct EncodingOption: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let encoding: String.Encoding
    let region: EncodingRegion
    
    static let common: [EncodingOption] = [
        // Common Western encodings
        EncodingOption(name: "UTF-8", encoding: .utf8, region: .universal),
        EncodingOption(name: "UTF-16", encoding: .utf16, region: .universal),
        EncodingOption(name: "ASCII", encoding: .ascii, region: .western),
        EncodingOption(name: "ISO Latin 1", encoding: .isoLatin1, region: .western),
        
        // Middle Eastern / Arabic encodings
        EncodingOption(name: "Arabic (Windows)", encoding: .init(rawValue: 0x0505), region: .middleEastern), // windowsArabic (1256)
        EncodingOption(name: "Arabic (ISO)", encoding: .init(rawValue: 0x0606), region: .middleEastern), // isoArabic
        EncodingOption(name: "Hebrew", encoding: .init(rawValue: 0x0505), region: .middleEastern), // windowsHebrew (1255)
        
        // South Asian encodings
        EncodingOption(name: "Devanagari (Hindi)", encoding: .init(rawValue: 0x0910), region: .southAsian), // devanagari
        EncodingOption(name: "Gurmukhi (Punjabi)", encoding: .init(rawValue: 0x0911), region: .southAsian), // gurmukhi
        EncodingOption(name: "Gujarati", encoding: .init(rawValue: 0x0912), region: .southAsian), // gujarati
        
        // East Asian encodings
        EncodingOption(name: "Japanese (EUC)", encoding: .japaneseEUC, region: .eastAsian),
        EncodingOption(name: "Japanese (Shift JIS)", encoding: .shiftJIS, region: .eastAsian),
        EncodingOption(name: "Chinese Simplified", encoding: .init(rawValue: 0x80000632), region: .eastAsian), // macChineseSimp
        EncodingOption(name: "Chinese Traditional", encoding: .init(rawValue: 0x80000A03), region: .eastAsian), // macChineseTrad
        EncodingOption(name: "Korean (EUC)", encoding: .init(rawValue: 0x80000630), region: .eastAsian), // macKorean
        
        // European encodings
        EncodingOption(name: "Central/East European", encoding: .windowsCP1250, region: .european),
        EncodingOption(name: "Cyrillic", encoding: .windowsCP1251, region: .european),
        EncodingOption(name: "Windows Latin-1", encoding: .windowsCP1252, region: .western)
    ]
}

enum EncodingRegion: String, CaseIterable {
    case universal = "Universal"
    case western = "Western"
    case european = "European"
    case eastAsian = "East Asian"
    case middleEastern = "Middle Eastern"
    case southAsian = "South Asian"
}

@MainActor
final class EncodingManager: ObservableObject {
    @Published var currentEncoding: EncodingOption {
        didSet {
            UserDefaults.standard.set(currentEncoding.encoding.rawValue, forKey: "defaultEncoding")
        }
    }
    
    let availableEncodings = EncodingOption.common
    
    var encodingsByRegion: [EncodingRegion: [EncodingOption]] {
        Dictionary(grouping: availableEncodings) { $0.region }
    }
    
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

        if let _ = String(data: data, encoding: .utf16) {
            return .utf16
        }
        
        for option in availableEncodings {
            if let _ = String(data: data, encoding: option.encoding) {
                return option.encoding
            }
        }
        
        return nil
    }
    
    func scriptDescription(for encoding: EncodingOption) -> String {
        switch encoding.region {
            case .universal:
                return "Supports most writing systems"
            case .western:
                return "Supports Latin, Greek, and some symbols"
            case .european:
                return "Supports Latin, Cyrillic, and Central European scripts"
            case .eastAsian:
                return "Supports Chinese, Japanese, or Korean characters"
            case .middleEastern:
                return "Supports Arabic, Hebrew, and Middle Eastern scripts"
            case .southAsian:
                return "Supports Devanagari, Gurmukhi, and other South Asian scripts"
        }
    }
}
