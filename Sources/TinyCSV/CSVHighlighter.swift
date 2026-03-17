import AppKit
import TinyKit

/// Syntax highlighter for CSV/TSV files.
/// Colors delimiters, alternates column colors, and highlights the header row.
final class CSVHighlighter: SyntaxHighlighting {
    var baseFont: NSFont = .monospacedSystemFont(ofSize: 14, weight: .regular)

    private var delimiterColor: NSColor {
        NSColor.controlAccentColor.withAlphaComponent(0.7)
    }

    // Alternating column colors for readability
    private var columnColors: [NSColor] {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        if isDark {
            return [
                NSColor.white,
                NSColor.white.withAlphaComponent(0.6),
            ]
        } else {
            return [
                NSColor.black,
                NSColor.black.withAlphaComponent(0.5),
            ]
        }
    }

    func highlight(_ textStorage: NSTextStorage) {
        let source = textStorage.string
        let fullRange = NSRange(location: 0, length: (source as NSString).length)
        guard fullRange.length > 0 else { return }

        textStorage.beginEditing()

        // Reset to base
        textStorage.addAttributes([
            .font: baseFont,
            .foregroundColor: NSColor.textColor,
            .backgroundColor: NSColor.clear,
        ], range: fullRange)

        let nsSource = source as NSString
        let colors = columnColors
        let boldFont = NSFont.monospacedSystemFont(ofSize: baseFont.pointSize, weight: .bold)

        var lineStart = 0
        var isFirstLine = true

        while lineStart < nsSource.length {
            let lineRange = nsSource.lineRange(for: NSRange(location: lineStart, length: 0))
            let line = nsSource.substring(with: lineRange)

            var col = 0
            var fieldStart = lineRange.location
            var inQuotes = false

            for (i, char) in line.enumerated() {
                let absPos = lineRange.location + i
                if char == "\"" {
                    inQuotes.toggle()
                } else if !inQuotes && (char == "," || char == "\t") {
                    // Color the field
                    let fieldRange = NSRange(location: fieldStart, length: absPos - fieldStart)
                    if fieldRange.length > 0 {
                        let color = colors[col % colors.count]
                        textStorage.addAttribute(.foregroundColor, value: color, range: fieldRange)
                        if isFirstLine {
                            textStorage.addAttribute(.font, value: boldFont, range: fieldRange)
                        }
                    }
                    // Color the delimiter
                    textStorage.addAttribute(.foregroundColor, value: delimiterColor, range: NSRange(location: absPos, length: 1))
                    col += 1
                    fieldStart = absPos + 1
                }
            }

            // Last field on the line
            let remaining = lineRange.location + lineRange.length - fieldStart
            if remaining > 0 {
                // Exclude trailing newline from coloring
                let trimLen = (line.hasSuffix("\n") ? remaining - 1 : remaining)
                if trimLen > 0 {
                    let fieldRange = NSRange(location: fieldStart, length: trimLen)
                    let color = colors[col % colors.count]
                    textStorage.addAttribute(.foregroundColor, value: color, range: fieldRange)
                    if isFirstLine {
                        textStorage.addAttribute(.font, value: boldFont, range: fieldRange)
                    }
                }
            }

            isFirstLine = false
            lineStart = lineRange.location + lineRange.length
        }

        textStorage.endEditing()
    }
}
