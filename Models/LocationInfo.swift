import Foundation
import CoreLocation

struct LocationInfo: Codable {
    let street: String
    let district: String
    let city: String
    let coordinate: CLLocationCoordinate2D
    
    enum CodingKeys: String, CodingKey {
        case street, district, city
        case latitude, longitude
    }
    
    init(street: String, district: String, city: String, coordinate: CLLocationCoordinate2D) {
        self.street = street
        self.district = district
        self.city = city
        self.coordinate = coordinate
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        street = try container.decode(String.self, forKey: .street)
        district = try container.decode(String.self, forKey: .district)
        city = try container.decode(String.self, forKey: .city)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(street, forKey: .street)
        try container.encode(district, forKey: .district)
        try container.encode(city, forKey: .city)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
}
