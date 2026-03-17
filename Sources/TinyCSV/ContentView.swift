import SwiftUI
import TinyKit

struct ContentView: View {
    @Bindable var state: AppState
    @Binding var columnVisibility: NavigationSplitViewVisibility
    @AppStorage("wordWrap") private var wordWrap = false
    @AppStorage("previewUserPref") private var previewUserPref = true
    @AppStorage("fontSize") private var fontSize: Double = 13
    @State private var showQuickOpen = false
    @AppStorage("showLineNumbers") private var showLineNumbers = false
    @State private var eventMonitor: Any?
    @State private var jumpToRange: NSRange?

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            TinyFileList(state: state)
                .navigationSplitViewColumnWidth(min: 160, ideal: 200, max: 300)
        } detail: {
            VStack(spacing: 0) {
                if state.tabs.count > 1 {
                    TinyTabBar(state: state)
                    Divider()
                }
                if previewUserPref {
                    EditorSplitView {
                        TinyEditorView(
                            text: $state.content,
                            wordWrap: $wordWrap,
                            fontSize: $fontSize,
                            showLineNumbers: $showLineNumbers,
                            shouldHighlight: true,
                            highlighterProvider: { CSVHighlighter() },
                            commentStyle: .hash,
                            jumpToRange: $jumpToRange
                        )
                    } right: {
                        CSVPreviewView(rows: state.parsedRows, wordWrap: $wordWrap) { row, col in
                            jumpToRange = csvRange(row: row, col: col, in: state.content, delimiter: state.delimiter)
                        }
                    }
                } else {
                    TinyEditorView(
                        text: $state.content,
                        wordWrap: $wordWrap,
                        fontSize: $fontSize,
                        showLineNumbers: $showLineNumbers,
                        shouldHighlight: true,
                        highlighterProvider: { CSVHighlighter() },
                        commentStyle: .hash,
                        jumpToRange: $jumpToRange
                    )
                }

                StatusBarView(text: state.content)
            }
        }
        .onDisappear {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }
        .onAppear {
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                let chars = event.charactersIgnoringModifiers ?? ""

                if flags == .option && chars == "z" {
                    wordWrap.toggle()
                    return nil
                }
                if flags == .option && chars == "p" {
                    previewUserPref.toggle()
                    return nil
                }
                if flags == .option && chars == "l" {
                    showLineNumbers.toggle()
                    return nil
                }
                if flags == .command && chars == "p" {
                    showQuickOpen.toggle()
                    return nil
                }
                if flags == .command && chars == "w" && state.tabs.count > 1 {
                    state.closeActiveTab()
                    return nil
                }
                if flags == .command && (chars == "=" || chars == "+") {
                    fontSize = min(fontSize + 1, 32)
                    return nil
                }
                if flags == .command && chars == "-" {
                    fontSize = max(fontSize - 1, 9)
                    return nil
                }
                if flags == .command && chars == "0" {
                    fontSize = 13
                    return nil
                }
                if flags == .command && (chars == "f" || chars == "g") {
                    return event
                }
                if flags == [.command, .shift] && chars == "g" {
                    return event
                }
                return event
            }
        }
        .sheet(isPresented: $showQuickOpen) {
            QuickOpenView(state: state, isPresented: $showQuickOpen)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: 12) {
                    Button {
                        wordWrap.toggle()
                    } label: {
                        Image(systemName: wordWrap ? "text.word.spacing" : "arrow.left.and.right.text.vertical")
                    }
                    .help("Toggle Word Wrap (\u{2325}Z)")
                    Button {
                        showLineNumbers.toggle()
                    } label: {
                        Image(systemName: showLineNumbers ? "list.number" : "list.bullet")
                    }
                    .help("Toggle Line Numbers (\u{2325}L)")
                    Button {
                        withAnimation { previewUserPref.toggle() }
                    } label: {
                        Image(systemName: previewUserPref ? "rectangle.righthalf.filled" : "rectangle.righthalf.inset.filled")
                    }
                    .help("Toggle Table Preview (\u{2325}P)")
                }
            }
        }
    }

    /// Find the NSRange of a specific cell in raw CSV text.
    /// `row` is 0-based including header (row 0 = header line).
    private func csvRange(row: Int, col: Int, in text: String, delimiter: Character) -> NSRange {
        let ns = text as NSString
        var lineStart = 0
        var currentLine = 0

        while lineStart < ns.length && currentLine < row {
            let lineRange = ns.lineRange(for: NSRange(location: lineStart, length: 0))
            lineStart = lineRange.location + lineRange.length
            currentLine += 1
        }

        guard currentLine == row, lineStart < ns.length else {
            return NSRange(location: max(ns.length - 1, 0), length: 0)
        }

        let lineRange = ns.lineRange(for: NSRange(location: lineStart, length: 0))
        let line = ns.substring(with: lineRange)

        // Walk columns
        var fieldStart = 0
        var currentCol = 0
        var inQuotes = false

        for (i, char) in line.enumerated() {
            if char == "\"" {
                inQuotes.toggle()
            } else if !inQuotes && char == delimiter {
                if currentCol == col {
                    let absStart = lineRange.location + fieldStart
                    return NSRange(location: absStart, length: i - fieldStart)
                }
                currentCol += 1
                fieldStart = i + 1
            }
        }

        // Last field
        if currentCol == col {
            let absStart = lineRange.location + fieldStart
            var len = line.count - fieldStart
            if line.hasSuffix("\n") { len -= 1 }
            if line.hasSuffix("\r\n") { len -= 1 }
            return NSRange(location: absStart, length: max(len, 0))
        }

        return NSRange(location: lineRange.location, length: 0)
    }
}
