enum UserRole: String, Codable, Equatable {
    case student
    case admin
}

struct User: Identifiable, Codable, Equatable {
    var id: String
    var email: String
    var name: String
    var role: UserRole

    enum CodingKeys: String, CodingKey {
        case id, email, name, isAdmin
    }

    init(id: String, email: String, name: String = "Unknown User", role: UserRole = .student) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown User"

        // Convert isAdmin boolean to UserRole enum
        let isAdmin = try container.decodeIfPresent(Bool.self, forKey: .isAdmin) ?? false
        role = isAdmin ? .admin : .student
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)

        // Convert role back to isAdmin boolean
        let isAdmin = (role == .admin)
        try container.encode(isAdmin, forKey: .isAdmin)
    }
}