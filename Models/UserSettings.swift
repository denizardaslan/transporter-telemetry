import Foundation

// Import local models
import enum TransporterTelemetry.TyreType

struct UserSettings: Codable {
    var driverName: String?
    var tyreType: TyreType
    var useMetricSystem: Bool
    
    init(driverName: String? = nil,
         tyreType: TyreType = .allSeason,
         useMetricSystem: Bool = true) {
        self.driverName = driverName
        self.tyreType = tyreType
        self.useMetricSystem = useMetricSystem
    }
    
    // Convenience methods for unit conversion
    func formatSpeed(_ speedInMetersPerSecond: Double) -> String {
        let speed = useMetricSystem ? 
            speedInMetersPerSecond * 3.6 :  // m/s to km/h
            speedInMetersPerSecond * 2.237  // m/s to mph
        return String(format: "%.1f %@", speed, useMetricSystem ? "km/h" : "mph")
    }
    
    func formatDistance(_ distanceInMeters: Double) -> String {
        let distance = useMetricSystem ?
            distanceInMeters / 1000 :  // meters to kilometers
            distanceInMeters / 1609.34  // meters to miles
        return String(format: "%.2f %@", distance, useMetricSystem ? "km" : "mi")
    }
} 