import SwiftUI
import AVFoundation

/// Modal settings panel, presented as a sheet from ContentView.
///
/// All settings are persisted in `AppState` (an ObservableObject), so changes
/// take effect immediately across the app without a save/cancel workflow.
/// This is intentional for a tour app — the user expects toggles to feel instant.
struct SettingsView: View {

    /// Shared preferences object — changes here are reflected live in ContentView.
    @EnvironmentObject var appState: AppState

    /// Used to dismiss the sheet when the user taps "Done".
    @Environment(\.dismiss) private var dismiss

    /// All English-language voices available on this device, sorted alphabetically by name.
    /// Computed once at view init — voice list doesn't change during a session.
    /// Filtering to "en" prefixes avoids showing 100+ non-English voices in the picker.
    private let availableVoices = AVSpeechSynthesisVoice.speechVoices()
        .filter { $0.language.hasPrefix("en") }
        .sorted { $0.name < $1.name }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Interest Filters
                // Each toggle adds/removes the filter from AppState.interestFilters (a Set).
                // The custom Binding does the set mutation in its setter so the ForEach
                // loop body stays clean. V1.1 will wire these into WikipediaService to
                // actually filter results by Wikipedia category.
                Section("Interest Filters") {
                    ForEach(InterestFilter.allCases) { filter in
                        Toggle(isOn: Binding(
                            get: { appState.interestFilters.contains(filter) },
                            set: { enabled in
                                if enabled {
                                    appState.interestFilters.insert(filter)
                                } else {
                                    appState.interestFilters.remove(filter)
                                }
                            }
                        )) {
                            // SF Symbol + label — defined on InterestFilter for consistency
                            Label(filter.rawValue, systemImage: filter.icon)
                        }
                    }
                }

                // MARK: Narrator Voice
                // Inline picker shows all installed English voices. The empty-string tag
                // represents "System Default" — TTSManager handles the empty case by
                // falling back to AVSpeechSynthesisVoice(language: "en-US").
                Section("Narrator Voice") {
                    Picker("Voice", selection: $appState.selectedVoiceIdentifier) {
                        Text("System Default").tag("")
                        ForEach(availableVoices, id: \.identifier) { voice in
                            Text(voice.name).tag(voice.identifier)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                // MARK: Playback
                // autoPauseOnMedia is read by TTSManager's audio session setup
                // (.duckOthers) — changing it here takes effect on the next narration.
                Section("Playback") {
                    Toggle("Auto-pause when media plays", isOn: $appState.autoPauseOnMedia)
                }

                // MARK: About
                // Quick at-a-glance info; version will be read from Bundle in a future iteration.
                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Mode", value: appState.tourMode.rawValue)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
