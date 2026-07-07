import XCTest

final class FilterCycleUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAddFlowShowsNewItem() throws {
        app.buttons["addButton"].tap()
        let nameField = app.textFields["nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("New Test Filter")
        app.buttons["saveButton"].tap()
        XCTAssertTrue(app.staticTexts["New Test Filter"].waitForExistence(timeout: 2))
    }

    func testFreeLimitTriggersPaywall() throws {
        for i in 0..<(6 + 1) {
            app.buttons["addButton"].tap()
            let nameField = app.textFields["nameField"]
            if nameField.waitForExistence(timeout: 2) {
                nameField.tap()
                nameField.typeText("Item \(i)")
                app.buttons["saveButton"].tap()
            } else {
                break
            }
        }
        XCTAssertTrue(app.buttons["unlockProButton"].waitForExistence(timeout: 3))
    }

    func testKeyboardDismissesOnTapOutside() throws {
        app.buttons["addButton"].tap()
        let nameField = app.textFields["nameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Sample")
        XCTAssertTrue(app.keyboards.element.exists)
        app.navigationBars.element.tap()
        XCTAssertFalse(app.keyboards.element.exists)
    }

    func testCancelDismissesAddSheet() throws {
        app.buttons["addButton"].tap()
        XCTAssertTrue(app.buttons["cancelButton"].waitForExistence(timeout: 2))
        app.buttons["cancelButton"].tap()
        XCTAssertFalse(app.textFields["nameField"].exists)
    }

    func testSettingsSheetOpens() throws {
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.buttons["settingsDoneButton"].waitForExistence(timeout: 2))
        app.buttons["settingsDoneButton"].tap()
    }
}
