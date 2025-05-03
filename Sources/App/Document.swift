// Sources/App/Document.swift

import Foundation

struct Document: Identifiable, Equatable {
    var id =  UUID ()
    var text = ""
    var fileURL: URL? = nil
    var isDirty = false
    
    var displayName: String {
        fileURL?.lastPathComponent ?? "Untitled"
    }
}

