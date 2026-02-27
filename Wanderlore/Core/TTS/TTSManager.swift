import AVFoundation

/// Manages spoken narration via AVSpeechSynthesizer, Wanderlore's on-device TTS engine.
///
/// **Why AVSpeechSynthesizer over a cloud TTS service?**
/// - Free — no API calls, no quota.
/// - Works offline — critical for tunnels, rural hikes, international travel.
/// - Low latency — starts speaking in under 100 ms, while Claude is the slow step.
/// - Ships built-in on every iPhone running iOS 17+.
///
/// The tradeoff is voice quality; if a richer voice is needed in the future, swap
/// the `speak(_:)` implementation for an AVAudioPlayer reading audio data from a
/// cloud TTS API while keeping this class's public interface identical.
///
/// Marked @MainActor because AVSpeechSynthesizer must be driven from the main thread
/// and @Published properties need to be mutated there for SwiftUI observation.
@MainActor
final class TTSManager: NSObject, ObservableObject {

    /// True while the synthesizer is actively speaking. Observe this in the UI to
    /// show a visual indicator or disable the "Start Tour" button during narration.
    @Published var isSpeaking: Bool = false

    /// AVSpeechSynthesisVoice identifier string selected by the user in Settings.
    /// If empty, the system falls back to the default en-US voice.
    /// Synced from AppState.selectedVoiceIdentifier via ContentView's .onChange modifier.
    var voiceIdentifier: String = ""

    /// The underlying speech synthesizer. One instance is reused for the session
    /// to avoid the ~100 ms init overhead on every narration.
    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self  // so we can flip isSpeaking off when speech ends
    }

    // MARK: - Public Interface

    /// Stops any current narration and begins speaking `text`.
    ///
    /// Audio session is configured as `.spokenAudio` with `.duckOthers` so
    /// music/podcasts lower their volume while Wanderlore narrates, then
    /// resume automatically when the utterance finishes.
    func speak(_ text: String) {
        stop()  // cancel any in-progress narration before queuing a new one

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.52          // Slightly below default (0.5) for natural pacing
        utterance.pitchMultiplier = 1.0 // Neutral pitch; adjustable for character
        utterance.volume = 1.0          // Full volume — session ducking handles the mix

        // Use the user-selected voice if one is set; otherwise pick the highest-quality
        // voice available for the device's current language.
        // Quality tiers: .premium (Siri voice, if downloaded) → .enhanced → default.
        if !voiceIdentifier.isEmpty, let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) {
            utterance.voice = voice
        } else {
            utterance.voice = TTSManager.bestAvailableVoice()
        }

        // Configure audio session for spoken-word playback.
        // .duckOthers lowers competing audio (music, podcasts) while we speak.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? AVAudioSession.sharedInstance().setActive(true)

        synthesizer.speak(utterance)
        isSpeaking = true
    }

    /// Immediately halts speech. Called before queuing a new utterance or when the tour is paused.
    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }

    /// Pauses at the next word boundary — preserves position so `resume()` can continue.
    func pause() {
        synthesizer.pauseSpeaking(at: .word)
    }

    /// Resumes from the paused word position.
    func resume() {
        synthesizer.continueSpeaking()
    }

    // MARK: - Voice Selection

    /// Returns the highest-quality voice available for the device's current language.
    ///
    /// iOS ships the same voice files used by Siri under AVSpeechSynthesisVoice, exposed
    /// at `.premium` quality once the user has downloaded them (Settings → Accessibility →
    /// Spoken Content → Voices). If premium isn't downloaded, `.enhanced` is next best.
    /// Falls back to the system default if neither tier exists for the current language.
    static func bestAvailableVoice() -> AVSpeechSynthesisVoice? {
        let language = Locale.current.language.languageCode?.identifier ?? "en"
        let candidates = AVSpeechSynthesisVoice.speechVoices()
            .filter { $0.language.hasPrefix(language) }

        return candidates.first { $0.quality == .premium }
            ?? candidates.first { $0.quality == .enhanced }
            ?? AVSpeechSynthesisVoice(language: Locale.current.identifier)
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSManager: AVSpeechSynthesizerDelegate {

    /// Called when an utterance finishes naturally (not when stopped manually).
    /// Bridge to @MainActor because delegate callbacks arrive on an internal audio thread.
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }

    /// Called when speech is cancelled via `stop()`. Also flips the speaking flag off
    /// so the UI stays in sync even after a manual stop.
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
