import Foundation

/// Sends Wikipedia article extracts to the Anthropic Claude API and returns
/// a short, engaging spoken narration in return.
///
/// This is the "magic layer" of Wanderlore's core loop — it transforms dry
/// encyclopedia text into 2-3 vivid storyteller sentences suitable for TTS.
/// The system prompt is the main lever for tuning output style; iterate on it
/// to change pacing, tone, or detail level without touching any other code.
///
/// API reference: https://docs.anthropic.com/en/api/messages
final class ClaudeService {

    private let apiKey: String
    private let session = URLSession.shared

    /// The Messages API endpoint. All requests are POST with a JSON body.
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!

    /// The persona and output instructions given to Claude on every request.
    ///
    /// Key constraints baked in:
    /// - 2-3 sentences only → keeps TTS duration short and digestible while walking/driving.
    /// - "Never start with the location name" → avoids robotic "The Eiffel Tower was built..." openers.
    /// - "Ends with one surprising detail" → the hook that makes users want to stop and look around.
    private let systemPrompt = """
        You are Wanderlore, a witty and curious audio guide. Given the following Wikipedia text \
        about a nearby location, write a 2-3 sentence spoken summary that is conversational, vivid, \
        and ends with one surprising or counterintuitive detail. Never start with the location name. \
        Sound like a great storyteller, not an encyclopedia.
        """

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    // MARK: - Public

    /// Sends `extract` (raw Wikipedia intro text) to Claude and returns the
    /// rewritten narration string ready for AVSpeechSynthesizer.
    ///
    /// - Parameter extract: Plain-text article intro from WikipediaService.
    /// - Returns: A 2-3 sentence narration string.
    /// - Throws: `ClaudeError.badResponse` for non-200 HTTP status (e.g. 401 invalid key),
    ///           `ClaudeError.emptyContent` if Claude returns a blank response,
    ///           or URLSession/JSON errors on network failure.
    func rewrite(extract: String) async throws -> String {
        // Build the request body following the Messages API schema
        let body: [String: Any] = [
            "model": "claude-haiku-4-5",   // Haiku a bit cheaper
            "max_tokens": 256,              // ~2-3 sentences; generous but capped to control latency
            "system": systemPrompt,         // Persona and output constraints
            "messages": [
                ["role": "user", "content": extract]  // The raw Wikipedia text is the user "message"
            ]
        ]

        // Build the URLRequest with the three required Anthropic headers
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey,             forHTTPHeaderField: "x-api-key")        // Auth
        request.setValue("2023-06-01",       forHTTPHeaderField: "anthropic-version") // API version pin
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        // Surface HTTP errors (401 bad key, 429 rate limit, 500 server error, etc.)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw ClaudeError.badResponse
        }

        // Decode the response and extract the first text content block
        let decoded = try JSONDecoder().decode(MessageResponse.self, from: data)
        guard let text = decoded.content.first?.text, !text.isEmpty else {
            throw ClaudeError.emptyContent
        }
        return text
    }

    // MARK: - Error Types

    enum ClaudeError: Error {
        /// The API returned a non-200 status. Check your API key and rate limits.
        case badResponse
        /// Claude returned a response with no text content (shouldn't happen normally).
        case emptyContent
    }
}

// MARK: - Private Decodable Response Types

/// Mirrors the Messages API response shape:
/// `{ "content": [ { "type": "text", "text": "..." } ] }`
///
/// Claude can theoretically return multiple content blocks (e.g. tool use),
/// but for a simple text-only request we always get exactly one "text" block.
private struct MessageResponse: Decodable {
    let content: [ContentBlock]

    struct ContentBlock: Decodable {
        let type: String  // "text" for standard completions
        let text: String  // The narration string we pass to TTS
    }
}
