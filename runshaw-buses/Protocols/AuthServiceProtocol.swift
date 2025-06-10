import Combine
protocol AuthServiceProtocol {
    /// Login with email and password
    func login(email: String, password: String) -> AnyPublisher<LoginResponse, NetworkError>

    /// Refresh authentication token
    func refreshToken(refreshToken: String) -> AnyPublisher<LoginResponse, NetworkError>

    /// Logout current user
    func logout() -> AnyPublisher<EmptyResponse, NetworkError>

    /// Check if an account is marked as deactivated
    /// Note: Will always return false as the API does not support this feature yet.
    func isAccountPendingDeletion(email: String) -> AnyPublisher<Bool, NetworkError>

    /// Reactivate a deactivated account
    func reactivateAccount(email: String) -> AnyPublisher<EmptyResponse, NetworkError>

    /// Exchange Google token for authentication
    func exchangeGoogleToken(idToken: String) -> AnyPublisher<LoginResponse, NetworkError>

    /// Exchange Apple token for authentication
    func exchangeAppleToken(idToken: String) -> AnyPublisher<LoginResponse, NetworkError>

    /// Validate current authentication token
    func validateToken() -> AnyPublisher<TokenValidationResponse, NetworkError>

    /// Get current user's profile
    func getUserProfile() -> AnyPublisher<User, NetworkError>
    
    /// Get current user's preferences
    func getUserPreferences() -> AnyPublisher<UserPreferences, NetworkError>
}
