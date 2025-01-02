import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var speed: Double = 0
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var isRecording = false
    @Published private(set) var currentDistance: Double = 0
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var pointIndex = 0
    private var recordingStartTime: TimeInterval?
    private var currentSession: DrivingSession?
    private var drivingPoints: [DrivingPoint] = []
    
    // MARK: - Session Properties
    private var driverName: String?
    private var tyreType: TyreType?
    private var sessionId: Int = 0
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = 1 // Update every 1 meter
    }
    
    // MARK: - Public Methods
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startRecording(driverName: String?, tyreType: TyreType) {
        guard !isRecording else { return }
        
        // Reset recording state
        self.driverName = driverName
        self.tyreType = tyreType
        self.pointIndex = 0
        self.currentDistance = 0
        self.drivingPoints.removeAll()
        self.recordingStartTime = Date().timeIntervalSince1970
        self.sessionId += 1
        
        // Start location updates
        locationManager.startUpdatingLocation()
        isRecording = true
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        locationManager.stopUpdatingLocation()
        isRecording = false
        
        // Create and save session
        let session = DrivingSession(
            id: UUID(),
            session_id: sessionId,
            session_start: recordingStartTime ?? Date().timeIntervalSince1970,
            session_end: Date().timeIntervalSince1970,
            data: drivingPoints,
            tyreType: tyreType ?? .summer,
            driverName: driverName
        )
        
        // Save session using DataManager
        Task {
            try? await Task.yield()  // Ensure we're not blocking the main thread
            try? DataManager.shared.saveSession(session)
        }
        
        // Reset state
        currentSession = nil
        drivingPoints.removeAll()
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
            speed = max(0, location.speed * 3.6) // Convert m/s to km/h
            
            if let lastLocation = lastLocation {
                currentDistance += location.distance(from: lastLocation)
            }
            
            lastLocation = location
            pointIndex += 1
            
            if isRecording {
                let point = DrivingPoint(
                    index: pointIndex,
                    timestamp: Date().timeIntervalSince1970,
                    longitude: location.coordinate.longitude,
                    latitude: location.coordinate.latitude,
                    speed: speed,
                    distance: currentDistance
                )
                drivingPoints.append(point)
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
} 