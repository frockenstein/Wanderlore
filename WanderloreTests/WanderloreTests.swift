import XCTest
@testable import Wanderlore  // @testable exposes internal types for unit testing

/// Unit tests for pure model and utility logic.
///
/// These tests have no external dependencies (no GPS, network, or TTS) so they
/// run fast in CI without any special setup. Add cases here whenever a business
/// rule lives in a model type rather than a service class.
final class WanderloreTests: XCTestCase {

    // MARK: - TourMode

    /// Verifies that Wander mode is always more sensitive (shorter threshold, smaller radius)
    /// than Journey mode. Catching an accidental value swap here would prevent a subtle
    /// bug where walking mode acts like driving mode and vice versa.
    func testTourModeThresholds() {
        XCTAssertLessThan(TourMode.wander.movementThreshold, TourMode.journey.movementThreshold,
            "Wander should fire more often (smaller threshold) than Journey")
        XCTAssertLessThan(TourMode.wander.searchRadius, TourMode.journey.searchRadius,
            "Wander should search a tighter radius than Journey")
    }

    // MARK: - InterestFilter

    /// Ensures every filter case has a non-empty SF Symbol name.
    /// A blank icon string would cause a broken image in the Settings toggle row.
    func testInterestFilterCoverage() {
        XCTAssertEqual(InterestFilter.allCases.count, 5,
            "Update this test if you add or remove filter cases")
        for filter in InterestFilter.allCases {
            XCTAssertFalse(filter.icon.isEmpty,
                "\(filter.rawValue) is missing an SF Symbol icon name")
        }
    }
}
