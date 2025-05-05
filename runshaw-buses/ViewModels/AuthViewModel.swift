import Foundation
import SwiftUI
import Combine

class AuthViewModel: ObservableObject {
    // Main auth state
    @Published var authState: AuthState = .loading
    
    // Direct access to user data with user data refresh mechanism
    private var _currentUser: User?
    private var lastUserDataRefresh: Date?
    private let userDataTTL: TimeInterval = 300 // 5 minutes in seconds
    
    // Auth status properties
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isRefreshingUserData: Bool = false
    
    // Computed property that triggers refresh if necessary
    var currentUser: User? {
        get {
            checkAndRefreshUserDataIfNeeded()
            return _currentUser
        }
    }
    
    // Computed properties for easy access to user details with auto-refresh
    var isSignedIn: Bool { currentUser != nil }
    var userEmail: String { currentUser?.email ?? "" }
    var userName: String { currentUser?.name ?? "" }
    var isAdmin: Bool { currentUser?.role == .admin }
    
    private let authService: AuthServiceProtocol
    private let keychainService: KeychainServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private var tokenRefreshTimer: Timer?
    private let tokenRefreshBuffer: TimeInterval = 60 * 5 // 5 minutes before expiration
    
    init(authService: AuthServiceProtocol, keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.authService = authService
        self.keychainService = keychainService
        
        // Check for existing authentication
        checkAuthStatus()
    }
    
    deinit {
        tokenRefreshTimer?.invalidate()
    }
    
    private func checkAuthStatus() {
        // Check keychain for stored credentials
        if let user = keychainService.getCurrentUser(),
           let expiration = keychainService.getTokenExpiration(),
           Date() < expiration {
            // Valid token exists - validate with server if network available
            validateToken(fallbackUser: user, fallbackExpiration: expiration)
        } else if let refreshToken = keychainService.getRefreshToken() {
            // Token expired but we have a refresh token
            refreshAuthToken(refreshToken: refreshToken)
        } else {
            // No valid auth, need to sign in
            DispatchQueue.main.async {
                self.updateAuthState(.signedOut)
            }
        }
    }
    
    // Check if user data needs to be refreshed and trigger refresh if needed
    private func checkAndRefreshUserDataIfNeeded() {
        guard isSignedInPrivate else { return }
        
        let now = Date()
        
        // Check if we need to refresh data (it's been more than 5 minutes since last refresh)
        if lastUserDataRefresh == nil ||
           now.timeIntervalSince(lastUserDataRefresh!) > userDataTTL {
            refreshUserData()
        }
    }
    
    // Private accessor that doesn't trigger refresh to avoid infinite loops
    private var isSignedInPrivate: Bool {
        if case .signedIn(_) = authState {
            return true
        }
        return false
    }
    
    // Method to refresh user data from the server
    private func refreshUserData() {
        guard !isRefreshingUserData, isSignedInPrivate,
              let _ = keychainService.getAuthToken() else { return }
        
        isRefreshingUserData = true
        
        // Create a user profile endpoint request
        authService.getUserProfile()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (completion: Subscribers.Completion<NetworkError>) in
                guard let self = self else { return }
                self.isRefreshingUserData = false
                
                if case .failure(let error) = completion {
                    print("Failed to refresh user data: \(error.localizedDescription)")
                    // We don't show an error to the user for background refreshes
                    // but we log it for debugging
                }
            } receiveValue: { [weak self] (user: User) in
                guard let self = self else { return }
                
                // Update the user data and refresh timestamp
                self._currentUser = user
                self.lastUserDataRefresh = Date()
                
                // Save the updated user in keychain
                _ = self.keychainService.saveCurrentUser(user)
                
                self.isRefreshingUserData = false
                
                // Notify observers that user data has been updated
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    // Force refresh user data - can be called manually when needed
    func forceRefreshUserData() {
        // Reset the last refresh time to force a refresh
        lastUserDataRefresh = nil
        // Access the currentUser property to trigger the refresh
        _ = currentUser
    }
    
    // Update both authState and currentUser in one place
    private func updateAuthState(_ newState: AuthState) {
        self.authState = newState
        
        // Extract user from state if signed in
        if case .signedIn(let user) = newState {
            self._currentUser = user
            self.lastUserDataRefresh = Date() // Reset the refresh timer
        } else {
            self._currentUser = nil
            self.lastUserDataRefresh = nil
        }
    }
    
    // New method to validate existing token
    private func validateToken(fallbackUser: User, fallbackExpiration: Date) {
        authService.validateToken()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(_) = completion {
                    // Network error or server unreachable - use cached credentials for now
                    print("Failed to validate token with server. Using cached credentials.")
                    self.updateAuthState(.signedIn(fallbackUser))
                    self.scheduleTokenRefresh(expirationDate: fallbackExpiration)
                }
            } receiveValue: { response in
                if response.isValid {
                    // Token is valid
                    self.updateAuthState(.signedIn(fallbackUser))
                    self.scheduleTokenRefresh(expirationDate: fallbackExpiration)
                } else {
                    // Token is invalid - try to refresh or sign out
                    if let refreshToken = self.keychainService.getRefreshToken() {
                        self.refreshAuthToken(refreshToken: refreshToken)
                    } else {
                        self.keychainService.clearAllTokens()
                        self.updateAuthState(.signedOut)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter both email and password"
            self.showError = true
            return
        }
        
        self.isAuthenticating = true
        self.errorMessage = nil
        self.showError = false
        
        authService.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isAuthenticating = false
                
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            } receiveValue: { response in
                // Store auth data securely
                _ = self.keychainService.saveAuthToken(response.token)
                _ = self.keychainService.saveRefreshToken(response.refreshToken)
                
                // Parse date from string for token expiration
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = dateFormatter.date(from: response.expiresAt) {
                    _ = self.keychainService.saveTokenExpiration(date)
                    self.scheduleTokenRefresh(expirationDate: date)
                } else {
                    print("Failed to parse date: \(response.expiresAt)")
                    // Fallback to a reasonable expiration
                    let fallbackDate = Date().addingTimeInterval(3600) // 1 hour from now
                    _ = self.keychainService.saveTokenExpiration(fallbackDate)
                    self.scheduleTokenRefresh(expirationDate: fallbackDate)
                }
                
                _ = self.keychainService.saveCurrentUser(response.user)
                
                // Update app state
                self.updateAuthState(.signedIn(response.user))
            }
            .store(in: &cancellables)
    }
    
    func signOut() {
        isAuthenticating = true
        
        authService.logout()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isAuthenticating = false
                
                // Clear tokens even if the request fails
                self.tokenRefreshTimer?.invalidate()
                self.keychainService.clearAllTokens()
                self.updateAuthState(.signedOut)
            } receiveValue: { _ in
                // Already handled in completion
            }
            .store(in: &cancellables)
    }
    
