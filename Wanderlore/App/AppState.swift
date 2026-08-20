import Foundation

/// Central store for user-configurable preferences that need to be shared
/// across multiple views (ContentView, SettingsView, etc.).
///
/// Marked @MainActor so all reads and writes happen on the main thread,
/// matching SwiftUI's rendering thread and preventing data races on
/// @Published properties.
@MainActor
final class AppState: ObservableObject {

    /// Which movement mode is active — controls GPS threshold and Wikipedia search radius.
    /// Defaults to Wander (pedestrian) on first launch.
    @Published var tourMode: TourMode = .wander

    /// The set of content categories the user wants to hear about.
    /// Defaults to all filters enabled. (V1 stores this but filtering logic
    /// will be wired into WikipediaService in a future iteration.)
    @Published var interestFilters: Set<InterestFilter> = Set(InterestFilter.allCases)

    /// AVSpeechSynthesisVoice identifier selected in Settings.
    /// Empty string means "use system default en-US voice."
    @Published var selectedVoiceIdentifier: String = ""

    /// When true, other audio (music, podcasts) is ducked while narration plays;
    /// when false, narration mixes on top of other audio instead.
    /// Forwarded into TTSManager.duckOthers by ContentView's .onChange modifier.
    @Published var autoPauseOnMedia: Bool = true
}
