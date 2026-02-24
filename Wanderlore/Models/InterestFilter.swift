import Foundation

/// Content categories the user can toggle in Settings.
///
/// In V1 these are stored in AppState and displayed as toggles, but the actual
/// filtering logic (e.g. matching Wikipedia categories against the active set)
/// will be wired into WikipediaService in V1.1. The groundwork is here now so
/// AppState and SettingsView don't need to change when that feature lands.
///
/// Conforms to:
/// - `CaseIterable` so Settings can enumerate all options with `ForEach`.
/// - `Identifiable` (via `id = rawValue`) so SwiftUI ForEach is stable.
/// - `Hashable` (implicit from String rawValue) so it can live in a `Set`.
enum InterestFilter: String, CaseIterable, Identifiable {
    case history        = "History"
    case architecture   = "Architecture"
    case nature         = "Nature"
    case military       = "Military"
    case notablePeople  = "Notable People"

    /// Stable identity key — uses the raw string value since it's already unique.
    var id: String { rawValue }

    /// SF Symbol name shown next to the toggle label in SettingsView.
    var icon: String {
        switch self {
        case .history:       return "clock.fill"
        case .architecture:  return "building.columns.fill"
        case .nature:        return "leaf.fill"
        case .military:      return "shield.fill"
        case .notablePeople: return "person.fill"
        }
    }
}
