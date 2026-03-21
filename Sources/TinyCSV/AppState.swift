import Foundation
import TinyKit

@Observable
final class AppState: FileState {
    init() {
        super.init(
            bookmarkKey: "lastFolderBookmark",
            defaultExtension: "csv",
            supportedExtensions: ["csv", "tsv", "txt", "text"]
        )
    }

    // MARK: - Spotlight

    private static let spotlightDomain = "com.tinyapps.tinycsv.files"

    override func didOpenFile(_ url: URL) {
        let headers = parsedRows.first?.joined(separator: ", ")
        SpotlightIndexer.index(file: url, content: content, domainID: Self.spotlightDomain, displayName: headers)
    }

    override func didSaveFile(_ url: URL) {
        didOpenFile(url)
    }

    // MARK: - Export

    var exportHTML: String {
        let rows = parsedRows
        guard !rows.isEmpty else {
            return ExportManager.wrapHTML(body: "<p>No data</p>", title: selectedFile?.lastPathComponent ?? "data")
        }
        var body = "<table><thead><tr>"
        for cell in rows[0] {
            body += "<th>\(ExportManager.escapeHTML(cell))</th>"
        }
        body += "</tr></thead><tbody>"
        for row in rows.dropFirst() {
            body += "<tr>"
            for cell in row {
                body += "<td>\(ExportManager.escapeHTML(cell))</td>"
            }
            body += "</tr>"
        }
        body += "</tbody></table>"
        return ExportManager.wrapHTML(body: body, title: selectedFile?.lastPathComponent ?? "data")
    }

    var isCSV: Bool {
        selectedFile?.pathExtension.lowercased() == "csv"
    }

    var isTSV: Bool {
        selectedFile?.pathExtension.lowercased() == "tsv"
    }

    var delimiter: Character {
        isTSV ? "\t" : ","
    }

    /// Parse CSV content into rows of columns.
    var parsedRows: [[String]] {
        parseCSV(content, delimiter: delimiter)
    }

    private func parseCSV(_ text: String, delimiter: Character) -> [[String]] {
        var rows: [[String]] = []
        var currentField = ""
        var currentRow: [String] = []
        var inQuotes = false

        for char in text {
            if inQuotes {
                if char == "\"" {
                    // Peek: if next is also quote, it's an escaped quote
                    // Simple approach: handle doubled quotes
                    inQuotes = false
                } else {
                    currentField.append(char)
                }
            } else {
                if char == "\"" {
                    inQuotes = true
                } else if char == delimiter {
                    currentRow.append(currentField)
                    currentField = ""
                } else if char == "\n" || char == "\r" {
                    if char == "\r" { continue } // skip \r, handle \n
                    currentRow.append(currentField)
                    currentField = ""
                    if !currentRow.allSatisfy({ $0.isEmpty }) || !currentRow.isEmpty {
                        rows.append(currentRow)
                    }
                    currentRow = []
                } else {
                    currentField.append(char)
                }
            }
        }
        // Last field/row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField)
            rows.append(currentRow)
        }
        return rows
    }
}
