import Foundation
import CoreLocation

/// Thin, stateless wrapper around two Wikipedia MediaWiki API endpoints:
///
/// 1. **Geosearch** (`list=geosearch`) — given a lat/lon and radius, returns
///    the nearest Wikipedia articles sorted by distance.
/// 2. **Extracts** (`prop=extracts`) — given a pageid, returns the intro
///    section of that article as clean plain text.
///
/// Both APIs are free, require no authentication, and have generous rate limits
/// for non-commercial use. See: https://www.mediawiki.org/wiki/API:Main_page
final class WikipediaService {

    private let session = URLSession.shared
    private let base = "https://en.wikipedia.org/w/api.php"

    // MARK: - Public Methods

    /// Fetches Wikipedia articles whose geographic coordinates fall within
    /// `radius` meters of `coordinate`, returning up to `limit` results
    /// sorted nearest-first.
    ///
    /// - Parameters:
    ///   - coordinate: The user's current GPS position.
    ///   - radius: Search radius in meters (max 10,000 per Wikipedia API).
    ///   - limit: Maximum number of results (default 5; we typically only use the top 1).
    /// - Returns: Array of `WikipediaSearchResult`, nearest first.
    /// - Throws: URLSession/networking errors, or JSON decoding errors.
    func fetchNearbyArticles(
        coordinate: CLLocationCoordinate2D,
        radius: Int,
        limit: Int = 5
    ) async throws -> [WikipediaSearchResult] {
        var components = URLComponents(string: base)!
        components.queryItems = [
            URLQueryItem(name: "action",   value: "query"),
            URLQueryItem(name: "list",     value: "geosearch"),
            // gscoord format: "lat|lon" — the pipe character is URL-encoded automatically
            URLQueryItem(name: "gscoord",  value: "\(coordinate.latitude)|\(coordinate.longitude)"),
            URLQueryItem(name: "gsradius", value: "\(radius)"),
            URLQueryItem(name: "gslimit",  value: "\(limit)"),
            URLQueryItem(name: "format",   value: "json"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        // Decode the outer wrapper and extract just the geosearch array
        let response = try JSONDecoder().decode(GeosearchResponse.self, from: data)
        return response.query.geosearch
    }

    /// Fetches the intro-section extract for a specific Wikipedia article by pageid.
    ///
    /// - `exintro=true` limits the response to the lead section only, keeping
    ///   token count low when the extract is passed to Claude.
    /// - `explaintext=true` strips all HTML/wikitext markup so the result is
    ///   clean prose that reads naturally when spoken by AVSpeechSynthesizer.
    ///
    /// - Parameter pageId: The Wikipedia page ID from a `WikipediaSearchResult`.
    /// - Returns: A `WikipediaExtract` containing the plain-text intro.
    /// - Throws: `WikipediaError.pageNotFound` if the API returns no matching page,
    ///           or URLSession/decoding errors on network failure.
    func fetchExtract(pageId: Int) async throws -> WikipediaExtract {
        var components = URLComponents(string: base)!
        components.queryItems = [
            URLQueryItem(name: "action",      value: "query"),
            URLQueryItem(name: "prop",        value: "extracts"),
            URLQueryItem(name: "exintro",     value: "true"),     // intro section only
            URLQueryItem(name: "explaintext", value: "true"),     // strip HTML → plain text
            URLQueryItem(name: "pageids",     value: "\(pageId)"),
            URLQueryItem(name: "format",      value: "json"),
        ]
        let (data, _) = try await session.data(from: components.url!)
        let response = try JSONDecoder().decode(ExtractsResponse.self, from: data)
        // The Extracts API returns a dictionary keyed by string pageid
        guard let page = response.query.pages[String(pageId)] else {
            throw WikipediaError.pageNotFound
        }
        return page
    }

    // MARK: - Error Types

    enum WikipediaError: Error {
        /// The Extracts API didn't include the requested pageid in its response.
        /// Can happen if the article was deleted or moved between the geosearch
        /// and the extract call (rare but possible).
        case pageNotFound
    }
}

// MARK: - Private Decodable Helpers

/// Mirrors the JSON shape of the Geosearch response:
/// `{ "query": { "geosearch": [ ... ] } }`
private struct GeosearchResponse: Decodable {
    let query: GeosearchQuery
    struct GeosearchQuery: Decodable {
        let geosearch: [WikipediaSearchResult]
    }
}

/// Mirrors the JSON shape of the Extracts response:
/// `{ "query": { "pages": { "<pageid>": { ... } } } }`
///
/// Note: Wikipedia always uses string keys for the pages dictionary even though
/// pageids are integers — hence `[String: WikipediaExtract]`.
private struct ExtractsResponse: Decodable {
    let query: ExtractsQuery
    struct ExtractsQuery: Decodable {
        let pages: [String: WikipediaExtract]
    }
}
