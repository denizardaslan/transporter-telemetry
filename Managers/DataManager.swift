import Foundation

enum DataManagerError: Error {
    case encodingError
    case decodingError
    case fileError
    case invalidDirectory
}

final class DataManager {
    static let shared = DataManager()
    
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    private init() {}
    
    func saveSession(_ session: DrivingSession) throws {
        guard let documentsDirectory = documentsDirectory else {
            throw DataManagerError.invalidDirectory
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(session)
            let fileURL = documentsDirectory.appendingPathComponent("\(session.id).json")
            try data.write(to: fileURL)
        } catch {
            throw DataManagerError.encodingError
        }
    }
    
    func loadSessions() throws -> [DrivingSession] {
        guard let documentsDirectory = documentsDirectory else {
            throw DataManagerError.invalidDirectory
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var sessions: [DrivingSession] = []
        
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory,
                                                             includingPropertiesForKeys: nil,
                                                             options: .skipsHiddenFiles)
            
            for fileURL in fileURLs where fileURL.pathExtension == "json" {
                let data = try Data(contentsOf: fileURL)
                let session = try decoder.decode(DrivingSession.self, from: data)
                sessions.append(session)
            }
        } catch {
            throw DataManagerError.decodingError
        }
        
        return sessions
    }
    
    func deleteSession(id: UUID) throws {
        guard let documentsDirectory = documentsDirectory else {
            throw DataManagerError.invalidDirectory
        }
        
        let fileURL = documentsDirectory.appendingPathComponent("\(id).json")
        try fileManager.removeItem(at: fileURL)
    }
} 