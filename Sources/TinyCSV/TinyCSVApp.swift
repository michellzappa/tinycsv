import SwiftUI
import TinyKit

@main
struct TinyCSVApp: App {
    @State private var state = AppState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic

    var body: some Scene {
        WindowGroup {
            Group {
                if state.folderURL == nil && WelcomeState.isFirstLaunch {
                    TinyWelcomeView(
                        appName: "TinyCSV",
                        subtitle: "A tiny CSV editor.",
                        features: [
                            (icon: "tablecells", title: "Table Preview", description: "See your data as a formatted table"),
                            (icon: "paintbrush", title: "Syntax Highlighting", description: "Color-coded columns and delimiters"),
                            (icon: "doc.on.doc", title: "Tabs", description: "Edit multiple files at once"),
                            (icon: "folder.badge.gearshape", title: "File Watcher", description: "Auto-reload on external changes"),
                        ],
                        onOpenFolder: {
                            state.openFolder()
                            WelcomeState.markLaunched()
                        },
                        onDismiss: {
                            WelcomeState.markLaunched()
                        }
                    )
                } else {
                    ContentView(state: state, columnVisibility: $columnVisibility)
                }
            }
            .navigationTitle(state.selectedFile?.lastPathComponent ?? "TinyCSV")
            .frame(minWidth: 600, minHeight: 400)
            .onAppear {
                state.restoreLastFolder()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                state.saveAllDirtyTabs()
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New File") {
                    state.newFile()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open Folder...") {
                    state.openFolder()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .sidebar) {
                Button("Toggle Sidebar") {
                    withAnimation {
                        columnVisibility = columnVisibility == .detailOnly ? .automatic : .detailOnly
                    }
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
        }

    }
}
