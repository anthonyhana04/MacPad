import Foundation

struct Document: Identifiable, Equatable {
    var id = UUID()
    var text = ""
    var fileURL: URL? = nil
    var isDirty = false
    var workingName = "Untitled"
    var encoding: String.Encoding = .utf8
    var displayName: String { fileURL?.lastPathComponent ?? workingName }
    var hasUnsavedChanges: Bool {
        isDirty || (fileURL == nil && !text.isEmpty)
    }
    
    static func == (lhs: Document, rhs: Document) -> Bool {
        lhs.id == rhs.id &&
        lhs.text == rhs.text &&
        lhs.fileURL == rhs.fileURL &&
        lhs.isDirty == rhs.isDirty &&
        lhs.workingName == rhs.workingName &&
        lhs.encoding == rhs.encoding
    }
}
