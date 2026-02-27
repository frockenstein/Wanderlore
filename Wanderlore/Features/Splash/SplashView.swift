import SwiftUI

/// Static splash screen shown while the app boots.
///
/// Displays a large "W" in SF Mono Medium (matching the in-app wordmark) on a
/// black background. Crossfades to ContentView after a brief hold.
struct SplashView: View {

    let onFinished: () -> Void

    private let displayDuration: Double = 1.5

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text("W")
                .font(.system(size: 220, weight: .medium, design: .monospaced))
                .foregroundStyle(.white)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) {
                onFinished()
            }
        }
    }
}

#Preview {
    SplashView(onFinished: {})
}
