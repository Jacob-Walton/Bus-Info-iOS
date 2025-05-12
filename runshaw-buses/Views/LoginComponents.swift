import SwiftUI

/// Displays the app logo with styling
struct AppLogo: View {
    var body: some View {
        Image("logo-full")
            .resizable()
            .scaledToFit()
            .frame(width: 150, height: 150)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
            .padding(.bottom, Design.Spacing.small)
    }
}

/// Displays the welcome header text
struct WelcomeHeader: View {
    var body: some View {
        Text("Welcome Back")
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(Design.Colors.primary)
            .padding(.bottom, Design.Spacing.medium)
    }
}

/// Button for creating a new account
struct CreateAccountButton: View {
    var body: some View {
        IconTextButton(iconName: "person.badge.plus", label: "Create new account") {
            // Navigation to register screen will be implemented here
        }
        .padding(.top, Design.Spacing.medium)
    }
}

/// Modal view for reactivating an account that was previously marked for deletion
struct ReactivationModalView: View {
    /// Controls visibility of the modal
    @Binding var showModal: Bool
    
    /// Email address of the account to reactivate
    let username: String
    
    /// Action to perform when user confirms reactivation
    let onReactivate: () -> Void
    
    var body: some View {
        VStack(spacing: Design.Spacing.medium) {
            Text("Account Pending Deletion")
                .font(.system(size: Design.Typography.heading3Size, weight: .semibold))
                .foregroundStyle(Design.Colors.secondary)
            
            Text("Your account is currently scheduled for deletion. Would you like to reactivate it?")
                .font(.system(size: 16))
                .foregroundStyle(Design.Colors.text)
                .multilineTextAlignment(.center)
            
            HStack(spacing: Design.Spacing.medium) {
                AppButton(
                    title: "Cancel",
                    type: .outline
                ) {
                    showModal = false
                }
                
                AppButton(
                    title: "Reactivate Account",
                    type: .primary
                ) {
                    onReactivate()
                    showModal = false
                }
            }
        }
        .padding(Design.Spacing.large)
        .frame(maxWidth: 400)
        .background(Design.Colors.background)
        .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
        .shadow(color: Design.Colors.shadowColor, radius: 20, x: 0, y: 4)
    }
}
