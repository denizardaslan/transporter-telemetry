import Foundation

struct DrivingSession: Codable, Identifiable {
    let id: UUID
    let session_id: Int
    let session_start: TimeInterval
    let session_end: TimeInterval?
    let data: [DrivingPoint]
    let tyreType: TyreType
    let driverName: String?
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case id, session_id, session_start, session_end, data, tyreType, driverName, name
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
        // If name doesn't exist in the saved data, create a default one
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Session \(session_id)"
    }
    
    init(id: UUID = UUID(), session_id: Int, session_start: TimeInterval, session_end: TimeInterval? = nil, 
         data: [DrivingPoint], tyreType: TyreType, driverName: String? = nil) {
        self.id = id
        self.session_id = session_id
        self.session_start = session_start
        self.session_end = session_end
        self.data = data
        self.tyreType = tyreType
        self.driverName = driverName
        self.name = "Session \(session_id)"
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