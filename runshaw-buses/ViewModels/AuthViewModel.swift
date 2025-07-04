import Combine
import Foundation
import SwiftUI

/// Main authentication view model handling user authentication state and operations
class AuthViewModel: ObservableObject {
    /// Main auth state
    @Published var authState: AuthState = .loading

    private var _currentUser: User?
    private var lastUserDataRefresh: Date?
    private let userDataTTL: TimeInterval = 5 * 60  // 5 minutes

    /// Auth status properties
    @Published var isAuthenticating: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var isRefreshingUserData: Bool = false

    var currentUser: User? {
        checkAndRefreshUserData()
        return _currentUser
    }

    var isSignedIn: Bool { currentUser != nil }
    var userEmail: String { currentUser?.email ?? "" }
    var userName: String { currentUser?.name ?? "" }
    var isAdmin: Bool { currentUser?.role == .admin }

    private let authService: AuthServiceProtocol
    private let keychainService: KeychainServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    private var tokenRefreshTimer: Timer?
    private let tokenRefreshBuffer: TimeInterval = 60 * 5  // 5 minutes

    init(
        authService: AuthServiceProtocol,
        keychainService: KeychainServiceProtocol = KeychainService.shared
    ) {
        self.authService = authService
        self.keychainService = keychainService

        // Check for existing authentication state
        checkAuthStatus()
    }

    deinit {
        tokenRefreshTimer?.invalidate()
    }

    /// Check authentication status
    /// - If a valid token is found, validate it with the server.
    /// - If the token is expired, try to refresh it using the refresh token.
    /// - If no valid token or refresh token is found, set the auth state to signed out.
    /// - If the token is valid, update the auth state to signed in.
    /// - If the token is invalid, try to refresh it or sign out.
    private func checkAuthStatus() {
        // Check keychain for stored credentials
        if let user = keychainService.getCurrentUser(),
            let expiration = keychainService.getTokenExpiration(),
            Date() < expiration
        {
            // Valid token found, validate with server if network is available
            validateToken(fallbackUser: user, fallbackExpiration: expiration)
        } else if let refreshToken = keychainService.getRefreshToken() {
            // Token expired, try to refresh
            refreshAuthToken(refreshToken: refreshToken)
        } else {
            // No valid token or refresh token, set to logged out
            DispatchQueue.main.async {
                self.updateAuthState(.signedOut)
            }
        }
    }

    /// Check if user data needs to be refreshed
    /// - If the user is signed in and the last refresh time is nil or older than the TTL, refresh user data.
    /// - This method is called whenever the current user is accessed.
    private func checkAndRefreshUserData() {
        guard isSignedInPrivate else { return }

        let now = Date()

        // Check if we need to refresh user data
        if lastUserDataRefresh == nil || now.timeIntervalSince(lastUserDataRefresh!) > userDataTTL {
            refreshUserData()
        }
    }

    /// Private accessor to prevent infinite loop
    private var isSignedInPrivate: Bool {
        if case .signedIn(_) = authState {
            return true
        }

        return false
    }

