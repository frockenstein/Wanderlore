import Foundation
import CoreLocation

// MARK: - Domain Model

/// A fully-resolved article ready for display and narration.
///
/// This is the app's internal representation, assembled after both Wikipedia
/// API calls (geosearch + extract) complete. It is intentionally separate from
/// the raw API response types below so the rest of the codebase doesn't
/// depend on Wikipedia's JSON shape.
struct LocationArticle: Identifiable {
    let id: Int                        // Wikipedia pageid — globally unique
    let title: String                  // Article title, e.g. "Golden Gate Bridge"
    let extract: String                // Intro paragraph(s) from the Extracts API
    let coordinate: CLLocationCoordinate2D  // Geographic position of the article subject
    let distanceMeters: Double         // Distance from user at time of search (meters)
}

// MARK: - Wikipedia API Response Types

/// Raw result item from the Wikipedia Geosearch API (`list=geosearch`).
///
/// The geosearch endpoint returns an array of nearby articles sorted by
/// distance. We only use the `pageid` to drive the follow-up Extracts call
/// and `dist` for potential future UI display.
struct WikipediaSearchResult: Decodable {
    let pageid: Int     // Unique Wikipedia page ID — used as the key for the Extracts call
    let title: String   // Article title
    let lat: Double     // Latitude of the article's subject
    let lon: Double     // Longitude of the article's subject
    let dist: Double    // Distance in meters from the search coordinate (API field name is "dist")
}

/// Raw result from the Wikipedia Extracts API (`prop=extracts`).
///
/// The `exintro=true` parameter limits the response to only the intro section,
/// and `explaintext=true` strips HTML tags so the text is safe to pass directly
/// to Claude and AVSpeechSynthesizer without sanitization.
struct WikipediaExtract: Decodable {
    let pageid: Int     // Matches the pageid used to request this extract
    let title: String   // Article title (echoed back by the API)
    let extract: String // Plain-text intro section — the raw material fed to Claude
}
