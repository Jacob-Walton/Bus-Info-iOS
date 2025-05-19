struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let refreshToken: String
    let expiresAt: String
    let user: User
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