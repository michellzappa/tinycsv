import Foundation
import XCTest

final class TinyCSVUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunchesWithFixtureAndShowsLoadedRows() {
        let fixturePath = fixturePath(named: "sample.csv")
        let app = XCUIApplication()
        app.launchArguments += ["--ui-testing", "--disable-ai", "--disable-spotlight", "--disable-file-watchers"]
        app.launchEnvironment["TINY_FIXTURE_PATH"] = fixturePath

        app.launch()

        let probe = app.staticTexts["ui-smoke-status"]
        XCTAssertTrue(probe.waitForExistence(timeout: 10))
        XCTAssertTrue(probe.label.contains("sample.csv"))
        XCTAssertTrue(probe.label.contains("rows:3"))
    }

    private func fixturePath(named name: String) -> String {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures/\(name)")
            .path
    }
}
