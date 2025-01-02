import Foundation

struct DrivingSession: Codable, Identifiable {
    let id: UUID
    let session_id: Int
    let session_start: TimeInterval
    let session_end: TimeInterval?
    let data: [DrivingPoint]
    let tyreType: TyreType
    let driverName: String?
    
    var duration: TimeInterval {
        (session_end ?? Date().timeIntervalSince1970) - session_start
    }
    
    var maxSpeed: Double {
        data.map(\.speed).max() ?? 0
    }
    
    var totalDistance: Double {
        data.last?.distance ?? 0
    }
} 