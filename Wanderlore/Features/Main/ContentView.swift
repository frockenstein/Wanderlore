import SwiftUI

/// The root view of Wanderlore. Composes the three main UI sections — header,
/// narration card, and controls — against a full-bleed dark background.
///
/// **Architecture note:** ContentView receives `locationManager` and `ttsManager`
/// from WanderloreApp and uses them to initialize `MainViewModel` via `@StateObject`.
/// This pattern keeps the services alive for the app's full lifetime (owned by App)
/// while still giving the ViewModel its dependencies at init time. If the services
/// were created inside ContentView's init, they'd be re-created on every view refresh.
struct ContentView: View {

    /// User preferences (mode, filters, voice) shared across ContentView and SettingsView.
    @EnvironmentObject var appState: AppState

    /// The core loop controller — owns the GPS → Wikipedia → Claude → TTS pipeline.
    @StateObject private var viewModel: MainViewModel

    /// Controls visibility of the Settings sheet.
    @State private var showSettings = false

    init(locationManager: LocationManager, ttsManager: TTSManager) {
        // Wrapping in StateObject here (not in the property declaration) lets us
        // pass arguments to the ViewModel initializer — a common SwiftUI pattern.
        _viewModel = StateObject(
            wrappedValue: MainViewModel(locationManager: locationManager, ttsManager: ttsManager)
        )
    }

    var body: some View {
        ZStack {
            // Full-bleed black canvas — the app's signature dark aesthetic
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {

                // MARK: Header
                HStack {
                    // App wordmark in monospaced caps for a minimal, techy feel
                    Text("WANDERLORE")
                        .font(.system(.caption, design: .monospaced).weight(.medium))
                        .foregroundStyle(.secondary)
                        .tracking(2)
                    Spacer()
                    // Settings gear — opens the modal sheet
                    Button { showSettings.toggle() } label: {
                        Image(systemName: "slider.horizontal.3")
                            .imageScale(.medium)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer()

                // MARK: Mode Picker
                // Locked (disabled) while a tour is running to prevent threshold/radius
                // changes mid-session that would confuse the active pipeline.
                ModePicker(selectedMode: $appState.tourMode)
                    .disabled(viewModel.isRunning)
                    .padding(.bottom, 32)

                // MARK: Narration Card
                // Three-state display: loading spinner / status message / narration text.
                NarrationCard(
                    title: viewModel.currentTitle,
                    text: viewModel.currentNarration,
                    statusMessage: viewModel.statusMessage,
                    isLoading: viewModel.isLoading
                )
                .padding(.horizontal)

                Spacer()

                // MARK: Start / Stop Button
                StartStopButton(isRunning: viewModel.isRunning) {
                    if viewModel.isRunning {
                        viewModel.stop()
                    } else {
                        // Pass the current mode at the moment the user taps Start
                        // so the ViewModel can configure the correct thresholds.
                        viewModel.start(mode: appState.tourMode)
                    }
                }
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
        // Forward voice selection changes from Settings into TTSManager.
        // Done here (rather than in ViewModel) because AppState is only accessible
        // in the view layer via @EnvironmentObject.
        .onChange(of: appState.selectedVoiceIdentifier) { _, newId in
            viewModel.ttsManager.voiceIdentifier = newId
        }
        .sheet(isPresented: $showSettings) {
            SettingsView().environmentObject(appState)
        }
    }
}
