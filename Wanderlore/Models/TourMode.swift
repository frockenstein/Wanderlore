import Foundation

/// The two operating modes for a Wanderlore session.
///
/// Each mode tunes two key parameters of the core loop:
/// - `movementThreshold`: how far the user must walk/drive before a new fetch fires.
/// - `searchRadius`: how wide a net Wikipedia Geosearch casts around the current position.
///
/// The values are calibrated so Wander (foot traffic) gives hyper-local results
/// and re-triggers often, while Journey (road speed) fires less frequently and
/// casts a wider search net to keep up with faster movement.
enum TourMode: String, CaseIterable {
    case wander  = "Wander"   // pedestrian — city streets, hiking trails
    case journey = "Journey"  // vehicle — road trips, drives

    /// Minimum distance (meters) the user must travel from the last processed
    /// location before the fetch-and-narrate pipeline fires again.
    /// Acts as a dead zone to prevent repeated triggers in the same spot.
    var movementThreshold: Double {
        switch self {
        case .wander:  return 45.72   // ~150 ft  — roughly a city block
        case .journey: return 152.4   // ~500 ft  — ~one highway landmark gap
        }
    }

    /// Radius in meters passed to the Wikipedia Geosearch `gsradius` parameter.
    /// Larger radius for Journey mode compensates for higher vehicle speed so
    /// articles aren't missed between GPS pings.
    var searchRadius: Int {
        switch self {
        case .wander:  return 150     // ~500 ft  — tight, hyper-local results
        case .journey: return 402     // ~1/4 mile — broader sweep for fast travel
        }
    }
}
