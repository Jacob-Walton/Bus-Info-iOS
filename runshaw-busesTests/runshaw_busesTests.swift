import Testing
import Combine
@testable import runshaw_buses

// TODO: Create actual tests
struct runshaw_busesTests {
    
    @Test func testLoginSuccess() async throws {
        // Setup mock service with success response
        let mockAuthService = MockAuthService()
        let expectedResponse = LoginResponse(
            token: "test-token",
            refreshToken: "test-refresh-token",
            expiresAt: "2023-12-31T23:59:59Z",
            user: User(id: "1", email: "test@example.com", name: "Test User")
        )
        mockAuthService.mockLoginResponse = .success(expectedResponse)
        
        // Execute the login method
        var receivedResponse: LoginResponse?
        var receivedError: NetworkError?
        
        let cancellable = mockAuthService.login(email: "test@example.com", password: "password")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
            }, receiveValue: { response in
                receivedResponse = response
            })
        
        // Wait a bit for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        cancellable.cancel()
        
        // Verify results
        #expect(receivedResponse != nil)
        #expect(receivedError == nil)
        #expect(receivedResponse?.token == "test-token")
        #expect(receivedResponse?.refreshToken == "test-refresh-token")
    }
    
    @Test func testLoginFailure() async throws {
        // Setup mock service with failure response
        let mockAuthService = MockAuthService()
        let expectedError = NetworkError.unauthorized
        mockAuthService.mockLoginResponse = .failure(expectedError)
        
        // Execute the login method
        var receivedResponse: LoginResponse?
        var receivedError: NetworkError?
        
        let cancellable = mockAuthService.login(email: "test@example.com", password: "password")
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    receivedError = error
                }
            }, receiveValue: { response in
                receivedResponse = response
            })
        
        // Wait a bit for async operation to complete
        try await Task.sleep(nanoseconds: 100_000_000)
        cancellable.cancel()
        
        // Verify results
        #expect(receivedResponse == nil)
        #expect(receivedError != nil)
        #expect(receivedError == .unauthorized)
    }
    
    @Test func testRefreshToken() async throws {
        // Setup mock service with success response
        let mockAuthService = MockAuthService()
        let expectedResponse = LoginResponse(
            token: "new-token",
            refreshToken: "new-refresh-token",
            expiresAt: "2023-12-31T23:59:59Z",
            user: User(id: "1", email: "test@example.com", name: "Test User")
        )
        mockAuthService.mockRefreshResponse = .success(expectedResponse)
        
        // Execute the refresh token method
        var receivedResponse: LoginResponse?
        
        let cancellable = mockAuthService.refreshToken(refreshToken: "old-refresh-token")
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                receivedResponse = response
            })
        
        try await Task.sleep(nanoseconds: 100_000_000)
        cancellable.cancel()
        
        // Verify results
        #expect(receivedResponse != nil)
        #expect(receivedResponse?.token == "new-token")
        #expect(receivedResponse?.refreshToken == "new-refresh-token")
    }
    
    @Test func testLogout() async throws {
        // Setup mock service with success response
        let mockAuthService = MockAuthService()
        mockAuthService.mockLogoutResponse = .success(EmptyResponse())
        
        // Execute the logout method
        var completed = false
        var receivedError: NetworkError?
        
        let cancellable = mockAuthService.logout()
            .sink(receiveCompletion: { completion in
                if case .finished = completion {
                    completed = true
                } else if case .failure(let error) = completion {
                    receivedError = error
                }
            }, receiveValue: { _ in })
        
        try await Task.sleep(nanoseconds: 100_000_000)
        cancellable.cancel()
        
        // Verify results
        #expect(completed == true)
        #expect(receivedError == nil)
    }
    
    @Test func testValidateToken() async throws {
        // Setup mock service with success response
        let mockAuthService = MockAuthService()
        let validationResponse = TokenValidationResponse(isValid: true)
        mockAuthService.mockValidateTokenResponse = .success(validationResponse)
        
        // Execute validate token method
        var receivedResponse: TokenValidationResponse?
        
        let cancellable = mockAuthService.validateToken()
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                receivedResponse = response
            })
        
        try await Task.sleep(nanoseconds: 100_000_000)
        cancellable.cancel()
        
        // Verify results
        #expect(receivedResponse != nil)
        #expect(receivedResponse?.isValid == true)
    }
    
    @Test func testGetUserProfile() async throws {
        // Setup mock service with success response
        let mockAuthService = MockAuthService()
        let expectedUser = User(id: "1", email: "test@example.com", name: "Test User")
        mockAuthService.mockUserProfileResponse = .success(expectedUser)
        
        // Execute get user profile method
        var receivedUser: User?
        
        let cancellable = mockAuthService.getUserProfile()
            .sink(receiveCompletion: { _ in }, receiveValue: { user in
                receivedUser = user
            })
        
        try await Task.sleep(nanoseconds: 100_000_000)
        cancellable.cancel()
        
        // Verify results
        #expect(receivedUser != nil)
        #expect(receivedUser?.id == "1")
        #expect(receivedUser?.email == "test@example.com")
        #expect(receivedUser?.name == "Test User")
    }
    
    @Test func testExchangeGoogleToken() async throws {
        // Setup mock service with success response
        let mockAuthService = MockAuthService()
        let expectedResponse = LoginResponse(
            token: "google-token",
            refreshToken: "google-refresh-token",
            expiresAt: "2023-12-31T23:59:59Z",
            user: User(id: "1", email: "google@example.com", name: "Google User")
        )
        mockAuthService.mockGoogleTokenResponse = .success(expectedResponse)
        
        // Execute the google token exchange method
        var receivedResponse: LoginResponse?
        
        let cancellable = mockAuthService.exchangeGoogleToken(idToken: "google-id-token")
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                receivedResponse = response
            })
        
        try await Task.sleep(nanoseconds: 100_000_000)
        cancellable.cancel()
        
        // Verify results
        #expect(receivedResponse != nil)
        #expect(receivedResponse?.token == "google-token")
        #expect(receivedResponse?.user.email == "google@example.com")
    }
    
    @Test func testExchangeAppleToken() async throws {
        // Setup mock service with success response
        let mockAuthService = MockAuthService()
        let expectedResponse = LoginResponse(
            token: "apple-token",
            refreshToken: "apple-refresh-token",
            expiresAt: "2023-12-31T23:59:59Z",
            user: User(id: "1", email: "apple@example.com", name: "Apple User")
        )
        mockAuthService.mockAppleTokenResponse = .success(expectedResponse)
        
        // Execute the apple token exchange method
        var receivedResponse: LoginResponse?
        
        let cancellable = mockAuthService.exchangeAppleToken(idToken: "apple-id-token")
            .sink(receiveCompletion: { _ in }, receiveValue: { response in
                receivedResponse = response
            })
        
        try await Task.sleep(nanoseconds: 100_000_000)
        cancellable.cancel()
        
        // Verify results
        #expect(receivedResponse != nil)
        #expect(receivedResponse?.token == "apple-token")
        #expect(receivedResponse?.user.email == "apple@example.com")
    }
}
