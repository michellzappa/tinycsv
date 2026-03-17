import SwiftUI

/// Renders parsed CSV data as a native SwiftUI table.
struct CSVPreviewView: View {
    let rows: [[String]]

    private var headers: [String] {
        guard let first = rows.first else { return [] }
        return first
    }

    private var dataRows: [[String]] {
        guard rows.count > 1 else { return [] }
        return Array(rows.dropFirst())
    }

    var body: some View {
        if rows.isEmpty {
            ContentUnavailableView("No Data", systemImage: "tablecells", description: Text("Open a CSV file to see its contents"))
        } else {
            ScrollView([.horizontal, .vertical]) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        ForEach(Array(headers.enumerated()), id: \.offset) { index, header in
                            Text(header)
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .lineLimit(1)
                                .frame(minWidth: 80, maxWidth: 200, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(Color.accentColor.opacity(0.1))
                            if index < headers.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .background(Color.accentColor.opacity(0.05))

                    Divider()

                    // Data rows
                    ForEach(Array(dataRows.enumerated()), id: \.offset) { rowIndex, row in
                        HStack(spacing: 0) {
                            ForEach(Array(headers.indices), id: \.self) { colIndex in
                                let value = colIndex < row.count ? row[colIndex] : ""
                                Text(value)
                                    .font(.system(size: 12, design: .monospaced))
                                    .lineLimit(1)
                                    .frame(minWidth: 80, maxWidth: 200, alignment: .leading)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                if colIndex < headers.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .background(rowIndex % 2 == 0 ? Color.clear : Color.primary.opacity(0.03))

                        if rowIndex < dataRows.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
    }
}
