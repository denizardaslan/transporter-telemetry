import Foundation

struct UserSettings: Codable {
    var driverName: String?
    var tyreType: TyreType
    var useMetricSystem: Bool
    var carModel: String?
    
    init(
        driverName: String? = nil,
        tyreType: TyreType = .allSeason,
        useMetricSystem: Bool = true,
        carModel: String? = nil
    ) {
        self.driverName = driverName
        self.tyreType = tyreType
        self.useMetricSystem = useMetricSystem
        self.carModel = carModel
    }
} 