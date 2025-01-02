import Foundation
import CoreLocation

struct DrivingPoint: Codable, Identifiable {
    let id: UUID
    let index: Int
    let timestamp: TimeInterval
    let longitude: Double
    let latitude: Double
    let speed: Double
    let distance: Double
    
    init(
        id: UUID = UUID(),
        index: Int,
        timestamp: TimeInterval,
        longitude: Double,
        latitude: Double,
        speed: Double,
        distance: Double
    ) {
        self.id = id
        self.index = index
        self.timestamp = timestamp
        self.longitude = longitude
        self.latitude = latitude
        self.speed = speed
        self.distance = distance
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
} 