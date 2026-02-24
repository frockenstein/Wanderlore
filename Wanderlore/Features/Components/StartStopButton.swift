import SwiftUI

/// The primary action button that starts and pauses a Wanderlore tour session.
///
/// Displays one of two states driven by `isRunning`:
/// - **Start Tour** (play icon) — when no session is active.
/// - **Pause Tour** (pause icon) — when GPS and the pipeline are running.
///
/// Styled as a white pill on the dark background to give it maximum visual
/// weight as the app's single primary CTA. Uses `.buttonStyle(.plain)` to
/// prevent SwiftUI from wrapping the custom shape in a default button highlight
/// that would break the capsule appearance on press.
struct StartStopButton: View {

    /// Reflects `MainViewModel.isRunning` — drives label and icon switching.
    let isRunning: Bool

    /// Action closure passed in from ContentView, which toggles `viewModel.start/stop`.
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Icon changes between play and pause to match the current state
                Image(systemName: isRunning ? "pause.fill" : "play.fill")

                // Label text also updates — keeps the button self-explanatory
                Text(isRunning ? "Pause Tour" : "Start Tour")
                    .fontWeight(.semibold)
            }
            .font(.system(.body, design: .rounded))
            .foregroundStyle(.black)          // Black text on white pill
            .frame(width: 200, height: 52)    // Fixed size — consistent across devices
            .background(Color.white)
            .clipShape(Capsule())
        }
        // .plain suppresses the default button press highlight so our custom
        // capsule background isn't hidden behind a system-provided tint overlay
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        StartStopButton(isRunning: false) {}   // Start state
        StartStopButton(isRunning: true) {}    // Pause state
    }
    .padding()
    .background(Color.black)
}
