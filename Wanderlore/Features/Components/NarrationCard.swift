import SwiftUI

/// The primary content card that surfaces the current tour state to the user.
///
/// Shows one of three states depending on the pipeline's progress:
///
/// 1. **Loading** — a centered spinner while Geosearch/Extract/Claude are running.
/// 2. **Empty** — a status message (e.g. "Wandering…", "Nothing nearby") when
///    no narration has been generated yet or the area has no Wikipedia coverage.
/// 3. **Narration** — the article title as a small caps label above the
///    Claude-generated narration text. This is the primary "reading state."
///
/// The card uses `.ultraThinMaterial` so it visually floats above the black
/// background with a frosted-glass effect rather than a flat opaque fill.
struct NarrationCard: View {

    /// Wikipedia article title for the current narration. Shown in small caps above the text.
    let title: String

    /// Claude's 2-3 sentence narration. Empty string signals "no narration yet."
    let text: String

    /// Human-readable status shown when `text` is empty and not loading
    /// (e.g. "Tap start to begin", "Wandering…", "Nothing nearby — keep exploring").
    let statusMessage: String

    /// True while the Wikipedia/Claude pipeline is in flight.
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            if isLoading {
                // Centered spinner — appears during the async pipeline
                HStack {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                }
                .padding(.vertical, 32)

            } else if text.isEmpty {
                // No narration available — show status text centered in the card
                Text(statusMessage)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)

            } else {
                // Active narration state: label + body text

                // Article title in monospaced uppercase with letter-spacing —
                // acts as a discreet source label rather than a headline
                Text(title)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .tracking(1.5)
                    .textCase(.uppercase)

                // Claude's narration — rounded font for warmth, generous line spacing
                // for readability in outdoor lighting conditions
                Text(text)
                    .font(.system(.body, design: .rounded))
                    .lineSpacing(5)
                    .foregroundStyle(.primary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
        // ultraThinMaterial = frosted glass over black — works in both light and dark mode
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NarrationCard(
        title: "Golden Gate Bridge",
        text: "Painted with 10,000 gallons a year, it's technically never finished — the moment crews paint the last rivet, they start over at the beginning.",
        statusMessage: "",
        isLoading: false
    )
    .padding()
    .background(Color.black)
}
