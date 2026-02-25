import SwiftUI
import MapKit

/// Full-screen map showing every point of interest narrated during the session.
///
/// Presented as a sheet from ContentView when the user taps the map icon in the header.
/// Each visited location appears as a white dot annotation; tapping one surfaces a
/// detail card at the bottom with the article title and Claude's narration.
///
/// The map auto-fits all annotations on appear via `.automatic` camera position.
/// If no locations have been visited yet an empty state is shown instead.
struct HistoryMapView: View {

    /// The ordered list of visited locations passed in from MainViewModel.
    let locations: [VisitedLocation]

    @Environment(\.dismiss) private var dismiss

    /// The currently tapped annotation. Drives detail card visibility.
    /// Tapping the same dot again, or the card's dismiss button, clears it.
    @State private var selectedLocation: VisitedLocation?

    /// Camera position binding — starts at .automatic to fit all annotations,
    /// then hands control to the user for free pan/zoom.
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if locations.isEmpty {
                    emptyState
                } else {
                    mapContent

                    // Detail card slides up from the bottom when a dot is tapped.
                    // Wrapped in an if-let so the transition fires on appearance/disappearance.
                    if let selected = selectedLocation {
                        VisitDetailCard(location: selected) {
                            withAnimation(.spring(duration: 0.3)) { selectedLocation = nil }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(1) // float above map controls
                    }
                }
            }
            .ignoresSafeArea(edges: .bottom)
            .navigationTitle("Places Visited")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Subviews

    /// The map itself with one annotation dot per visited location.
    private var mapContent: some View {
        Map(position: $position) {
            // Show the user's live position as the standard blue pulsing dot
            UserAnnotation()

            ForEach(locations) { loc in
                Annotation(loc.title, coordinate: loc.coordinate, anchor: .center) {
                    VisitAnnotationView(isSelected: selectedLocation?.id == loc.id) {
                        withAnimation(.spring(duration: 0.3)) {
                            // Tapping the active dot deselects it; tapping a new dot selects it
                            selectedLocation = selectedLocation?.id == loc.id ? nil : loc
                        }
                    }
                }
            }
        }
        .mapStyle(.standard)
        // Tap anywhere on the map (not a dot) to dismiss the detail card
        .onTapGesture {
            if selectedLocation != nil {
                withAnimation(.spring(duration: 0.3)) { selectedLocation = nil }
            }
        }
    }

    /// Shown when the user opens the map before visiting any locations.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "map")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("No places visited yet")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.secondary)
            Text("Start a tour — dots will appear here as you explore.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}

// MARK: - Annotation Dot

/// The white dot that appears on the map for each visited location.
///
/// Two-layer design: a small solid core for precise positioning,
/// surrounded by a larger translucent ring that grows when selected
/// to give clear tap feedback without a distracting highlight.
struct VisitAnnotationView: View {
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer selection halo — only visible when this dot is active
                Circle()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 30, height: 30)
                    .opacity(isSelected ? 1 : 0)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)

                // Subtle ring — always visible so dots are legible on light map tiles
                Circle()
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                    .frame(width: 20, height: 20)

                // Solid core dot
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Detail Card

/// Bottom card that appears when the user taps a location dot.
///
/// Mirrors the NarrationCard aesthetic (ultraThinMaterial + rounded corners)
/// to keep the map UI visually consistent with the main tour screen.
struct VisitDetailCard: View {
    let location: VisitedLocation
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 6) {
                    // Article title in the same monospaced small-caps treatment as NarrationCard
                    Text(location.title)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .tracking(1.5)
                        .textCase(.uppercase)

                    // Claude's narration — limited to 4 lines to keep the card compact
                    Text(location.narration)
                        .font(.system(.subheadline, design: .rounded))
                        .lineSpacing(4)
                        .foregroundStyle(.primary)
                        .lineLimit(4)
                }

                Spacer(minLength: 8)

                // Dismiss button — small circular X in the top-right corner
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(7)
                        .background(Color.white.opacity(0.1), in: Circle())
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    HistoryMapView(locations: [
        VisitedLocation(
            coordinate: .init(latitude: 37.8199, longitude: -122.4783),
            title: "Golden Gate Bridge",
            narration: "Painted with 10,000 gallons a year, it's technically never finished — the moment crews paint the last rivet, they start over at the beginning."
        ),
        VisitedLocation(
            coordinate: .init(latitude: 37.8270, longitude: -122.4230),
            title: "Alcatraz Island",
            narration: "It held some of America's most dangerous criminals, yet its most famous escape attempt ended with the convicts simply vanishing — never found dead or alive."
        )
    ])
}
