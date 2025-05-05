import Foundation
import AuthenticationServices

class WebAuthenticationService: NSObject, WebAuthenticationServiceProtocol {
    /// Shared instance
    static let shared: WebAuthenticationServiceProtocol = WebAuthenticationService()

    private var authSession: ASWebAuthenticationSession?
    private var completionHandler: ((Result<URL, Error>) -> Void)?

    override private init() {
        super.init()
    }

    func authenticate(using url: URL, callbackURLScheme: String, completion: @escaping (Result<URL, Error>) -> Void) {
        self.completionHandler = completion
        
        // Create the authentication session
        authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: callbackURLScheme
        ) { [weak self] (callbackURL, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.completionHandler?(.failure(error))
                return
            }
            
            guard let callbackURL = callbackURL else {
                self.completionHandler?(.failure(NSError(domain: "WebAuthentication", code: -1, userInfo: [NSLocalizedDescriptionKey: "No callback URL returned"])))
                return
            }
            
            self.completionHandler?(.success(callbackURL))
        }
        
        // Set presentation context provider (if available)
        if #available(iOS 13.0, *) {
            authSession?.presentationContextProvider = self
        }
        
        // Start session
        authSession?.start()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension WebAuthenticationService: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 13.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}

// MARK: - Factory Method

extension WebAuthenticationService {
    static func create() -> WebAuthenticationServiceProtocol {
        return WebAuthenticationService.shared
    }
}

// MARK: - Mock Web Authentication Service

#if DEBUG
class MockWebAuthenticationService: WebAuthenticationServiceProtocol {
    /// The mock result to be returned
    var mockResult: Result<URL, Error>?
    
    /// Records the URL and callback scheme used
    var lastAuthenticationURL: URL?
    var lastCallbackURLScheme: String?
    
    func authenticate(using url: URL, callbackURLScheme: String, completion: @escaping (Result<URL, Error>) -> Void) {
        // Record the authentication parameters
        lastAuthenticationURL = url
        lastCallbackURLScheme = callbackURLScheme
        
        // Return the mock result or a default error
        if let mockResult = mockResult {
            completion(mockResult)
        } else {
            completion(.failure(NSError(domain: "MockWebAuthentication", code: -1, userInfo: [NSLocalizedDescriptionKey: "No mock result set"])))
        }
    }
    
    /// Set a successful authentication result
    func setSuccessResult(callbackURL: URL) {
        mockResult = .success(callbackURL)
    }
    
    /// Set a failure authentication result
    func setFailureResult(error: Error) {
        mockResult = .failure(error)
    }
    
    /// Simulate a user cancellation
    func simulateUserCancellation() {
        let error = NSError(
            domain: "com.apple.AuthenticationServices.WebAuthenticationSession", 
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "User canceled login"]
        )
        mockResult = .failure(error)
    }
}
#endif