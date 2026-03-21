import SwiftUI
import TinyKit

@main
struct TinyCSVApp: App {
    @State private var state = AppState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showWelcome = false

    var body: some Scene {
        WindowGroup {
            ContentView(state: state, columnVisibility: $columnVisibility)
                .navigationTitle(state.selectedFile?.lastPathComponent ?? "TinyCSV")
                .frame(minWidth: 600, minHeight: 400)
                .onAppear {
                    if WelcomeState.isFirstLaunch {
                        showWelcome = true
                    } else {
                        state.restoreLastFolder()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    state.saveAllDirtyTabs()
                }
                .welcomeSheet(
                    isPresented: $showWelcome,
                    appName: "TinyCSV",
                    subtitle: "A tiny CSV editor.",
                    features: [
                        (icon: "tablecells", title: "Table Preview", description: "See your data as a formatted table"),
                        (icon: "paintbrush", title: "Syntax Highlighting", description: "Color-coded columns and delimiters"),
                        (icon: "doc.on.doc", title: "Tabs", description: "Edit multiple files at once"),
                        (icon: "folder.badge.gearshape", title: "File Watcher", description: "Auto-reload on external changes"),
                    ],
                    onOpen: { state.openFolder() },
                    onDismiss: { state.restoreLastFolder() }
                )
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
            CommandGroup(after: .newItem) {
                Divider()

                Button("Export as PDF\u{2026}") {
                    let name = state.selectedFile?.lastPathComponent ?? "data.csv"
                    ExportManager.exportPDF(html: state.exportHTML, suggestedName: name)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Button("Export as HTML\u{2026}") {
                    let name = state.selectedFile?.lastPathComponent ?? "data.csv"
                    ExportManager.exportHTML(html: state.exportHTML, suggestedName: name)
                }

                Divider()

                Button("Copy as Rich Text") {
                    ExportManager.copyAsRichText(body: state.exportHTML)
                }
                .keyboardShortcut("c", modifiers: [.command, .option])
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
