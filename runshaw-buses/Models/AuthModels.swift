struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let refreshToken: String?
    let expiresAt: String
    let expiresIn: Int?
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case token = "accessToken"
        case refreshToken
        case expiresAt
        case expiresIn
        case user
    }
    
    init(token: String, refreshToken: String? = nil, expiresAt: String, expiresIn: Int? = nil, user: User? = nil) {
        self.token = token
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.expiresIn = expiresIn
        self.user = user
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let accessToken = try? container.decode(String.self, forKey: .token) {
            token = accessToken
        } else if let rawToken = try? container.decode(String.self, forKey: CodingKeys(stringValue: "token")!) {
            token = rawToken
        } else {
            throw DecodingError.keyNotFound(CodingKeys.token, DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Neither 'accessToken' nor 'token' key found"
            ))
        }
        
        refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        expiresAt = try container.decode(String.self, forKey: .expiresAt)
        expiresIn = try container.decodeIfPresent(Int.self, forKey: .expiresIn)
        user = try container.decodeIfPresent(User.self, forKey: .user)
    }
}

struct TokenRefreshRequest: Codable {
    let refreshToken: String
}

struct ReactivateAccountRequest: Codable {
    let email: String
}

struct GoogleTokenExchangeRequest: Codable {
    let idToken: String
}

struct AppleTokenExchangeRequest: Codable {
    let idToken: String
}

struct TokenValidationResponse: Codable {
    let isValid: Bool
    let user: User?
    
    init(isValid: Bool, user: User? = nil) {
        self.isValid = isValid
        self.user = user
    }
}

struct UserPreferences: Codable {
    let pushNotificationsEnabled: Bool
    let showPreferredRoutesSeparately: Bool
    let preferredRoutes: [String]
}

enum AuthState: Equatable {
    case loading
    case signedIn(User)
    case signedOut
    case serverUnreachable

    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.signedIn(let user1), .signedIn(let user2)):
            return user1 == user2
        case (.signedOut, .signedOut):
            return true
        case (.serverUnreachable, .serverUnreachable):
            return true
        default:
            return false
        }
    }
}