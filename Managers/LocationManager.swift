import Foundation
import CoreLocation
import Combine

final class LocationManager: NSObject, ObservableObject {
    // Published properties
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var speed: Double = 0
    @Published private(set) var isRecording = false
    @Published private(set) var currentSession: DrivingSession?
    
    // Private properties
    private let locationManager = CLLocationManager()
    private var points: [DrivingPoint] = []
    private var sessionStartTime: TimeInterval = 0
    private var lastDistance: Double = 0
    private var sessionId: Int = 0
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = 1 // Update every 1 meter
    }
    
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startRecording(driverName: String?, tyreType: TyreType) {
        guard !isRecording else { return }
        
        points.removeAll()
        sessionStartTime = Date().timeIntervalSince1970
        lastDistance = 0
        sessionId += 1
        
        currentSession = DrivingSession(
            id: UUID(),
            session_id: sessionId,
            session_start: sessionStartTime,
            session_end: nil,
            data: [],
            tyreType: tyreType,
            driverName: driverName
        )
        
        locationManager.startUpdatingLocation()
        isRecording = true
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        locationManager.stopUpdatingLocation()
        isRecording = false
        
        if var session = currentSession {
            session.session_end = Date().timeIntervalSince1970
            session.data = points
            currentSession = session
            
            // Save session
            do {
                try DataManager.shared.saveSession(session)
            } catch {
                print("Error saving session: \(error)")
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, isRecording else { return }
        
        currentLocation = location
        speed = location.speed >= 0 ? location.speed : 0
        
        // Calculate distance from last point
        if let lastPoint = points.last {
            let lastLocation = CLLocation(latitude: lastPoint.latitude, longitude: lastPoint.longitude)
            lastDistance += location.distance(from: lastLocation)
        }
        
        // Create new driving point
        let point = DrivingPoint(
            index: points.count,
            timestamp: location.timestamp.timeIntervalSince1970,
            longitude: location.coordinate.longitude,
            latitude: location.coordinate.latitude,
            speed: speed,
            distance: lastDistance
        )
        
        points.append(point)
        
        // Update current session
        if var session = currentSession {
            session.data = points
            currentSession = session
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            print("Location access granted")
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            print("Location access not determined")
        @unknown default:
            break
        }
    }
} 