    /// Refresh user data from the server
    private func refreshUserData() {
        guard !isRefreshingUserData, isSignedInPrivate, keychainService.getAuthToken() != nil else {
            return
        }

        isRefreshingUserData = true

        // Create a user profile endpoint request
        authService.getUserProfile()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (completion: Subscribers.Completion<NetworkError>) in
                guard let self = self else { return }
                self.isRefreshingUserData = false

                #if DEBUG
                    if case .failure(let error) = completion {
                        print("Failed to refresh user data: \(error.localizedDescription)")
                        // Don't need to show an error to user for background refresh
                    }
                #endif
            } receiveValue: { [weak self] (user: User) in
                guard let self = self else { return }

                // Update the user data and refresh time
                self._currentUser = user
                self.lastUserDataRefresh = Date()

                // Save the user data to keychain
                _ = self.keychainService.saveCurrentUser(user)

                self.isRefreshingUserData = false

                // Notify observers
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    /// Force refresh user data - can be called from UI
    func forceRefreshUserData() {
        guard isSignedInPrivate else { return }

        // Invalidate the current user data
        _currentUser = nil
        lastUserDataRefresh = nil

        // Refresh user data
        refreshUserData()
    }

    /// Update both authState and currentUser
    private func updateAuthState(_ newState: AuthState) {
        self.authState = newState

        // Extract user from state if signed in
        if case .signedIn(let user) = newState {
            self._currentUser = user
            self.lastUserDataRefresh = Date()  // Reset the last refresh time
        } else {
            // Reset user data if signed out
            self._currentUser = nil
            self.lastUserDataRefresh = nil
        }
    }

    /// Validate token with server
    ///
    /// - Parameters:
    ///   - fallbackUser: The user to use if token validation fails
    ///   - fallbackExpiration: The expiration date to use if token validation fails
    private func validateToken(fallbackUser: User, fallbackExpiration: Date) {
        authService.validateToken()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    // Check specifically for connectivity errors
                    if case .connectivityError = error {
                        // Network connectivity issue - don't log out, show connectivity error
                        #if DEBUG
                            print("Network connectivity issue detected. Showing server unreachable state.")
                        #endif
                        self.updateAuthState(.serverUnreachable)
                    } else {
                        // Other errors - use cached user data if available
                        #if DEBUG
                            print("Failed to validate token with server. Using cached user.")
                        #endif
                        self.updateAuthState(.signedIn(fallbackUser))
                        self.scheduleTokenRefresh(expirationDate: fallbackExpiration)
                    }
                }
            } receiveValue: { response in
                if response.isValid {
                    // Token is valid, update auth state
                    self.updateAuthState(.signedIn(fallbackUser))
                    self.scheduleTokenRefresh(expirationDate: fallbackExpiration)
                } else {
                    // Token is invalid - try to refresh or sign out
                    if let refreshToken = self.keychainService.getRefreshToken() {
                        self.refreshAuthToken(refreshToken: refreshToken)
                    } else {
                        // No refresh token available, sign out
                        self.keychainService.clearAllTokens()
                        self.updateAuthState(.signedOut)
                    }
                }
            }
            .store(in: &cancellables)
    }

    /// Sign in with email and password
    ///
    /// - Parameters:
    ///  - email: The user's email address
    ///  - password: The user's password
    func signIn(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Please enter both email and password."
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
                // Process successful authentication response and update app state
                self.handleSuccessfulAuthentication(response)
            }
            .store(in: &cancellables)
    }

    /// Sign out the user
    func signOut() {
        self.isAuthenticating = true

        authService.logout()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isAuthenticating = false

                // Clear tokens even if logout fails
                self.tokenRefreshTimer?.invalidate()
                self.keychainService.clearAllTokens()
                self.updateAuthState(.signedOut)
            } receiveValue: { _ in
                // Already handled in completion
            }
            .store(in: &cancellables)
    }

    /// Check if account is pending deletion
    func isAccountPendingDeletion(email: String) -> Bool {
        // For now, return false since this is not implemented in the API
        return false
    }

    /// Reactivate account
    ///
    /// - Parameters:
    ///   - email: The user's email address
    func reactivateAccount(email: String) {
        self.isAuthenticating = true

        authService.reactivateAccount(email: email)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                self.isAuthenticating = false

                if case .failure(let error) = completion {
                    self.errorMessage =
                        "Failed to reactivate account: \(error.localizedDescription)"
                    self.showError = true
                }
            } receiveValue: { response in
                // Show success message
                self.errorMessage = "Account reactivated successfully. Please log in."
                self.showError = true
            }
            .store(in: &cancellables)
    }

    /// Function to exchange Google ID token for app token
    ///
    /// - Parameters:
    ///   - idToken: The Google ID token to exchange
    func exchangeGoogleToken(idToken: String) {
        self.isAuthenticating = true
        self.errorMessage = nil
        self.showError = false

        authService.exchangeGoogleToken(idToken: idToken)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isAuthenticating = false

                    switch completion {
                    case .finished:
                        // Successful login, state already set in receiveValue
                        break
                    case .failure(let error):
                        #if DEBUG
                            // Handle specific error cases
                            if case .decodingError(let underlyingError) = error {
                                self.errorMessage =
                                    "Failed to process server response: \(underlyingError.localizedDescription)"
                            } else if case .httpStatusCode(let code) = error, code == 400 {
                                self.errorMessage =
                                    "Invalid Google login attempt. Please try again or use a different method."
                            } else {
                                self.errorMessage =
                                    "Failed to log in with Google: \(error.localizedDescription)"
                            }
                        #else
                            // Handle generic error
                            self.errorMessage =
                                "Invalid Google login attempt. Please try again or use a different method."
                        #endif

                        // Show error message to user
                        self.showError = true
                        self.updateAuthState(.signedOut)
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    self.handleSuccessfulAuthentication(response)
                }
            )
            .store(in: &cancellables)
    }

    /// Exchange Apple ID token for app token
    func exchangeAppleToken(idToken: String) {
        self.isAuthenticating = true
        self.errorMessage = nil
        self.showError = false

        authService.exchangeAppleToken(idToken: idToken)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isAuthenticating = false

                    switch completion {
                    case .finished:
                        // Successful login, state already set in receiveValue
                        break
                    case .failure(let error):
                        #if DEBUG
                            // Handle specific error cases
                            if case .decodingError(let underlyingError) = error {
                                self.errorMessage =
                                    "Failed to process server response: \(underlyingError.localizedDescription)"
                            } else if case .httpStatusCode(let code) = error, code == 400 {
                                self.errorMessage =
                                    "Invalid Apple login attempt. Please try again or use a different method."
                            } else {
                                self.errorMessage =
                                    "Failed to log in with Apple: \(error.localizedDescription)"
                            }
                        #endif

                        // Show error message to user
                        self.showError = true
                        self.updateAuthState(.signedOut)
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }
                    self.handleSuccessfulAuthentication(response)
                }
            )
            .store(in: &cancellables)
    }

    /// Refresh auth token using refresh token
    private func refreshAuthToken(refreshToken: String) {
        self.authService.refreshToken(refreshToken: refreshToken)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case .failure(let error) = completion {
                    #if DEBUG
                        print("Failed to refresh token: \(error.localizedDescription)")
                    #endif

                    if case .connectivityError = error {
                        self.updateAuthState(.serverUnreachable)
                    } else {
                        self.keychainService.clearAllTokens()
                        self.updateAuthState(.signedOut)
                    }
                }
            } receiveValue: { response in
                self.handleSuccessfulAuthentication(response)
            }
            .store(in: &cancellables)
    }

    /// Refresh the authentication token if needed
    private func refreshAuthToken() {
        guard let refreshToken = keychainService.getRefreshToken() else {
            print("No refresh token available, signing out")
            signOut()
            return
        }
        
        refreshAuthToken(refreshToken: refreshToken)
    }

    /// Handle keychain operation errors
    private func handleKeychainError(operation: String) {
        print("Keychain operation failed: \(operation)")
        // For keychain errors, we'll show a generic error but not sign out
        // as the tokens might still be valid in memory
        showError(message: "Unable to securely store authentication data. Please restart the app if issues persist.")
    }

    /// Show error message to user
    func showError(message: String) {
        self.errorMessage = message
        self.showError = true
    }

    /// Clear the error message
    func clearError() {
        self.errorMessage = nil
        self.showError = false
    }

    /// Schedule automatic token refresh before expiration
    private func scheduleTokenRefresh(expirationDate: Date) {
        tokenRefreshTimer?.invalidate()
        
        let refreshTime = expirationDate.addingTimeInterval(-tokenRefreshBuffer)
        let timeUntilRefresh = refreshTime.timeIntervalSinceNow
        
        guard timeUntilRefresh > 0 else {
            // Token expires soon, refresh immediately
            refreshAuthToken()
            return
        }
        
        tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: timeUntilRefresh, repeats: false) { [weak self] _ in
            self?.refreshAuthToken()
        }
        
        print("Scheduled token refresh in \(timeUntilRefresh) seconds")
    }

    /// Process successful authentication response and update app state
    private func handleSuccessfulAuthentication(_ response: LoginResponse) {
        print("Processing successful authentication")
        
        // Store authentication data in keychain
        let tokenSaved = keychainService.saveAuthToken(response.token)
        if !tokenSaved {
            handleKeychainError(operation: "save auth token")
        }
        
        if let refreshToken = response.refreshToken {
            let refreshTokenSaved = keychainService.saveRefreshToken(refreshToken)
            if !refreshTokenSaved {
                handleKeychainError(operation: "save refresh token")
            }
        }
        
        // Parse and store token expiration if available
        if let expirationDate = parseTokenExpiration(response.expiresAt) {
            let expirationSaved = keychainService.saveTokenExpiration(expirationDate)
            if !expirationSaved {
                handleKeychainError(operation: "save token expiration")
            }
            scheduleTokenRefresh(expirationDate: expirationDate)
        }
        
        // Store user information
        if let user = response.user {
            let userSaved = keychainService.saveCurrentUser(user)
            if !userSaved {
                handleKeychainError(operation: "save user information")
            }
            
            // Update view model state
            self._currentUser = user
            self.authState = .signedIn(user)
        }
        
        // Clear any existing errors
        clearError()
        
        print("Authentication completed successfully")
    }

    /// Retry connection when server is unreachable
    func retryConnection() {
        print("Retrying connection...")
        authState = .loading
        
        // Clear any existing error state
        clearError()
        
        // Check authentication status again
        checkAuthStatus()
    }

    /// Parse token expiration date from string
    private func parseTokenExpiration(_ expiresAt: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: expiresAt)
    }
}

// MARK: - Factory Method

extension AuthViewModel {
    static func create() -> AuthViewModel {
        // Get auth service from environment, if not exists, create new one
        let authService = AuthService.create()
        let keychainService = KeychainService.create()
        return AuthViewModel(authService: authService, keychainService: keychainService)
    }
}
