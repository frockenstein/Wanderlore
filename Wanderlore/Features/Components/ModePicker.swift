import SwiftUI

/// A segmented-style toggle for switching between Wander and Journey modes.
///
/// Rendered as a pill/capsule rather than iOS's native UISegmentedControl so
/// we can precisely match the app's dark aesthetic. The selected segment gets a
/// white fill with black text; idle segments are transparent with secondary text.
///
/// Disabled while a tour is running (controlled by ContentView) to prevent
/// mid-session mode switches that would change the GPS threshold and search radius
/// without properly restarting the pipeline.
struct ModePicker: View {

    /// Bound to `appState.tourMode` in ContentView — changes propagate immediately.
    @Binding var selectedMode: TourMode

    var body: some View {
        HStack(spacing: 0) {
            // Iterate over all cases so adding a future mode (e.g. "Cycle")
            // appears here automatically without touching this view.
            ForEach(TourMode.allCases, id: \.self) { mode in
                Button {
                    // Short ease-in-out so the highlight slides smoothly between segments
                    withAnimation(.easeInOut(duration: 0.18)) { selectedMode = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.system(.footnote, design: .rounded).weight(.semibold))
                        .frame(maxWidth: .infinity)  // each segment fills an equal share of width
                        .padding(.vertical, 9)
                        // Active segment: white background, black text
                        // Idle segment: transparent background, secondary (gray) text
                        .background(selectedMode == mode ? Color.white : Color.clear)
                        .foregroundStyle(selectedMode == mode ? Color.black : Color.secondary)
                }
            }
        }
        // Clip the entire HStack into a capsule so the highlighted segment has
        // rounded ends without any manual corner-radius math
        .clipShape(Capsule())
        // Subtle border so the picker is visible against the dark background
        // even when no segment is highlighted (shouldn't happen, but defensive)
        .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
        .frame(width: 220) // fixed width keeps the pill from stretching on wide devices
    }
}

#Preview {
    ModePicker(selectedMode: .constant(.wander))
        .padding()
        .background(Color.black)
}
