import CoreLocation
import Combine
import UIKit

@MainActor
final class LocationManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isRecording = false
    @Published var speed: Double = 0
    @Published var currentDistance: Double = 0
    @Published var isWaitingForLocation = false
    @Published private(set) var currentLocation: CLLocation?
    
    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var lastLocation: CLLocation?
    private var pointIndex = 0
    private var recordingStartTime: TimeInterval?
    private var currentSession: DrivingSession?
    private var drivingPoints: [DrivingPoint] = []
    private var startLocation: LocationInfo?
    private var endLocation: LocationInfo?
    private let geocoder = CLGeocoder()
    
    // MARK: - Session Properties
    private var driverName: String?
    private var tyreType: TyreType?
    private var sessionId = 0
    
    // MARK: - Initialization
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.startUpdatingLocation()
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
        
        // Prevent screen from timing out during recording
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Reset recording state
        self.driverName = driverName
        self.tyreType = tyreType
        self.pointIndex = 0
        self.currentDistance = 0
        self.drivingPoints.removeAll()
        self.recordingStartTime = Date().timeIntervalSince1970
        self.sessionId += 1
        self.startLocation = nil
        self.endLocation = nil
        
        // Start by getting current location
        if let location = currentLocation {
            isWaitingForLocation = true
            
            // Capture start time for minimum delay
            let startTime = Date()
            
            getLocationInfo(for: location) { [weak self] locationInfo in
                guard let self = self else { return }
                self.startLocation = locationInfo
                print("Start location captured: \(locationInfo?.district ?? "Unknown")")
                
                // Calculate remaining time to meet minimum 1 second delay
                let elapsedTime = Date().timeIntervalSince(startTime)
                let remainingDelay = max(0, 1.0 - elapsedTime)
                
                // Wait for remaining time then start recording
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingDelay) {
                    self.isWaitingForLocation = false
                    self.locationManager.startUpdatingLocation()
                    self.isRecording = true
                }
            }
        } else {
            // If no location available, start updates and wait for first location
            isWaitingForLocation = true
            locationManager.startUpdatingLocation()
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        locationManager.stopUpdatingLocation()
        isRecording = false
        
        // Re-enable screen timeout when recording stops
        UIApplication.shared.isIdleTimerDisabled = false
        
        // Store final data
        let finalData = drivingPoints
        let finalSessionId = sessionId
        let finalStartTime = recordingStartTime
        let finalTyreType = tyreType
        let finalDriverName = driverName
        let finalStartLocation = startLocation
        
        // Get end location
        if let location = currentLocation {
            getLocationInfo(for: location) { [weak self] locationInfo in
                print("End location captured: \(locationInfo?.district ?? "Unknown")")
                print("Start location was: \(finalStartLocation?.district ?? "Unknown")")
                
                // Create and save session after getting end location
                let session = DrivingSession(
                    id: UUID(),
                    session_id: finalSessionId,
                    session_start: finalStartTime ?? Date().timeIntervalSince1970,
                    session_end: Date().timeIntervalSince1970,
                    data: finalData,
                    tyreType: finalTyreType ?? .summer,
                    driverName: finalDriverName,
                    startLocation: finalStartLocation,
                    endLocation: locationInfo
                )
                
                // Save session using DataManager
                Task {
                    do {
                        try await Task.yield()
                        try DataManager.shared.saveSession(session)
                        print("Successfully saved session: \(session.id)")
                        print("Session data points: \(finalData.count)")
                        print("Max speed: \(session.maxSpeed)")
                        print("Total distance: \(session.totalDistance)")
                    } catch {
                        print("Failed to save session: \(error)")
                    }
                }
            }
        }
        
        // Reset state
        currentSession = nil
        drivingPoints.removeAll()
        startLocation = nil
        endLocation = nil
    }
    
    private func getLocationInfo(for location: CLLocation, completion: @escaping (LocationInfo?) -> Void) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first else {
                print("Geocoding error: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            let locationInfo = LocationInfo(
                street: placemark.thoroughfare ?? "Unknown Street",
                district: placemark.subLocality ?? placemark.locality ?? "Unknown District",
                city: placemark.administrativeArea ?? "Unknown City",
                coordinate: location.coordinate
            )
            completion(locationInfo)
        }
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
        currentLocation = location
        
        if isWaitingForLocation && !isRecording {
            // If we're waiting for initial location, get it and start recording
            isWaitingForLocation = false
            
            // Capture start time for minimum delay
            let startTime = Date()
            
            getLocationInfo(for: location) { [weak self] locationInfo in
                guard let self = self else { return }
                self.startLocation = locationInfo
                print("Start location captured: \(locationInfo?.district ?? "Unknown")")
                
                // Calculate remaining time to meet minimum 1 second delay
                let elapsedTime = Date().timeIntervalSince(startTime)
                let remainingDelay = max(0, 1.0 - elapsedTime)
                
                // Wait for remaining time then start recording
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingDelay) {
                    self.locationManager.startUpdatingLocation()
                    self.isRecording = true
                }
            }
            return
        }
        
        guard isRecording else { return }
        
        speed = max(0, location.speed * 3.6) // Convert m/s to km/h
        
        // Update distance if we have a previous location
        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)
            currentDistance += distance
        }
        
        // Create and add driving point
        let point = DrivingPoint(
            index: pointIndex,
            timestamp: location.timestamp.timeIntervalSince1970,
            longitude: location.coordinate.longitude,
            latitude: location.coordinate.latitude,
            speed: speed,
            distance: currentDistance
        )
        
        drivingPoints.append(point)
        pointIndex += 1
        lastLocation = location
        
        print("Added point - Speed: \(speed) km/h, Distance: \(currentDistance) m")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}