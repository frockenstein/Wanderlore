import XCTest

/// UI tests that launch the full app and drive it through XCTest's accessibility layer.
///
/// These tests verify that key interactive elements exist and are reachable by
/// accessibility identifier — important both for test reliability and for ensuring
/// the app is VoiceOver-accessible.
///
/// **Running UI tests:**
/// Select the WanderloreUITests scheme, choose a simulator, and press ⌘U.
/// UI tests require the app to compile and launch, so they're slower than unit tests
/// and shouldn't be run on every commit — reserve them for pre-release checks.
final class WanderloreUITests: XCTestCase {

    /// The app under test. Launched fresh before each test method.
    let app = XCUIApplication()

    override func setUpWithError() throws {
        // Stop on first failure — don't keep poking a broken UI state.
        continueAfterFailure = false
        // Cold-launch the app. Each test gets a clean session.
        app.launch()
    }

    // MARK: - Existence Tests

    /// Verifies the primary CTA button renders with its expected label.
    /// If this fails, StartStopButton's Text label was changed without updating tests.
    func testStartButtonExists() {
        XCTAssertTrue(app.buttons["Start Tour"].exists,
            "The Start Tour button should be visible on launch")
    }

    /// Verifies both mode segments exist in the ModePicker.
    /// Failure here means a TourMode case was renamed or the picker label was changed.
    func testModePickerExists() {
        XCTAssertTrue(app.buttons["Wander"].exists,
            "Wander mode button should be visible")
        XCTAssertTrue(app.buttons["Journey"].exists,
            "Journey mode button should be visible")
    }
}
