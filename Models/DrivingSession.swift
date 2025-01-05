import Foundation
import CoreLocation

struct DrivingSession: Codable, Identifiable {
    let id: UUID
    let session_id: Int
    let session_start: TimeInterval
    let session_end: TimeInterval?
    let data: [DrivingPoint]
    let tyreType: TyreType
    let driverName: String?
    let carModel: String?
    let startLocation: LocationInfo?
    let endLocation: LocationInfo?
    
    enum CodingKeys: String, CodingKey {
        case id, session_id, session_start, session_end, data, tyreType, driverName, carModel, startLocation, endLocation
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        session_id = try container.decode(Int.self, forKey: .session_id)
        session_start = try container.decode(TimeInterval.self, forKey: .session_start)
        session_end = try container.decodeIfPresent(TimeInterval.self, forKey: .session_end)
        data = try container.decode([DrivingPoint].self, forKey: .data)
        tyreType = try container.decode(TyreType.self, forKey: .tyreType)
        driverName = try container.decodeIfPresent(String.self, forKey: .driverName)
        carModel = try container.decodeIfPresent(String.self, forKey: .carModel)
        startLocation = try container.decodeIfPresent(LocationInfo.self, forKey: .startLocation)
        endLocation = try container.decodeIfPresent(LocationInfo.self, forKey: .endLocation)
    }
    
    init(id: UUID = UUID(), 
         session_id: Int, 
         session_start: TimeInterval, 
         session_end: TimeInterval? = nil, 
         data: [DrivingPoint], 
         tyreType: TyreType, 
         driverName: String? = nil,
         carModel: String? = nil,
         startLocation: LocationInfo? = nil,
         endLocation: LocationInfo? = nil) {
        self.id = id
        self.session_id = session_id
        self.session_start = session_start
        self.session_end = session_end
        self.data = data
        self.tyreType = tyreType
        self.driverName = driverName
        self.carModel = carModel
        self.startLocation = startLocation
        self.endLocation = endLocation
    }
    
    var name: String {
        let date = Date(timeIntervalSince1970: session_start)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var locationDescription: String? {
        if let start = startLocation?.district, let end = endLocation?.district {
            return "\(start) → \(end)"
        }
        return nil
    }
    
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