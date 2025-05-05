import Foundation
import Security

class KeychainService: KeychainServiceProtocol {
    static let shared: KeychainServiceProtocol = KeychainService()

    private init() {}

    // MARK: - Error Handling
    
    enum KeychainError: Error {
        case itemNotFound
        case duplicateItem
        case unexpectedStatus(OSStatus)
    }

    // MARK: - Keychain Keys

    private enum KeychainKey: String {
        case authToken = "com.konpeki.runshaw-buses.authToken"
        case refreshToken = "com.konpeki.runshaw-buses.refreshToken"
        case tokenExpiration = "com.konpeki.runshaw-buses.tokenExpiration"
        case currentUser = "com.konpeki.runshaw-buses.currentUser"
    }

    // MARK: - Public Methods

    func saveAuthToken(_ token: String) -> Bool {
        let data = Data(token.utf8)
        return save(key: KeychainKey.authToken.rawValue, data: data)
    }

    func getAuthToken() -> String? {
        guard let data = getData(key: KeychainKey.authToken.rawValue) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func saveRefreshToken(_ token: String) -> Bool {
        let data = Data(token.utf8)
        return save(key: KeychainKey.refreshToken.rawValue, data: data)
    }

    func getRefreshToken() -> String? {
        guard let data = getData(key: KeychainKey.refreshToken.rawValue) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func saveTokenExpiration(_ date: Date) -> Bool {
        let data = try? NSKeyedArchiver.archivedData(withRootObject: date, requiringSecureCoding: true)
        guard let expirationData = data else {
            return false
        }
        return save(key: KeychainKey.tokenExpiration.rawValue, data: expirationData)
    }
    
    func getTokenExpiration() -> Date? {
        guard let data = getData(key: KeychainKey.tokenExpiration.rawValue) else {
            return nil
        }
        
        do {
            return try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDate.self, from: data) as Date?
        } catch {
            print("Error unarchiving token expiration: \(error)")
            return nil
        }
    }
    
    func saveCurrentUser(_ user: User) -> Bool {
        let encoder = JSONEncoder()
        guard let userData = try? encoder.encode(user) else {
            return false
        }
        return save(key: KeychainKey.currentUser.rawValue, data: userData)
    }
    
    func getCurrentUser() -> User? {
        guard let userData = getData(key: KeychainKey.currentUser.rawValue) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(User.self, from: userData)
    }
    
    func clearAllTokens() {
        _ = delete(key: KeychainKey.authToken.rawValue)
        _ = delete(key: KeychainKey.refreshToken.rawValue)
        _ = delete(key: KeychainKey.tokenExpiration.rawValue)
        _ = delete(key: KeychainKey.currentUser.rawValue)
    }

    // MARK: - Private Helper Methods

    private func save(key: String, data: Data) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getData(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            return nil
        }
        
        return dataTypeRef as? Data
    }
    
    private func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

// MARK: - Mock Implementation

#if DEBUG
class MockKeychainService: KeychainServiceProtocol {
    // In-memory storage for testing
    private var storage: [String: Any] = [:]

    // Keys
    private enum StorageKey: String {
        case authToken = "com.konpeki.runshaw-buses.authToken"
        case refreshToken = "com.konpeki.runshaw-buses.refreshToken"
        case tokenExpiration = "com.konpeki.runshaw-buses.tokenExpiration"
        case currentUser = "com.konpeki.runshaw-buses.currentUser"
    }
    
    func saveAuthToken(_ token: String) -> Bool {
        storage[StorageKey.authToken.rawValue] = token
        return true
    }
    
    func getAuthToken() -> String? {
        return storage[StorageKey.authToken.rawValue] as? String
    }
    
    func saveRefreshToken(_ token: String) -> Bool {
        storage[StorageKey.refreshToken.rawValue] = token
        return true
    }
    
    func getRefreshToken() -> String? {
        return storage[StorageKey.refreshToken.rawValue] as? String
    }
    
    func saveTokenExpiration(_ date: Date) -> Bool {
        storage[StorageKey.tokenExpiration.rawValue] = date
        return true
    }
    
    func getTokenExpiration() -> Date? {
        return storage[StorageKey.tokenExpiration.rawValue] as? Date
    }
    
    func saveCurrentUser(_ user: User) -> Bool {
        storage[StorageKey.currentUser.rawValue] = user
        return true
    }
    
    func getCurrentUser() -> User? {
        return storage[StorageKey.currentUser.rawValue] as? User
    }
    
    func clearAllTokens() {
        storage.removeValue(forKey: StorageKey.authToken.rawValue)
        storage.removeValue(forKey: StorageKey.refreshToken.rawValue)
        storage.removeValue(forKey: StorageKey.tokenExpiration.rawValue)
        storage.removeValue(forKey: StorageKey.currentUser.rawValue)
    }
    
    // Helper method to set up test state
    func setupTestUser(withToken token: String = "test-token") {
        saveAuthToken(token)
        saveRefreshToken("test-refresh-token")
        saveTokenExpiration(Date().addingTimeInterval(3600)) // 1 hour from now
        saveCurrentUser(User(id: "test-id", email: "test@example.com", name: "Test User", role: .student))
    }
}
#endif