import Foundation

protocol WebAuthenticationServiceProtocol {
    /// Authenticate using a web-based OAuth flow
    /// - Parameters:
    ///   - url: The URL to the authentication endpoint
    ///   - callbackURLScheme: URL scheme for callback
    ///   - completion: Callback with result containing callback URL or error
    func authenticate(using url: URL, callbackURLScheme: String, completion: @escaping (Result<URL, Error>) -> Void)
}
