import Foundation

/// Static configuration and secret resolution for the app.
///
/// API keys should never be hardcoded into source control. The preferred
/// workflow for each environment is:
///
/// **Development:**
///   Copy `Secrets.xcconfig.example` to `Secrets.xcconfig` (gitignored) and
///   set `CLAUDE_API_KEY`. Xcode substitutes it into Info.plist at build time.
///
/// **CI / TestFlight:**
///   Inject via your CI provider's secret management (e.g. Xcode Cloud env vars,
///   GitHub Actions secrets) as `CLAUDE_API_KEY`.
///
/// **Production (advanced):**
///   Move key resolution server-side and have the app call your own backend,
///   which proxies requests to Anthropic. This keeps the key off the device entirely.
enum Config {

    /// The Anthropic API key used by `ClaudeService`.
    ///
    /// Resolution order:
    /// 1. `CLAUDE_API_KEY` environment variable (CI or a local scheme override).
    /// 2. Info.plist value substituted from `Secrets.xcconfig` at build time.
    /// 3. Empty string — ClaudeService will receive a 401 and surface an error.
    static let claudeAPIKey: String = {
        if let key = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"], !key.isEmpty {
            return key
        }
        if let key = Bundle.main.object(forInfoDictionaryKey: "CLAUDE_API_KEY") as? String,
           !key.isEmpty,
           !key.hasPrefix("$(") {
            return key
        }
        return ""
    }()
}
