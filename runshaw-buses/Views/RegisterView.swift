import SwiftUI
import AuthenticationServices
import GoogleSignIn

/// Main registration page
struct RegisterView: View {
    /// Authentication view model
    @EnvironmentObject var authViewModel: AuthViewModel
    
    /// User input fields
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var termsAgreed: Bool = false
    
    /// Apple Sign-In Coordinator
    @State private var appleSignInCoordinator: AppleSignInCoordinator?
    
    /// Web-based auth flow service
    private let webAuthService: WebAuthenticationServiceProtocol
    
    /// Current size class for layout adjustments
    @SwiftUI.Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
                        
                        // Registration form
                        FormSection {
                            HStack {
                                AppTextField(
                                    label: "First Name",
                                    placeholder: "Enter first name",
                                    text: $firstName,
                                    type: .text
                                )
                                
                                AppTextField(
                                    label: "Last Name",
                                    placeholder: "Enter last name",
                                    text: $lastName,
                                    type: .text
                                )
                            }
                            
                            AppTextField(
                                label: "Email",
                                placeholder: "Enter email",
                                text: $username,
                                type: .emailAddress
                            )
                            
                            AppTextField(
                                label: "Password",
                                placeholder: "Enter password",
                                text: $password,
                                type: .password
                            )
                            
                            AppTextField(
                                label: "Confirm Password",
                                placeholder: "Confirm your password",
                                text: $confirmPassword,
                                type: .password
                            )
                            
                            // TODO: Make checkbox a modular component and add terms/independence disclaimer agreement
                            
                            AppButton(
                                title: "Register",
                                isLoading:
                                    authViewModel.isAuthenticating
                            ) {
                                /* TODO: Handle register */
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
                                /* TODO: Handle Google register */
                            }
                            
                            SocialSignInButton(
                                iconName: "apple-logo",
                                label: "Apple"
                            ) {
                                /* TODO: Handle Apple register */
                            }
                        }
                        .padding(.horizontal, Design.Spacing.medium * 1.5)
                    }
                    .padding(.vertical, Design.Spacing.large)
                    .frame(minHeight: geometry.size.height)
                    .frame(maxWidth: 400)
                    .frame(maxWidth: .infinity)
                    .background(Design.Colors.background)
                }
            }
            .background(Design.Colors.background)
        }
    }
}

#if DEBUG
#Preview {
    RegisterView()
        .environmentObject(AuthViewModel(authService: MockAuthService(), keychainService: MockKeychainService()))
}
#endif
