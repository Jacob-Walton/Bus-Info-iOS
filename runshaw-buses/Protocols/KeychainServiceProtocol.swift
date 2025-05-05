import Foundation

protocol KeychainServiceProtocol {
    // Authentication tokens
    func saveAuthToken(_ token: String) -> Bool
    func getAuthToken() -> String?
    func saveRefreshToken(_ token: String) -> Bool
    func getRefreshToken() -> String?
    
    // Token expiration
    func saveTokenExpiration(_ date: Date) -> Bool
    func getTokenExpiration() -> Date?
    
    // User management
    func saveCurrentUser(_ user: User) -> Bool
    func getCurrentUser() -> User?
    
    // Cleanup
    func clearAllTokens()
}
