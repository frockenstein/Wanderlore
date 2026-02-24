import SwiftUI

/// Entry point for the Wanderlore app.
///
/// All long-lived service objects are instantiated here as `@StateObject`s so they
/// survive for the full app lifetime and are never accidentally re-created when the
/// view tree re-renders. They're passed down the hierarchy via direct injection
/// (into ContentView) and SwiftUI's environment (appState) rather than singletons,
/// keeping every layer independently testable.
@main
struct WanderloreApp: App {

    /// Shared, observable user preferences: tour mode, interest filters, voice choice.
    /// Pushed into the SwiftUI environment so any nested view can read it via @EnvironmentObject.
    @StateObject private var appState = AppState()

    /// Wraps CLLocationManager — owns the GPS subscription and movement-threshold logic.
    @StateObject private var locationManager = LocationManager()

    /// Wraps AVSpeechSynthesizer — owns the TTS audio session and speaking state.
    @StateObject private var ttsManager = TTSManager()

    var body: some Scene {
        WindowGroup {
            // Pass services directly into ContentView, which forwards them into
            // MainViewModel. appState goes into the environment so nested sheets
            // (e.g. SettingsView) can access it without threading it through props.
            ContentView(
                locationManager: locationManager,
                ttsManager: ttsManager
            )
            .environmentObject(appState)
        }
    }
}
