import Foundation
import Combine

class AuthService: AuthServiceProtocol {
    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }

    func login(email: String, password: String) -> AnyPublisher<LoginResponse, NetworkError> {
        let loginRequest = LoginRequest(email: email, password: password)

        guard let data = try? JSONEncoder().encode(loginRequest) else {
            return Fail(error: NetworkError.unexpectedError(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode login request"]))).eraseToAnyPublisher()
        }

        return networkService.request(endpoint: "api/accounts/login", method: .post, body: data)
    }

    func refreshToken(refreshToken: String) -> AnyPublisher<LoginResponse, NetworkError> {
        let refreshRequest = TokenRefreshRequest(refreshToken: refreshToken)
        
        guard let data = try? JSONEncoder().encode(refreshRequest) else {
            return Fail(error: NetworkError.unexpectedError(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode refresh request"]))).eraseToAnyPublisher()
        }
        
        return networkService.request(endpoint: "api/token/refresh", method: .post, body: data)
    }
    
    func logout() -> AnyPublisher<EmptyResponse, NetworkError> {
        return networkService.request(endpoint: "api/accounts/logout", method: .post)
    }

    func isAccountPendingDeletion(email: String) -> AnyPublisher<Bool, NetworkError> {
        // let request = ReactivateAccountRequest(email: email)
        // guard let data = try? JSONEncoder().encode(request) else {
        //     return Fail(error: NetworkError.unexpectedError(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"]))).eraseToAnyPublisher()
        // }
        
        // return networkService.request(endpoint: "api/accounts/pending-deletion", method: .post, body: data)
        //     .map { $0.isPendingDeletion }
        //     .eraseToAnyPublisher()

        // Temporary implementation until the API supports this feature
        return Just(false)
            .setFailureType(to: NetworkError.self)
            .eraseToAnyPublisher()
    }
    
    func reactivateAccount(email: String) -> AnyPublisher<EmptyResponse, NetworkError> {
        let request = ReactivateAccountRequest(email: email)
        guard let data = try? JSONEncoder().encode(request) else {
            return Fail(error: NetworkError.unexpectedError(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request"]))).eraseToAnyPublisher()
        }
        
        return networkService.request(endpoint: "api/accounts/reactivate", method: .post, body: data)
    }
    
    func exchangeGoogleToken(idToken: String) -> AnyPublisher<LoginResponse, NetworkError> {
        let requestBody = GoogleTokenExchangeRequest(idToken: idToken)
        
        guard let data = try? JSONEncoder().encode(requestBody) else {
            return Fail(error: NetworkError.unexpectedError(NSError(domain: "AuthService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode Google token exchange request"]))).eraseToAnyPublisher()
        }
        
        return networkService.request(endpoint: "api/token/google", method: .post, body: data)
    }
    
    func exchangeAppleToken(idToken: String) -> AnyPublisher<LoginResponse, NetworkError> {
        let requestBody = AppleTokenExchangeRequest(idToken: idToken)
        
        guard let data = try? JSONEncoder().encode(requestBody) else {
            return Fail(error: NetworkError.unexpectedError(NSError(domain: "AuthService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to encode Apple token exchange request"])))
                .eraseToAnyPublisher()
        }
        
        return networkService.request(endpoint: "api/token/apple", method: .post, body: data)
    }
    
    func validateToken() -> AnyPublisher<TokenValidationResponse, NetworkError> {
        return networkService.request(endpoint: "api/token/validate", method: .post)
    }
    
    func getUserProfile() -> AnyPublisher<User, NetworkError> {
        return networkService.request(endpoint: "api/accounts/profile", method: .get)
    }
    
    func getUserPreferences() -> AnyPublisher<UserPreferences, NetworkError> {
        return Fail(error: NetworkError.invalidResponse).eraseToAnyPublisher()
    }
}

// MARK: - Factory Method

extension AuthService {
    static func create() -> AuthServiceProtocol {
        return AuthService(networkService: NetworkService.create())
    }
}

// MARK: - Mock Auth Service

#if DEBUG
// TODO: Implement the mock service
class MockAuthService: AuthServiceProtocol {
    var mockLoginResponse: Result<LoginResponse, NetworkError> = .failure(.unexpectedError(NSError()))
    var mockRefreshResponse: Result<LoginResponse, NetworkError> = .failure(.unexpectedError(NSError()))
    var mockLogoutResponse: Result<EmptyResponse, NetworkError> = .failure(.unexpectedError(NSError()))
    var mockIsAccountPendingDeletionResponse: Result<Bool, NetworkError> = .failure(.unexpectedError(NSError()))
    var mockReactivateResponse: Result<EmptyResponse, NetworkError> = .failure(.unexpectedError(NSError()))
    var mockGoogleTokenResponse: Result<LoginResponse, NetworkError> = .failure(.unexpectedError(NSError()))
    var mockAppleTokenResponse: Result<LoginResponse, NetworkError> = .failure(.unexpectedError(NSError()))
    var mockValidateTokenResponse: Result<TokenValidationResponse, NetworkError> = .failure(.unexpectedError(NSError()))
    var mockUserProfileResponse: Result<User, NetworkError> = .failure(.unexpectedError(NSError()))
    
    func login(email: String, password: String) -> AnyPublisher<LoginResponse, NetworkError> {
        return mockLoginResponse.publisher.eraseToAnyPublisher()
    }
    
    func refreshToken(refreshToken: String) -> AnyPublisher<LoginResponse, NetworkError> {
        return mockRefreshResponse.publisher.eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<EmptyResponse, NetworkError> {
        return mockLogoutResponse.publisher.eraseToAnyPublisher()
    }

    func isAccountPendingDeletion(email: String) -> AnyPublisher<Bool, NetworkError> {
        return mockIsAccountPendingDeletionResponse.publisher.eraseToAnyPublisher()
    }
    
    func reactivateAccount(email: String) -> AnyPublisher<EmptyResponse, NetworkError> {
        return mockReactivateResponse.publisher.eraseToAnyPublisher()
    }
    
    func exchangeGoogleToken(idToken: String) -> AnyPublisher<LoginResponse, NetworkError> {
        return mockGoogleTokenResponse.publisher.eraseToAnyPublisher()
    }
    
    func exchangeAppleToken(idToken: String) -> AnyPublisher<LoginResponse, NetworkError> {
        return mockAppleTokenResponse.publisher.eraseToAnyPublisher()
    }
    
    func validateToken() -> AnyPublisher<TokenValidationResponse, NetworkError> {
        return mockValidateTokenResponse.publisher.eraseToAnyPublisher()
    }
    
    func getUserProfile() -> AnyPublisher<User, NetworkError> {
        return mockUserProfileResponse.publisher.eraseToAnyPublisher()
    }
    
    func getUserPreferences() -> AnyPublisher<UserPreferences, NetworkError> {
        fatalError("Not implemented")
    }
}
#endif
