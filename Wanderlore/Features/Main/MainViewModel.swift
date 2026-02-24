import Foundation
import CoreLocation

/// Orchestrates the entire Wanderlore core loop: GPS → Wikipedia → Claude → TTS.
///
/// This is the brain of the app. Its one job is to listen for location threshold
/// events and drive the async pipeline that transforms a GPS coordinate into
/// spoken audio. It owns no UI — it exposes @Published state and lets ContentView
/// decide how to display it.
///
/// **Core loop (happy path):**
/// 1. LocationManager fires `onMovementThreshold` with the new CLLocation.
/// 2. `handleLocationUpdate` cancels any in-flight fetch and starts a new Task.
/// 3. `fetchAndNarrate` calls Wikipedia Geosearch → gets the nearest article.
/// 4. Calls Wikipedia Extracts → gets the intro text.
/// 5. Sends the text to Claude → gets a 2-3 sentence narration.
/// 6. Passes the narration to TTSManager → user hears the story.
///
/// **Cancellation:**
/// Each new location event cancels the previous Task via `fetchTask?.cancel()`.
/// Cooperative cancellation checks (`guard !Task.isCancelled`) are placed after
/// each `await` so stale work is discarded quickly without surfacing errors to the UI.
@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - Published State (read by ContentView)

    /// Human-readable status shown in NarrationCard when no narration is playing.
    @Published var statusMessage: String = "Tap start to begin your tour"

    /// The Wikipedia article title for the current narration.
    @Published var currentTitle: String = ""

    /// The Claude-generated narration currently displayed and/or being spoken.
    @Published var currentNarration: String = ""

    /// True while the Wikipedia/Claude pipeline is in flight — shows a spinner in the UI.
    @Published var isLoading: Bool = false

    /// True while a tour session is active (GPS running). Drives button label and mode picker lock.
    @Published var isRunning: Bool = false

    // MARK: - Dependencies (public so ContentView can forward voice changes, etc.)

    let locationManager: LocationManager
    let ttsManager: TTSManager

    // MARK: - Private State

    private let wikipedia = WikipediaService()
    private let claude: ClaudeService

    /// The active TourMode — stored locally so `handleLocationUpdate` can pass the
    /// correct searchRadius without needing a reference to AppState.
    private var currentMode: TourMode = .wander

    /// Handle to the current async pipeline task.
    /// Stored so it can be cancelled when a newer location event arrives or the tour stops.
    private var fetchTask: Task<Void, Never>?

    // MARK: - Init

    init(locationManager: LocationManager, ttsManager: TTSManager) {
        self.locationManager = locationManager
        self.ttsManager = ttsManager
        self.claude = ClaudeService(apiKey: Config.claudeAPIKey)

        // Wire up the location threshold callback. Weak self prevents a retain cycle
        // between LocationManager (which holds this closure) and MainViewModel (which
        // owns LocationManager).
        locationManager.onMovementThreshold = { [weak self] location in
            self?.handleLocationUpdate(location)
        }
    }

    // MARK: - Public Interface

    /// Starts the tour in the given mode: syncs thresholds, requests GPS permission,
    /// and begins streaming location updates.
    func start(mode: TourMode) {
        currentMode = mode
        // Push the mode's threshold down into LocationManager before starting GPS
        locationManager.movementThreshold = mode.movementThreshold
        locationManager.requestPermission()
        locationManager.startUpdating()
        isRunning = true
        statusMessage = mode == .wander ? "Wandering…" : "On the road…"
    }

    /// Stops GPS, cancels any in-flight fetch, and halts TTS.
    func stop() {
        locationManager.stopUpdating()
        ttsManager.stop()
        fetchTask?.cancel()
        isRunning = false
        statusMessage = "Tour paused"
    }

    // MARK: - Private Pipeline

    /// Called by LocationManager's threshold callback.
    /// Cancels the previous fetch (if still running) and kicks off a new one.
    /// This ensures the pipeline always reflects the most recent position.
    private func handleLocationUpdate(_ location: CLLocation) {
        fetchTask?.cancel()
        fetchTask = Task { await fetchAndNarrate(coordinate: location.coordinate) }
    }

    /// The async pipeline: Geosearch → Extract → Claude rewrite → TTS.
    ///
    /// Cooperative cancellation is checked after every `await` so if a new location
    /// event arrives mid-flight, the stale work exits cleanly without touching UI state.
    private func fetchAndNarrate(coordinate: CLLocationCoordinate2D) async {
        isLoading = true
        statusMessage = "Finding nearby lore…"

        do {
            // Step 1: Find nearby Wikipedia articles within the mode's search radius
            let results = try await wikipedia.fetchNearbyArticles(
                coordinate: coordinate,
                radius: currentMode.searchRadius
            )

            guard let top = results.first else {
                // No articles in range — happens in very remote areas
                statusMessage = "Nothing nearby — keep exploring"
                isLoading = false
                return
            }
            guard !Task.isCancelled else { return }

            // Step 2: Fetch the intro extract for the nearest article
            statusMessage = "Reading about \(top.title)…"
            let extract = try await wikipedia.fetchExtract(pageId: top.pageid)
            guard !Task.isCancelled else { return }

            // Step 3: Send the raw Wikipedia text to Claude for storytelling rewrite
            let narration = try await claude.rewrite(extract: extract.extract)
            guard !Task.isCancelled else { return }

            // Step 4: Publish results to UI and speak the narration
            currentTitle = top.title
            currentNarration = narration
            statusMessage = top.title  // show article name as the card header
            isLoading = false
            ttsManager.speak(narration)

        } catch {
            // Catches network errors, Wikipedia 404s, Claude 4xx/5xx responses, etc.
            // Cancelled tasks are silently ignored — they're not errors from the user's perspective.
            guard !Task.isCancelled else { return }
            statusMessage = "Couldn't load lore — keep moving"
            isLoading = false
        }
    }
}
