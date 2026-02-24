import Foundation

/// Static configuration and secret resolution for the app.
///
/// API keys should never be hardcoded into source control. The preferred
/// workflow for each environment is:
///
/// **Development:**
///   Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
///   Add `CLAUDE_API_KEY` = `sk-ant-...`
///
/// **CI / TestFlight:**
///   Inject via your CI provider's secret management (e.g. Xcode Cloud env vars,
///   GitHub Actions secrets) and read the same `CLAUDE_API_KEY` env var.
///
/// **Production (advanced):**
///   Move key resolution server-side and have the app call your own backend,
///   which proxies requests to Anthropic. This keeps the key off the device entirely.
enum Config {

    /// The Anthropic API key used by `ClaudeService`.
    ///
    /// Resolution order:
    /// 1. `CLAUDE_API_KEY` environment variable (set in your Xcode scheme).
    /// 2. Empty string fallback — ClaudeService will receive a 401 and surface
    ///    an error message in the UI, prompting you to set the key.
    static let claudeAPIKey: String = {
        if let key = ProcessInfo.processInfo.environment["CLAUDE_API_KEY"], !key.isEmpty {
            return key
        }
        // ⚠️ Paste a dev key here temporarily if needed, but never commit it.
        // Consider adding a Secrets.xcconfig (gitignored) and reading from Bundle
        // for a cleaner local workflow.
        return ""
    }()
}
