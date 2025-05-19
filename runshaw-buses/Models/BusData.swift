import Foundation

// MARK: - Bus Info Response

struct BusInfoResponse: Codable {
    let busData: [String: BusData]
    let lastUpdated: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case busData, lastUpdated, status
    }
    
    // Standard initializer
    init(busData: [String: BusData], lastUpdated: String?, status: String) {
        self.busData = busData
        self.lastUpdated = lastUpdated
        self.status = status
    }
    
    // Decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        busData = try container.decode([String: BusData].self, forKey: .busData)
        lastUpdated = try container.decodeIfPresent(String.self, forKey: .lastUpdated)
        status = try container.decode(String.self, forKey: .status)
        
        #if DEBUG
        print("Successfully decoded \(busData.count) bus entries")
        #endif
    }
}

// MARK: - Bus Data

struct BusData: Codable {
    let status: String?
    let bay: String?
    let id: Int?
    
    enum CodingKeys: String, CodingKey {
        case status, bay, id
    }
    
    // Standard initializer
    init(status: String?, bay: String?, id: Int?) {
        self.status = status
        self.bay = bay
        self.id = id
    }
    
    // Decoder initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode status (required field)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        
        // Optional fields
        bay = try container.decodeIfPresent(String.self, forKey: .bay)
        id = try container.decodeIfPresent(Int.self, forKey: .id)
    }
}