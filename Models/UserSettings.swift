import Foundation

struct UserSettings: Codable {
    var driverName: String?
    var tyreType: TyreType
    var useMetricSystem: Bool
    
    init(
        driverName: String? = nil,
        tyreType: TyreType = .allSeason,
        useMetricSystem: Bool = true
    ) {
        self.driverName = driverName
        self.tyreType = tyreType
        self.useMetricSystem = useMetricSystem
    }
} 