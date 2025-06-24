import AuthenticationServices
import GoogleSignIn
import SwiftUI

/// New multi-step login view
struct NewLoginView: View {
    /// Authentication view model for managing sign-in processes
    @EnvironmentObject var authViewModel: AuthViewModel
    
    /// Current step in the login flow
    @State private var currentStep: LoginStep = .welcome
    
    /// User input fields
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false
    
    /// Animation and UI state
    @State private var showPassword: Bool = false
    @State private var animateTransition: Bool = false
    
    /// Controls visibility of modals
    @State private var showReactivationModal: Bool = false
    @State private var showRegisterView: Bool = false
    
    /// Coordinator for Apple Sign-In
    @State private var appleSignInCoordinator: AppleSignInCoordinator?
    
    /// Service for web-based authentication flows
    private let webAuthService: WebAuthenticationServiceProtocol
    
    /// Login flow steps
    enum LoginStep: CaseIterable {
        case welcome
        case email
        case password
        case socialAuth
    }
    
    init(webAuthService: WebAuthenticationServiceProtocol = WebAuthenticationService.shared) {
        self.webAuthService = webAuthService
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Progress indicator
                LoginProgressIndicator(
                    currentStep: currentStep,
                    totalSteps: LoginStep.allCases.count
                )
                .padding(.top, Design.Spacing.medium)
                
                ScrollView {
                    VStack(spacing: Design.Spacing.large) {
                        // App logo (smaller on step screens)
                        if currentStep == .welcome {
                            AppLogo()
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            AppLogo()
                                .scaleEffect(0.6)
                                .transition(.scale.combined(with: .opacity))
                        }
                        
                        // Error message display
                        if authViewModel.showError, let errorMessage = authViewModel.errorMessage {
                            ErrorBanner(message: errorMessage)
                                .padding(.horizontal, Design.Spacing.medium)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // Step content
                        stepContent
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
                    }
                    .padding(.vertical, Design.Spacing.large)
                    .frame(minHeight: geometry.size.height - 80) // Account for progress bar
                }
                
                // Navigation buttons
                navigationButtons
                    .padding(.horizontal, Design.Spacing.medium)
                    .padding(.bottom, Design.Spacing.medium)
            }
            .background(Design.Colors.background)
        }
        .sheet(isPresented: $showRegisterView) {
            RegisterView()
                .environmentObject(authViewModel)
        }
        .sheet(isPresented: $showReactivationModal) {
            ReactivationModalView(
                showModal: $showReactivationModal,
                username: email
            ) {
                authViewModel.reactivateAccount(email: email)
            }
        }
    }
    
    @ViewBuilder
    private var stepContent: some View {
        VStack(spacing: Design.Spacing.large) {
            switch currentStep {
            case .welcome:
                welcomeStep
            case .email:
                emailStep
            case .password:
                passwordStep
            case .socialAuth:
                socialAuthStep
            }
        }
        .frame(maxWidth: 400)
        .padding(.horizontal, Design.Spacing.medium)
    }
    
    private var welcomeStep: some View {
        VStack(spacing: Design.Spacing.medium) {
            Text("Welcome Back")
                .ubuntuFont(style: .bold, size: Design.Typography.heading2Size)
                .foregroundColor(Design.Colors.secondary)
                .multilineTextAlignment(.center)
            
            Text("Sign in to access your personalized bus schedule and stay updated with real-time information.")
                .ubuntuFont(style: .regular, size: Design.Typography.bodySize)
                .foregroundColor(Design.Colors.darkGrey)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    private var emailStep: some View {
        VStack(spacing: Design.Spacing.medium) {
            VStack(alignment: .leading, spacing: Design.Spacing.small) {
                Text("What's your email?")
                    .ubuntuFont(style: .bold, size: Design.Typography.heading3Size)
                    .foregroundColor(Design.Colors.secondary)
                
                Text("Enter the email address associated with your account.")
                    .ubuntuFont(style: .regular, size: Design.Typography.bodySize)
                    .foregroundColor(Design.Colors.darkGrey)
            }
            
            AppTextField(
                label: "Email Address",
                placeholder: "your.email@example.com",
                text: $email,
                type: .emailAddress
            )
            .onSubmit {
                if isEmailValid {
                    nextStep()
                }
            }
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    private var passwordStep: some View {
        VStack(spacing: Design.Spacing.medium) {
            VStack(alignment: .leading, spacing: Design.Spacing.small) {
                Text("Enter your password")
                    .ubuntuFont(style: .bold, size: Design.Typography.heading3Size)
                    .foregroundColor(Design.Colors.secondary)
                
                Text("Welcome back, \(email.components(separatedBy: "@").first ?? "there")!")
                    .ubuntuFont(style: .regular, size: Design.Typography.bodySize)
                    .foregroundColor(Design.Colors.darkGrey)
            }
            
            AppTextField(
                label: "Password",
                placeholder: "Enter your password",
                text: $password,
                type: .password
            )
            .onSubmit {
                if isPasswordValid {
                    handleLogin()
                }
            }
            
            RememberMeRow(isChecked: $rememberMe)
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    private var socialAuthStep: some View {
        VStack(spacing: Design.Spacing.medium) {
            VStack(alignment: .leading, spacing: Design.Spacing.small) {
                Text("Or continue with")
                    .ubuntuFont(style: .bold, size: Design.Typography.heading3Size)
                    .foregroundColor(Design.Colors.secondary)
                
                Text("Choose your preferred sign-in method.")
                    .ubuntuFont(style: .regular, size: Design.Typography.bodySize)
                    .foregroundColor(Design.Colors.darkGrey)
            }
            
            VStack(spacing: Design.Spacing.small) {
                SocialSignInButton(
                    iconName: "google-logo",
                    label: "Continue with Google"
                ) {
                    handleGoogleSignInSDK()
                }
                
                SocialSignInButton(
                    iconName: "apple-logo",
                    label: "Continue with Apple"
                ) {
                    handleAppleSignIn()
                }
            }
            
            CreateAccountButton {
                showRegisterView = true
            }
            .padding(.top, Design.Spacing.medium)
        }
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    @ViewBuilder
    private var navigationButtons: some View {
        HStack(spacing: Design.Spacing.medium) {
            // Back button
            if currentStep != .welcome {
                Button("Back") {
                    previousStep()
                }
                .font(.custom(Design.Typography.UbuntuStyle.medium.rawValue, size: Design.Typography.bodySize))
                .foregroundColor(Design.Colors.darkGrey)
                .padding(.vertical, Design.Spacing.small)
                .padding(.horizontal, Design.Spacing.medium)
                .background(Design.Colors.lightGrey)
                .clipShape(AlternatingRoundedRectangle(radius: Design.Layout.buttonRadius))
            }
            
            Spacer()
            
            // Next/Continue button
            Button(nextButtonTitle) {
                handleNextAction()
            }
            .font(.custom(Design.Typography.UbuntuStyle.medium.rawValue, size: Design.Typography.bodySize))
            .foregroundColor(.white)
            .padding(.vertical, Design.Spacing.small)
            .padding(.horizontal, Design.Spacing.large)
            .background(isNextButtonDisabled ? Design.Colors.lightGrey : Design.Colors.primary)
            .clipShape(AlternatingRoundedRectangle(radius: Design.Layout.buttonRadius))
            .disabled(isNextButtonDisabled)
            .opacity(authViewModel.isAuthenticating ? 0.6 : 1.0)
            .overlay(
                Group {
                    if authViewModel.isAuthenticating && currentStep == .password {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                }
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var nextButtonTitle: String {
        switch currentStep {
        case .welcome:
            return "Get Started"
        case .email:
            return "Continue"
        case .password:
            return authViewModel.isAuthenticating ? "" : "Sign In"
        case .socialAuth:
            return "Use Email Instead"
        }
    }
    
    private var isNextButtonDisabled: Bool {
        switch currentStep {
        case .welcome:
            return false
        case .email:
            return !isEmailValid
        case .password:
            return !isPasswordValid || authViewModel.isAuthenticating
        case .socialAuth:
            return false
        }
    }
    
    private var isEmailValid: Bool {
        email.contains("@") && email.contains(".") && !email.isEmpty
    }
    
    private var isPasswordValid: Bool {
        !password.isEmpty
    }
    
    // MARK: - Navigation Methods
    
    private func nextStep() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            switch currentStep {
            case .welcome:
                currentStep = .socialAuth
            case .email:
                currentStep = .password
            case .password:
                break // Handled by login action
            case .socialAuth:
                currentStep = .email
            }
        }
    }
    
    private func previousStep() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            switch currentStep {
            case .welcome:
                break
            case .email:
                currentStep = .socialAuth
            case .password:
                currentStep = .email
            case .socialAuth:
                currentStep = .welcome
            }
        }
    }
    
    private func handleNextAction() {
        switch currentStep {
        case .welcome:
            nextStep()
        case .email:
            if isEmailValid {
                nextStep()
            }
        case .password:
            if isPasswordValid {
                handleLogin()
            }
        case .socialAuth:
            nextStep()
        }
    }
    
    // MARK: - Authentication Handlers
    
    private func handleLogin() {
        if authViewModel.isAccountPendingDeletion(email: email) {
            showReactivationModal = true
            return
        }
        
        authViewModel.signIn(email: email, password: password)
    }
    
    private func handleGoogleSignInSDK() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController
        else {
            authViewModel.showError(message: "Could not find root view controller for Google Sign-In.")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            guard error == nil else {
                authViewModel.showError(message: "Google Sign-In failed: \(error!.localizedDescription)")
                return
            }
            
            guard let signInResult = signInResult,
                  let idToken = signInResult.user.idToken?.tokenString else {
                authViewModel.showError(message: "Google Sign-In failed: Could not retrieve ID token.")
                return
            }
            
            authViewModel.exchangeGoogleToken(idToken: idToken)
        }
    }
    
    private func handleAppleSignIn() {
        let coordinator = AppleSignInCoordinator(authViewModel: authViewModel)
        self.appleSignInCoordinator = coordinator
        coordinator.startSignInFlow()
    }
}

/// Progress indicator for the multi-step login flow
struct LoginProgressIndicator: View {
    let currentStep: NewLoginView.LoginStep
    let totalSteps: Int
    
    private var currentStepIndex: Int {
        NewLoginView.LoginStep.allCases.firstIndex(of: currentStep) ?? 0
    }
    
    var body: some View {
        VStack(spacing: Design.Spacing.small) {
            HStack(spacing: Design.Spacing.tiny) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Rectangle()
                        .fill(index <= currentStepIndex ? Design.Colors.primary : Design.Colors.lightGrey)
                        .frame(height: 3)
                        .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
                }
            }
            .padding(.horizontal, Design.Spacing.medium)
            
            HStack {
                Text("Step \(currentStepIndex + 1) of \(totalSteps)")
                    .ubuntuFont(style: .regular, size: Design.Typography.xSmallSize)
                    .foregroundColor(Design.Colors.darkGrey)
                
                Spacer()
            }
            .padding(.horizontal, Design.Spacing.medium)
        }
    }
}

// MARK: - Apple Sign In Coordinator

/// Coordinator class that handles the Apple Sign-In authentication flow
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
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
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            // Extract the identity token
            guard let identityToken = appleIDCredential.identityToken,
                let tokenString = String(data: identityToken, encoding: .utf8)
            else {
                authViewModel.showError(
                    message: "Apple Sign In failed: Could not retrieve identity token.")
                return
            }

            // Send the token to the backend for verification and authentication
            authViewModel.exchangeAppleToken(idToken: tokenString)
        } else {
            authViewModel.showError(message: "Apple Sign In failed: Invalid credentials received.")
        }
    }

    /// Handles Apple Sign-In authorization errors
    func authorizationController(
        controller: ASAuthorizationController, didCompleteWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.authViewModel.showError(
                message: "Apple Sign In failed: \(error.localizedDescription)")
        }
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    /// Provides the presentation anchor for the authorization UI
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = windowScene.windows.first
        else {
            fatalError("No window found for presenting Apple Sign In")
        }
        return window
    }
}

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

    /// Controls visibility of the registration view
    @State private var showRegisterView: Bool = false

    /// Initialize with dependencies
    init(webAuthService: WebAuthenticationServiceProtocol = WebAuthenticationService.shared) {
        self.webAuthService = webAuthService
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
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
                                text: $username,
                                type: .emailAddress,
                            )

                            AppTextField(
                                label: "Password",
                                placeholder: "Enter your password",
                                text: $password,
                                type: .password
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

                        CreateAccountButton {
                            showRegisterView = true
                        }
                        .padding(.top, Design.Spacing.medium)
                    }
                    .padding(.vertical, Design.Spacing.large)
                    .frame(minHeight: geometry.size.height)
                    .frame(maxWidth: 400)
                    .frame(maxWidth: .infinity)
                    .background(Design.Colors.background)
                }
            }
            .background(Design.Colors.background)
            .sheet(isPresented: $showRegisterView) {
                RegisterView()
                    .environmentObject(authViewModel)
            }
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
            let rootViewController = windowScene.windows.first?.rootViewController
        else {
            authViewModel.showError(
                message: "Could not find root view controller for Google Sign-In.")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
            guard error == nil else {
                authViewModel.showError(
                    message: "Google Sign-In failed: \(error!.localizedDescription)")
                return
            }

            guard let signInResult = signInResult else {
                authViewModel.showError(message: "Google Sign-In failed: No result returned.")
                return
            }

            // Successfully signed in with Google
            guard let idToken = signInResult.user.idToken?.tokenString else {
                authViewModel.showError(
                    message: "Google Sign-In failed: Could not retrieve ID token.")
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

// MARK: - Preview Providers

#if DEBUG
    /// Preview for the LoginView
    struct LoginView_Previews: PreviewProvider {
        static var previews: some View {
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
    }
#endif // DEBUG


/// Wrapper view that conditionally shows either the original or new login based on experiment flag
struct LoginViewWrapper: View {
    private let webAuthService: WebAuthenticationServiceProtocol
    
    init(webAuthService: WebAuthenticationServiceProtocol = WebAuthenticationService.shared) {
        self.webAuthService = webAuthService
    }
    
    var body: some View {
        Group {
            // Show the original design
            LoginView(webAuthService: webAuthService)
                .transition(.opacity)
        }
    }
}
