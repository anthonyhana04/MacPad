import SwiftUI

final class ThemeManager: ObservableObject {
    // Persist the user choice in UserDefaults
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false {
        didSet { objectWillChange.send() }
    }

    var colorScheme: ColorScheme { isDarkMode ? .dark : .light }

    // Toggle called by the moon/sun button
    func toggleTheme() { isDarkMode.toggle() }

    // MARK: - Document menu helpers (delegate to FileService)
    func newDocument()   { FileService.shared.newFile()   }
    func openDocument()  { FileService.shared.openFile()  }
    func saveDocument()  { FileService.shared.saveFile()  }
}

