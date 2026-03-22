import SwiftUI
import TinyKit
import UniformTypeIdentifiers

@main
struct TinyCSVApp: App {
    @NSApplicationDelegateAdaptor(TinyAppDelegate.self) var appDelegate
    @State private var state = AppState()
    @State private var columnVisibility: NavigationSplitViewVisibility = .automatic
    @State private var showWelcome = false

    var body: some Scene {
        WindowGroup {
            ContentView(state: state, columnVisibility: $columnVisibility)
                .defaultAppBanner(appName: "TinyCSV", associations: [
                    FileTypeAssociation(utType: .commaSeparatedText, label: ".csv files"),
                    FileTypeAssociation(utType: .tabSeparatedText, label: ".tsv files"),
                ])
                .navigationTitle(state.selectedFile?.lastPathComponent ?? "TinyCSV")
                .frame(minWidth: 600, minHeight: 400)
                .onAppear {
                    if !TinyAppDelegate.pendingFiles.isEmpty {
                        let files = TinyAppDelegate.pendingFiles
                        TinyAppDelegate.pendingFiles.removeAll()
                        openFiles(files)
                    } else if WelcomeState.isFirstLaunch {
                        showWelcome = true
                    } else {
                        state.restoreLastFolder()
                    }

                    TinyAppDelegate.onOpenFiles = { [weak state] urls in
                        guard let state else { return }
                        openFilesInState(urls, state: state)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    state.saveAllDirtyTabs()
                }
                .welcomeSheet(
                    isPresented: $showWelcome,
                    appName: "TinyCSV",
                    subtitle: "A minimal, fast CSV editor for macOS.",
                    features: [
                        (icon: "tablecells", title: "Table Preview", description: "See your data as a formatted table"),
                        (icon: "paintbrush", title: "Syntax Highlighting", description: "Color-coded columns and delimiters"),
                        (icon: "doc.on.doc", title: "Tabs", description: "Edit multiple files at once"),
                        (icon: "folder.badge.gearshape", title: "File Watcher", description: "Auto-reload on external changes"),
                    ],
                    onOpenFolder: { state.openFolder() },
                    onOpenFile: { state.openFile() },
                    onDismiss: { state.restoreLastFolder() }
                )
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About TinyCSV") {
                    NSApp.orderFrontStandardAboutPanel()
                }
                Divider()
                Button("Feedback\u{2026}") {
                    NSWorkspace.shared.open(URL(string: "https://tinysuite.app/support.html")!)
                }
                Button("TinySuite Website") {
                    NSWorkspace.shared.open(URL(string: "https://tinysuite.app")!)
                }
            }
            CommandGroup(replacing: .help) {
                Button("TinyCSV on GitHub") {
                    NSWorkspace.shared.open(URL(string: "https://github.com/michellzappa/tinycsv")!)
                }
            }
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
                RecentFilesMenu { url in
                    state.selectFile(url)
                }

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

    private func openFiles(_ urls: [URL]) {
        openFilesInState(urls, state: state)
    }

    private func openFilesInState(_ urls: [URL], state: AppState) {
        guard let url = urls.first else { return }
        let folder = url.deletingLastPathComponent()
        if state.folderURL != folder {
            state.setFolder(folder)
        }
        state.selectFile(url)
        columnVisibility = .detailOnly
    }
}
