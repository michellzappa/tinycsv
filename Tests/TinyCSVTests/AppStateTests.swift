import Foundation
import XCTest
@testable import TinyCSV

final class AppStateTests: XCTestCase {
    func testParsedRowsHandleQuotedFieldsCRLFAndTrailingEmptyCells() {
        let state = AppState()
        state.selectedFile = URL(fileURLWithPath: "/tmp/sample.csv")
        state.content = "\"Name\",Age,Note,\r\n\"Doe, Jane\",42,\"hello \"\"there\"\"\",\r\n"

        XCTAssertEqual(
            state.parsedRows,
            [
                ["Name", "Age", "Note", ""],
                ["Doe, Jane", "42", "hello \"there\"", ""],
            ]
        )
    }

    func testExportHTMLBuildsEscapedTableMarkup() {
        let state = AppState()
        state.selectedFile = URL(fileURLWithPath: "/tmp/sample.tsv")
        state.content = "name\tvalue\nfoo\t<bar>"

        let html = state.exportHTML

        XCTAssertTrue(html.contains("<th>name</th>"))
        XCTAssertTrue(html.contains("<td>foo</td>"))
        XCTAssertTrue(html.contains("&lt;bar&gt;"))
    }
}
