import CoreLocation
import Combine

/// Wraps `CLLocationManager` and implements Wanderlore's movement-threshold logic.
///
/// **Why a custom threshold instead of CLLocationManager's distanceFilter?**
/// `CLLocationManager.distanceFilter` suppresses delegate callbacks until the device
/// moves a set distance, but it resets relative to *every* location update, not just
/// the last one we *acted on*. Our dead-zone requirement is: "don't re-fetch until
/// the user has moved X meters from the location we last fetched for." That's a
/// semantic distinction CLLocationManager can't express natively, so we implement
/// it ourselves in `evaluateThreshold(for:)`.
///
/// Marked @MainActor because CLLocationManagerDelegate callbacks are bridged onto
/// the main thread via `Task { @MainActor in ... }` and all @Published properties
/// must be mutated on the main actor to keep SwiftUI happy.
@MainActor
final class LocationManager: NSObject, ObservableObject {

    /// The most recent raw GPS fix. Updated on every CLLocationManager callback
    /// (subject to the 10 m distanceFilter set on the underlying manager).
    @Published var currentLocation: CLLocation?

    /// Reflects the current Core Location authorization state.
    /// Views can observe this to show permission prompts or disabled-state UI.
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

    /// Closure fired when the user has moved at least `movementThreshold` meters
    /// from the last location that triggered a fetch. Set by MainViewModel on init.
    var onMovementThreshold: ((CLLocation) -> Void)?

    /// Distance in meters the user must travel before `onMovementThreshold` fires again.
    /// Kept in sync with the active `TourMode` — MainViewModel updates this on `start(mode:)`.
    var movementThreshold: Double = TourMode.wander.movementThreshold

    /// The underlying Core Location manager. distanceFilter is set to 10 m as a
    /// cheap first-pass filter so the OS doesn't wake us for micro-jitter.
    private let manager = CLLocationManager()

    /// Snapshot of the location we last passed to `onMovementThreshold`.
    /// Used as the reference point for subsequent distance comparisons.
    private var lastProcessedLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest  // GPS-quality fixes
        manager.distanceFilter = 10  // OS-level pre-filter; our threshold logic sits on top
    }

    // MARK: - Public Interface

    /// Requests "when in use" authorization. iOS will show the system permission dialog
    /// on the first call; subsequent calls are no-ops if already authorized.
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    /// Begins streaming location updates to the delegate.
    ///
    /// Background updates are enabled here (and disabled in `stopUpdating`) so GPS
    /// keeps flowing while the phone is locked — required for the `location` entry
    /// in UIBackgroundModes to actually take effect. With when-in-use authorization
    /// this shows the system's blue location indicator while backgrounded.
    func startUpdating() {
        manager.allowsBackgroundLocationUpdates = true
        manager.pausesLocationUpdatesAutomatically = false
        manager.showsBackgroundLocationIndicator = true
        manager.startUpdatingLocation()
    }

    /// Stops streaming. Called when the user pauses the tour.
    func stopUpdating() {
        manager.allowsBackgroundLocationUpdates = false
        manager.stopUpdatingLocation()
    }

    // MARK: - Private

    /// Compares `location` against `lastProcessedLocation` and fires `onMovementThreshold`
    /// if the user has moved far enough. On the very first fix there's no reference point,
    /// so we fire immediately and store the fix as the new baseline.
    private func evaluateThreshold(for location: CLLocation) {
        guard let last = lastProcessedLocation else {
            // First fix ever — establish baseline and trigger an immediate fetch.
            lastProcessedLocation = location
            onMovementThreshold?(location)
            return
        }
        // CLLocation.distance(from:) returns meters between two coordinates.
        if location.distance(from: last) >= movementThreshold {
            lastProcessedLocation = location
            onMovementThreshold?(location)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    /// Receives a batch of location fixes from Core Location.
    /// `locations.last` is the most recent and highest-accuracy fix in the batch.
    /// Marked `nonisolated` because CLLocationManagerDelegate methods are called on
    /// an internal CL thread; we hop to @MainActor explicitly via Task.
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
            self.evaluateThreshold(for: location)
        }
    }

    /// Fires whenever the user grants, revokes, or changes location permission.
    /// We reflect the new status so the UI can react (e.g. show a "enable location" prompt).
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }

    /// Non-fatal errors (e.g. signal loss in a tunnel) — logged, not surfaced to the user.
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[LocationManager] \(error.localizedDescription)")
    }
}
