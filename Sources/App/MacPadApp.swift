import SwiftUI

@main
struct MacPadApp: App {
    // 1️⃣  Single shared ThemeManager instance
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
        .commands {           // native ⌘N / ⌘O / ⌘S shortcuts
            CommandGroup(replacing: .newItem) {
                Button("New", action: themeManager.newDocument)
                    .keyboardShortcut("n")
            }
            CommandGroup(after: .saveItem) {
                Button("Open…", action: themeManager.openDocument)
                    .keyboardShortcut("o")
                Button("Save…", action: themeManager.saveDocument)
                    .keyboardShortcut("s")
            }
        }
    }
}