    func isAccountPendingDeletion(email: String) -> Bool {
        // In real implementation, this would check with the backend
        // For demo purposes, maintain the current behavior
        return email.lowercased() == "deleted@example.com"
    }
    
    func reactivateAccount(email: String) {
        self.isAuthenticating = true
        
        authService.reactivateAccount(email: email)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isAuthenticating = false
                
                if case .failure(let error) = completion {
                    self.errorMessage = "Failed to reactivate account: \(error.localizedDescription)"
                    self.showError = true
                }
            } receiveValue: { _ in
                // Show success message
                self.errorMessage = "Account reactivated successfully. Please sign in."
                self.showError = true
            }
            .store(in: &cancellables)
    }
    
    // Function to handle Google ID token exchange
    func exchangeGoogleToken(idToken: String) {
        self.isAuthenticating = true
        self.errorMessage = nil
        self.showError = false

        authService.exchangeGoogleToken(idToken: idToken)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isAuthenticating = false
                
                switch completion {
                case .finished:
                    // Successful login, state already set in receiveValue
                    break
                case .failure(let error):
                    // Handle specific errors
                    if case .decodingError(let underlyingError) = error {
                        self.errorMessage = "Failed to process server response: \(underlyingError.localizedDescription)"
                    } else if case .httpStatusCode(let code) = error, code == 400 {
                        self.errorMessage = "Invalid Google sign-in. Please try again or use another method."
                    } else {
                        self.errorMessage = "Failed to sign in with Google: \(error.localizedDescription)"
                    }
                    self.showError = true
                    self.updateAuthState(.signedOut)
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }

                // Store auth data securely
                guard self.keychainService.saveAuthToken(response.token) else {
                    self.handleKeychainError(message: "Failed to save authentication token.")
                    return
                }

                guard self.keychainService.saveRefreshToken(response.refreshToken) else {
                    self.handleKeychainError(message: "Failed to save refresh token.")
                    return
                }

                // Parse expiration date
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                guard let expirationDate = dateFormatter.date(from: response.expiresAt) else {
                    self.errorMessage = "Failed to parse token expiration date from server."
                    self.showError = true
                    self.updateAuthState(.signedOut)
                    self.keychainService.clearAllTokens()
                    return
                }
                
                guard self.keychainService.saveTokenExpiration(expirationDate) else {
                    self.handleKeychainError(message: "Failed to save token expiration.")
                    return
                }

                guard self.keychainService.saveCurrentUser(response.user) else {
                    self.handleKeychainError(message: "Failed to save user information.")
                    return
                }

                // Update auth state
                self.updateAuthState(.signedIn(response.user))
                self.scheduleTokenRefresh(expirationDate: expirationDate)
            })
            .store(in: &cancellables)
    }

    // Function to handle Apple ID token exchange
    func exchangeAppleToken(idToken: String) {
        print("AuthViewModel: Exchanging Apple token")
        self.isAuthenticating = true
        self.errorMessage = nil
        self.showError = false
        
        authService.exchangeAppleToken(idToken: idToken)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                self.isAuthenticating = false
                
                if case .failure(let error) = completion {
                    print("AuthViewModel: Apple token exchange failed: \(error)")
                    if case .httpStatusCode(let code) = error, code == 400 {
                        self.showError(message: "Your Apple ID is linked to a different account type. Please use another sign-in method.")
                    } else {
                        self.showError(message: "Failed to authenticate with Apple: \(error.localizedDescription)")
                    }
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                print("AuthViewModel: Apple token exchange successful")
                
                // Store tokens and user
                guard self.keychainService.saveAuthToken(response.token) else {
                    self.handleKeychainError(message: "Failed to save authentication token.")
                    return
                }
                
                guard self.keychainService.saveRefreshToken(response.refreshToken) else {
                    self.handleKeychainError(message: "Failed to save refresh token.")
                    return
                }
                
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                guard let expirationDate = dateFormatter.date(from: response.expiresAt) else {
                    self.errorMessage = "Failed to parse token expiration date from server."
                    self.showError = true
                    self.updateAuthState(.signedOut)
                    self.keychainService.clearAllTokens()
                    return
                }
                
                guard self.keychainService.saveTokenExpiration(expirationDate) else {
                    self.handleKeychainError(message: "Failed to save token expiration.")
                    return
                }
                
                guard self.keychainService.saveCurrentUser(response.user) else {
                    self.handleKeychainError(message: "Failed to save user information.")
                    return
                }
                
                // Update auth state
                self.updateAuthState(.signedIn(response.user))
                self.scheduleTokenRefresh(expirationDate: expirationDate)
            })
            .store(in: &cancellables)
    }
    
    // Helper function for keychain errors
    private func handleKeychainError(message: String) {
        self.errorMessage = message
        self.showError = true
        self.updateAuthState(.signedOut)
        // Clear any potentially saved tokens to avoid inconsistent state
        self.keychainService.clearAllTokens()
    }
    
    // Updated to use the new token refresh endpoint
    private func refreshAuthToken(refreshToken: String) {
        self.authService.refreshToken(refreshToken: refreshToken)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(_) = completion {
                    // If token refresh fails, clear credentials and return to sign in
                    self.keychainService.clearAllTokens()
                    self.updateAuthState(.signedOut)
                }
            } receiveValue: { response in
                // Update stored tokens
                _ = self.keychainService.saveAuthToken(response.token)
                _ = self.keychainService.saveRefreshToken(response.refreshToken)
                
                // Parse date from string for token expiration
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = dateFormatter.date(from: response.expiresAt) {
                    _ = self.keychainService.saveTokenExpiration(date)
                    self.scheduleTokenRefresh(expirationDate: date)
                } else {
                    print("Failed to parse date: \(response.expiresAt)")
                    // Fallback to a reasonable expiration
                    let fallbackDate = Date().addingTimeInterval(3600) // 1 hour from now
                    _ = self.keychainService.saveTokenExpiration(fallbackDate)
                    self.scheduleTokenRefresh(expirationDate: fallbackDate)
                }
                
                _ = self.keychainService.saveCurrentUser(response.user)
                
                // Update app state
                self.updateAuthState(.signedIn(response.user))
            }
            .store(in: &cancellables)
    }
    
    private func scheduleTokenRefresh(expirationDate: Date) {
        tokenRefreshTimer?.invalidate() // Cancel existing timer

        let refreshTime = expirationDate.addingTimeInterval(-tokenRefreshBuffer)
        let now = Date()

        guard refreshTime > now else {
            // Token already expired or too close to expiry, attempt refresh immediately
            if let refreshToken = keychainService.getRefreshToken() {
                refreshAuthToken(refreshToken: refreshToken)
            }
            return
        }

        let timeInterval = refreshTime.timeIntervalSince(now)

        tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: timeInterval,
                                                 repeats: false) { [weak self] _ in
            guard let self = self, let refreshToken = self.keychainService.getRefreshToken() else { return }
            self.refreshAuthToken(refreshToken: refreshToken)
        }
    }
    
    // Helper to show errors easily
    func showError(message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
}

// AuthState enum definition
enum AuthState: Equatable {
    case loading
    case signedIn(User)
    case signedOut
    
    // Custom Equatable implementation for associated values
    static func == (lhs: AuthState, rhs: AuthState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.signedOut, .signedOut):
            return true
        case (.signedIn(let lhsUser), .signedIn(let rhsUser)):
            return lhsUser.id == rhsUser.id
        default:
            return false
        }
    }
}

// MARK: - Factory Method

extension AuthViewModel {
    static func create() -> AuthViewModel {
        return AuthViewModel(
            authService: AuthService.create(),
            keychainService: KeychainService.shared
        )
    }
}
