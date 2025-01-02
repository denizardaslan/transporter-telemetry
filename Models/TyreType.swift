import Foundation

enum TyreType: String, Codable, CaseIterable {
    case summer = "Summer"
    case winter = "Winter"
    case allSeason = "All Season"
    
    var emoji: String {
        switch self {
        case .summer: return "☀️"
        case .winter: return "❄️"
        case .allSeason: return "🌧️"
        }
    }
} 