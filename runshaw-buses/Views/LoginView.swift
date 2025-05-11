//
//  LoginView.swift
//  runshaw-buses
//
//  Created by Jacob on 03/05/2025.
//  Copyright © 2025 Konpeki. All rights reserved.
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

/// Main login screen that handles user authentication through multiple methods
struct LoginView: View {
    /// Authentication view model for managing sign-in processes
    @EnvironmentObject var authViewModel: AuthViewModel
    
    /// User input fields for email/password authentication
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    
    /// Controls visibility of the account reactivation modal
    @State private var showReactivationModal: Bool = false
    
    /// Coordinator for Apple Sign-In (maintained as state to prevent deallocation)
    @State private var appleSignInCoordinator: AppleSignInCoordinator?
    
    /// Service for web-based authentication flows
    private let webAuthService: WebAuthenticationServiceProtocol
    
    /// Current size class for responsive layout adjustments
    @SwiftUI.Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    /// Initialize with dependencies
    init(webAuthService: WebAuthenticationServiceProtocol = WebAuthenticationService.shared) {
        self.webAuthService = webAuthService
    }
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Updated hero with SharedHeroView
                    SharedHeroView(
                        title: "Welcome Back",
                        subtitle: "Sign in to check bus status",
                        height: 180,
                        contentBottomPadding: 24
                    )
                    .padding(.bottom, Design.Spacing.medium)
                    
                    VStack(alignment: .center) {
                        // App logo
                        AppLogo()
                            .padding(.bottom, Design.Spacing.small)
                            
                        // Error message display
                        if authViewModel.showError, let errorMessage = authViewModel.errorMessage {
                            ErrorBanner(message: errorMessage)
                                .padding(.horizontal, Design.Spacing.medium)
                        }
                        
                        // Login form
                        FormSection {
                            AppTextField(
                                label: "Email",
                                placeholder: "Enter your email",
                                text: $username
                            )
                            
                            AppTextField(
                                label: "Password",
                                placeholder: "Enter your password",
                                text: $password,
                                isSecure: true
                            )
                            
                            RememberMeRow(isChecked: $rememberMe)
                            
                            AppButton(
                                title: "Sign In",
                                isLoading: authViewModel.isAuthenticating
                            ) {
                                handleLogin()
                            }
                            .padding(.top, Design.Spacing.small)
                        }
                        .padding(.horizontal, Design.Spacing.medium * 1.5)
                        
                        DividerWithText(text: "or continue with")
                        
                        // Social authentication options
                        HStack(spacing: Design.Spacing.small) {
                            SocialSignInButton(
                                iconName: "google-logo",
                                label: "Google"
                            ) {
                                handleGoogleSignInSDK()
                            }
                            
                            SocialSignInButton(
                                iconName: "apple-logo",
                                label: "Apple"
                            ) {
                                handleAppleSignIn()
                            }
                        }
                        .padding(.horizontal, Design.Spacing.medium * 1.5)
                        
                        CreateAccountButton()
                            .padding(.top, Design.Spacing.medium)
                    }
                    .padding(.vertical, Design.Spacing.large)
                    .frame(minHeight: geometry.size.height - 180)  // Adjust for hero height
                    .frame(maxWidth: 400)
                    .frame(maxWidth: .infinity)
                    .background(Design.Colors.background)
                }
            }
            .background(Design.Colors.background)
        }
        .sheet(isPresented: $showReactivationModal) {
            ReactivationModalView(
                showModal: $showReactivationModal,
                username: username
            ) {
                authViewModel.reactivateAccount(email: username)
            }
        }
    }
    
    // MARK: - Authentication Handlers
    
    /// Handles the standard email/password login process
    /// Checks for special account states like pending deletion
    private func handleLogin() {
        // Check account status before processing login
        if authViewModel.isAccountPendingDeletion(email: username) {
            showReactivationModal = true
            return
        }
        
        // Process standard authentication
        authViewModel.signIn(email: username, password: password)
    }
    
    /// Initiates Google Sign-In authentication flow using the SDK
    private func handleGoogleSignInSDK() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            authViewModel.showError(message: "Could not find root view controller for Google Sign-In.")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            guard error == nil else {
                authViewModel.showError(message: "Google Sign-In failed: \(error!.localizedDescription)")
                return
            }

            guard let signInResult = signInResult else {
                authViewModel.showError(message: "Google Sign-In failed: No result returned.")
                return
            }

            // Successfully signed in with Google
            guard let idToken = signInResult.user.idToken?.tokenString else {
                authViewModel.showError(message: "Google Sign-In failed: Could not retrieve ID token.")
                return
            }

            // Exchange Google ID token for app-specific JWT
            authViewModel.exchangeGoogleToken(idToken: idToken)
        }
    }
    
    /// Initiates Apple Sign-In authentication flow
    private func handleAppleSignIn() {
        // Create and store the coordinator to prevent premature deallocation
        let coordinator = AppleSignInCoordinator(authViewModel: authViewModel)
        self.appleSignInCoordinator = coordinator
        coordinator.startSignInFlow()
    }
}

// MARK: - Apple Sign In Coordinator

/// Coordinator class that handles the Apple Sign-In authentication flow
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    /// Reference to the authentication view model for completing the sign-in process
    private let authViewModel: AuthViewModel
    
    /// Initialize the coordinator with the authentication view model
    /// - Parameter authViewModel: The view model that will process the authentication response
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        super.init()
    }
    
    /// Begins the Apple Sign-In authentication flow
    func startSignInFlow() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
    
    // MARK: - ASAuthorizationControllerDelegate
    
    /// Handles successful Apple Sign-In authorization
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Extract the identity token
            guard let identityToken = appleIDCredential.identityToken,
                  let tokenString = String(data: identityToken, encoding: .utf8) else {
                authViewModel.showError(message: "Apple Sign In failed: Could not retrieve identity token.")
                return
            }
            
            // Send the token to the backend for verification and authentication
            authViewModel.exchangeAppleToken(idToken: tokenString)
        } else {
            authViewModel.showError(message: "Apple Sign In failed: Invalid credentials received.")
        }
    }
    
    /// Handles Apple Sign-In authorization errors
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.authViewModel.showError(message: "Apple Sign In failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - ASAuthorizationControllerPresentationContextProviding
    
    /// Provides the presentation anchor for the authorization UI
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window found for presenting Apple Sign In")
        }
        return window
    }
}

// MARK: - Preview Providers

/// SwiftUI preview for the LoginView
#Preview {
    let networkService = NetworkService(
        baseURL: ConfigurationManager.shared.currentConfig.baseURL
    )
    let authService = AuthService(networkService: networkService)
    let authViewModel = AuthViewModel(
        authService: authService, 
        keychainService: KeychainService.shared
    )
    
    return LoginView(webAuthService: WebAuthenticationService.shared)
        .environmentObject(authViewModel)
}