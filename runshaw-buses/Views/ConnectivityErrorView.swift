import SwiftUI

/// View displayed when the server cannot be reached
struct ConnectivityErrorView: View {
    /// Authentication view model
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        ZStack {
            // Background color
            Design.Colors.lightGrey.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Standard header
                StandardHeader(
                    title: "Connection Error",
                    leftAction: nil,
                    rightAction: StandardHeader.HeaderAction(
                        iconName: "arrow.clockwise",
                        action: { authViewModel.retryConnection() }
                    )
                )
                
                ScrollView {
                    VStack(spacing: 0) {
                        SharedHeroView(
                            title: "Cannot Reach Server",
                            subtitle: "There seems to be a connection problem",
                            height: 220
                        )
                        
                        VStack(spacing: Design.Spacing.large) {
                            // Error explanation card
                            ContentPanel(title: "Connection Problem", iconName: "exclamationmark.triangle") {
                                VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                                    Text("We're having trouble connecting to our servers.")
                                        .font(.system(size: 16))
                                        .foregroundColor(Design.Colors.text)
                                    
                                    ConnectionErrorItem(
                                        icon: "wifi.exclamationmark",
                                        text: "Check your internet connection and try again."
                                    )
                                    
                                    ConnectionErrorItem(
                                        icon: "server.rack",
                                        text: "Our servers might be temporarily unavailable."
                                    )
                                    
                                    Divider()
                                        .padding(.vertical, Design.Spacing.small)
                                    
                                    AppButton(
                                        title: "Retry Connection",
                                        action: {
                                            authViewModel.retryConnection()
                                        }
                                    )
                                    .padding(.top, Design.Spacing.small)
                                }
                                .padding(Design.Spacing.medium)
                            }
                            
                            // Support information
                            ContentPanel(title: "Need Help?", iconName: "questionmark.circle") {
                                VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                                    Text("If the problem persists, please contact our support team:")
                                        .font(.system(size: 16))
                                        .foregroundColor(Design.Colors.text)
                                    
                                    Button(action: {
                                        if let url = URL(string: "mailto:support@konpeki.co.uk") {
                                            UIApplication.shared.open(url)
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "envelope.fill")
                                                .foregroundColor(Design.Colors.primary)
                                            
                                            Text("support@konpeki.co.uk")
                                                .font(.system(size: 16))
                                                .foregroundColor(Design.Colors.primary)
                                        }
                                        .padding(Design.Spacing.medium)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Design.Colors.primaryHover)
                                        .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
                                    }
                                }
                                .padding(Design.Spacing.medium)
                            }
                        }
                        .padding(.horizontal, Design.Spacing.medium)
                        .padding(.top, Design.Spacing.medium)
                        .padding(.bottom, Design.Spacing.extraLarge)
                    }
                }
            }
        }
    }
}

/// Helper view for displaying bulleted items with icons
struct ConnectionErrorItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: Design.Spacing.small) {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundColor(Design.Colors.primary)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(Design.Colors.darkGrey)
        }
    }
}

#if DEBUG
    /// Preview provider for ConnectivityErrorView
    struct ConnectivityErrorView_Previews: PreviewProvider {
        static var previews: some View {
            let networkService = NetworkService(
                baseURL: ConfigurationManager.shared.currentConfig.baseURL)
            let authService = AuthService(networkService: networkService)
            let authViewModel = AuthViewModel(authService: authService)
            
            return ConnectivityErrorView()
                .environmentObject(authViewModel)
        }
    }
#endif
