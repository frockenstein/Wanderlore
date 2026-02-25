import Foundation
import CoreLocation

/// A single point of interest the user has passed through during a tour.
///
/// Appended to `MainViewModel.visitedLocations` each time the pipeline
/// successfully generates a narration for a new location. Used to populate
/// the history map with annotation dots showing the user's path.
struct VisitedLocation: Identifiable {

    /// Stable unique identifier used as the Map annotation tag for tap-selection handling.
    let id: UUID

    /// GPS coordinate of the Wikipedia article's subject — where the dot appears on the map.
    let coordinate: CLLocationCoordinate2D

    /// Wikipedia article title — shown as the annotation label and detail card header.
    let title: String

    /// Claude's narration for this location — shown in the detail card when the dot is tapped.
    let narration: String

    /// Wall-clock time this location was visited — reserved for future timeline/history features.
    let visitedAt: Date

    init(coordinate: CLLocationCoordinate2D, title: String, narration: String) {
        self.id = UUID()
        self.coordinate = coordinate
        self.title = title
        self.narration = narration
        self.visitedAt = Date()
    }
}
