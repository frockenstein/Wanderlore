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

    /// When true, TTS should duck/pause if another audio source begins playing.
    /// Implemented via AVAudioSession .duckOthers option in TTSManager.
    @Published var autoPauseOnMedia: Bool = true
}
