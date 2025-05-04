import Foundation

struct Document: Identifiable, Equatable {
    var id = UUID()
    var text = ""
    var fileURL: URL? = nil
    var isDirty = false
    var workingName = "Untitled"
    var displayName: String { fileURL?.lastPathComponent ?? workingName }
    var hasUnsavedChanges: Bool {
        isDirty || (fileURL == nil && !text.isEmpty)
    }
}

