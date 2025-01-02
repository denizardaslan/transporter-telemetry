# Product Requirements Document: The Transporter Telemetry App

## 1. Introduction

### 1.1 Purpose
The Transporter Telemetry App is a SwiftUI-based iOS application for collecting and analyzing driving data, providing users with comprehensive insights into their driving patterns.

### 1.2 Goals & Success Metrics
- Primary Goals:
  - Accurate capture of driving metrics with <1% error margin
  - User engagement: >80% of users recording at least 3 sessions/week
  - Data reliability: Zero data loss during background operation
  - Performance: <100ms latency for real-time updates
  - Battery efficiency: <5% battery usage per hour of recording

### 1.3 Target Audience & Use Cases
- Individual drivers tracking habits
- Fleet managers monitoring vehicle usage
- Driving instructors analyzing student performance
- Insurance companies requiring driving logs

## 2. System Architecture

### 2.1 High-Level Components
- Core Location Manager: Handles GPS data collection
- Data Processing Engine: Processes raw location data
- Storage Manager: Handles JSON persistence
- UI Layer: SwiftUI views and view models
- Background Task Manager: Ensures continued recording

### 2.2 Data Flow
1. Location Manager captures raw GPS data
2. Processing Engine calculates derived metrics
3. Storage Manager persists data to JSON
4. UI Layer updates in real-time
5. Background Manager maintains data collection

### 2.3 Technical Stack
- SwiftUI for UI
- Core Location for GPS
- Combine for reactive updates
- FileManager for storage
- BackgroundTasks framework

## 3. Detailed Requirements

### 3.1 Core Functionalities

#### 3.1.1 Recording System
- Initialize recording with location permissions
- Track metrics:
  - Speed (km/h, mph)
  - Location (lat/long)
  - Distance
  - Timestamps
  - Vehicle/driver info
- Maintain background recording
- Prevent device sleep during recording
- Generate unique session IDs

#### 3.1.2 Data Management
- JSON file generation per session
- File listing with metadata
- Share functionality via iOS share sheet
- Swipe-to-delete with confirmation
- Automatic file size optimization

#### 3.1.3 Settings Management
- Driver profile:
  - Name
  - Vehicle details
- Tire type selection:
  - Summer ☀️
  - Winter ❄️
  - All Season 🌧️
- Unit preferences (km/h vs mph)
- Data retention policies

#### 3.1.4 Real-time Display
- Current speed with color indicators
  - Green: Accelerating
  - Red: Decelerating
- Live distance calculation
- Session duration timer
- 60-second speed graph
- Auto-switch to recording view


#### 3.1.5 Analytics Dashboard
- Session statistics:
  - Total trips counter
  - Maximum speed tracker
  - Cumulative distance
  - Total driving time
- Performance metrics
- Data visualization components


### 3.2 Performance Requirements
- Location sampling rate: 1Hz
- Maximum file size: 10MB per hour of recording
- Memory usage: <100MB
- CPU usage: <10% during active recording
- Battery optimization: Location updates reduced when speed <5 km/h

### 3.3 Security & Privacy
- Data encryption at rest
- Privacy policy compliance
- Location data anonymization options
- Secure file sharing implementation

### 3.4 Error Handling
- GPS signal loss recovery
- Storage space management
- Background task termination recovery
- Network connectivity issues
- Data corruption prevention

### 3.5 Testing Requirements
- Unit tests: >80% coverage
- UI tests for critical paths
- Performance testing under various conditions
- Background mode testing
- Battery impact testing

## 4. Implementation Guidelines

### 4.1 Code Organization
```swift
// LocationManager.swift
final class LocationManager: NSObject, ObservableObject {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var speed: Double = 0
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
}

// DataManager.swift
struct DataManager {
    static func saveSession(_ session: DrivingSession) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(session)
        try data.write(to: fileURL(for: session.id))
    }
}
```

### 4.2 UI Components
- Use SwiftUI's environment objects for state management
- Implement custom ViewModifiers for consistent styling
- Create reusable components for graphs and statistics

### 4.3 Background Processing
- Implement proper background task handling
- Use background location updates
- Handle app suspension and revival

## 5. Future Roadmap
[Previous content retained]

## 6. Appendices
- JSON Schema Documentation
{
  "driverName" : "Deniz Arda",
  "data" : [
    {
      "speed" : 2.530869245529175,
      "longitude" : 32.591083759483034,
      "distance" : 0,
      "latitude" : 39.940133229772215,
      "index" : 0,
      "timestamp" : 1734778946.0429358
    },
    {
      "distance" : 1.9887795584561194,
      "longitude" : 32.591098035859574,
      "speed" : 1.459486961364746,
      "timestamp" : 1734778947.0430741,
      "index" : 1,
      "latitude" : 39.94011908860987
    },
    {
      "distance" : 4.138597570045237,
      "index" : 2,
      "longitude" : 32.59110443425079,
      "timestamp" : 1734778948.042934,
      "latitude" : 39.94010036630303,
      "speed" : 1.459486961364746
    }
  ],
  "session_end" : 1734779039.91832,
  "id" : "A3216297-4A0C-42BF-90E3-5704BDCE0FDE",
  "tyreType" : "Winter",
  "session_start" : 1734778945.0388808,
  "session_id" : 9
}

Types:
id = UUID()
session_id: Int
session_start: TimeInterval
session_end: TimeInterval?
data: [DrivingPoint]
tyreType: TyreType
driverName: String?
 index: Int
timestamp: TimeInterval
longitude: Double
latitude: Double
speed: Double
distance: Double