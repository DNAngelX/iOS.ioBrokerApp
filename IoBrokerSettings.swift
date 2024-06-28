import Foundation

struct IoBrokerSettings: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var url: String
    var port: String
    var useCredentials: Bool
    var username: String
    var password: String
    var person: String
    var device: String
    var location: String
    var isActive: Bool
    var onlineState: Bool
    var lastSensorValues: [String: String] // Store as JSON strings
    var lastUpdateTimes: [String: Date]

    init(id: UUID = UUID(), name: String, url: String, port: String, useCredentials: Bool, username: String, password: String, person: String, device: String, location: String, isActive: Bool = true, onlineState: Bool = true, lastSensorValues: [String: String] = [:], lastUpdateTimes: [String: Date] = [:]) {
        self.id = id
        self.name = name
        self.url = url
        self.port = port
        self.useCredentials = useCredentials
        self.username = username
        self.password = password
        self.person = person
        self.device = device
        self.location = location
        self.isActive = isActive
        self.onlineState = onlineState
        self.lastSensorValues = lastSensorValues
        self.lastUpdateTimes = lastUpdateTimes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case url
        case port
        case useCredentials
        case username
        case password
        case person
        case device
        case location
        case isActive
        case onlineState
        case lastSensorValues
        case lastUpdateTimes
    }
    
    // Adding conformance to Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        port = try container.decode(String.self, forKey: .port)
        useCredentials = try container.decode(Bool.self, forKey: .useCredentials)
        username = try container.decode(String.self, forKey: .username)
        password = try container.decode(String.self, forKey: .password)
        person = try container.decode(String.self, forKey: .person)
        device = try container.decode(String.self, forKey: .device)
        location = try container.decode(String.self, forKey: .location)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        onlineState = try container.decode(Bool.self, forKey: .onlineState)
        lastSensorValues = try container.decode([String: String].self, forKey: .lastSensorValues)
        lastUpdateTimes = try container.decode([String: Date].self, forKey: .lastUpdateTimes)
    }

    // Adding conformance to Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(url, forKey: .url)
        try container.encode(port, forKey: .port)
        try container.encode(useCredentials, forKey: .useCredentials)
        try container.encode(username, forKey: .username)
        try container.encode(password, forKey: .password)
        try container.encode(person, forKey: .person)
        try container.encode(device, forKey: .device)
        try container.encode(location, forKey: .location)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(onlineState, forKey: .onlineState)
        try container.encode(lastSensorValues, forKey: .lastSensorValues)
        try container.encode(lastUpdateTimes, forKey: .lastUpdateTimes)
    }

    static func == (lhs: IoBrokerSettings, rhs: IoBrokerSettings) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
