import SwiftUI
import AppKit

/// Renders parsed CSV data as a sortable, resizable NSTableView.
struct CSVPreviewView: NSViewRepresentable {
    let rows: [[String]]
    @Binding var wordWrap: Bool
    /// Called when a cell is tapped: (originalRowIndex including header, columnIndex)
    var onCellTap: ((Int, Int) -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let tableView = NSTableView()

        tableView.style = .plain
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnReordering = true
        tableView.allowsColumnResizing = true
        tableView.allowsColumnSelection = false
        tableView.columnAutoresizingStyle = .noColumnAutoresizing
        tableView.intercellSpacing = NSSize(width: 8, height: 2)
        tableView.rowHeight = 20
        tableView.headerView = NSTableHeaderView()
        tableView.gridStyleMask = [.solidVerticalGridLineMask]

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false

        context.coordinator.tableView = tableView
        context.coordinator.onCellTap = onCellTap
        context.coordinator.updateData(rows: rows, wordWrap: wordWrap)

        tableView.target = context.coordinator
        tableView.action = #selector(Coordinator.tableClicked(_:))

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.onCellTap = onCellTap
        context.coordinator.updateData(rows: rows, wordWrap: wordWrap)
    }

    final class Coordinator: NSObject, NSTableViewDelegate, NSTableViewDataSource {
        var tableView: NSTableView?
        var onCellTap: ((Int, Int) -> Void)?
        private var headers: [String] = []
        private var dataRows: [[String]] = []
        private var sortedRows: [[String]] = []
        private var sortedIndices: [Int] = []  // maps sorted position → original data row index
        private var sortColumn: Int?
        private var sortAscending = true
        private var wordWrap = false

        func updateData(rows: [[String]], wordWrap: Bool) {
            guard let tableView else { return }

            let newHeaders = rows.first ?? []
            let newDataRows = rows.count > 1 ? Array(rows.dropFirst()) : []
            self.wordWrap = wordWrap

            // Only rebuild columns if headers changed
            if newHeaders != headers {
                headers = newHeaders
                dataRows = newDataRows
                sortColumn = nil
                sortAscending = true

                // Remove old columns
                for col in tableView.tableColumns.reversed() {
                    tableView.removeTableColumn(col)
                }

                // Add new columns
                for (i, header) in headers.enumerated() {
                    let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("col_\(i)"))
                    col.title = header
                    col.minWidth = 60
                    col.width = max(CGFloat(header.count * 9 + 20), 80)
                    col.maxWidth = 600
                    col.sortDescriptorPrototype = NSSortDescriptor(key: "\(i)", ascending: true)
                    tableView.addTableColumn(col)
                }

                sortedRows = dataRows
                sortedIndices = Array(0..<dataRows.count)
            } else {
                dataRows = newDataRows
                applySorting()
            }

            // Update row height for word wrap
            tableView.rowHeight = wordWrap ? 40 : 20

            tableView.reloadData()
        }

        private func applySorting() {
            let indexed = dataRows.enumerated().map { ($0.offset, $0.element) }
            if let col = sortColumn, col < headers.count {
                let sorted = indexed.sorted { a, b in
                    let va = col < a.1.count ? a.1[col] : ""
                    let vb = col < b.1.count ? b.1[col] : ""
                    if let na = Double(va), let nb = Double(vb) {
                        return sortAscending ? na < nb : na > nb
                    }
                    return sortAscending ? va.localizedCompare(vb) == .orderedAscending : va.localizedCompare(vb) == .orderedDescending
                }
                sortedIndices = sorted.map(\.0)
                sortedRows = sorted.map(\.1)
            } else {
                sortedIndices = Array(0..<dataRows.count)
                sortedRows = dataRows
            }
        }

        // MARK: - DataSource

        func numberOfRows(in tableView: NSTableView) -> Int {
            sortedRows.count
        }

        func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
            guard let tableColumn else { return nil }
            let id = tableColumn.identifier
            guard let colStr = id.rawValue.split(separator: "_").last,
                  let colIndex = Int(colStr),
                  row < sortedRows.count else { return nil }

            let value = colIndex < sortedRows[row].count ? sortedRows[row][colIndex] : ""

            let cellID = NSUserInterfaceItemIdentifier("cell")
            let cell: NSTextField
            if let existing = tableView.makeView(withIdentifier: cellID, owner: nil) as? NSTextField {
                cell = existing
            } else {
                cell = NSTextField(labelWithString: "")
                cell.identifier = cellID
                cell.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
                cell.cell?.truncatesLastVisibleLine = true
            }

            cell.stringValue = value
            cell.lineBreakMode = wordWrap ? .byWordWrapping : .byTruncatingTail
            cell.maximumNumberOfLines = wordWrap ? 3 : 1
            cell.toolTip = value

            return cell
        }

        // MARK: - Sorting

        func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
            guard let descriptor = tableView.sortDescriptors.first,
                  let key = descriptor.key,
                  let colIndex = Int(key) else { return }
            sortColumn = colIndex
            sortAscending = descriptor.ascending
            applySorting()
            tableView.reloadData()
        }

        // MARK: - Cell Click

        @objc func tableClicked(_ sender: NSTableView) {
            let row = sender.clickedRow
            let col = sender.clickedColumn
            guard row >= 0, col >= 0, row < sortedIndices.count else { return }
            // +1 because row 0 in original data is the header
            let originalRow = sortedIndices[row] + 1
            onCellTap?(originalRow, col)
        }
    }
}
