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