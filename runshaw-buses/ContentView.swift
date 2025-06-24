//
//  ContentView.swift
//  runshaw-buses
//
//  Created by Jacob on 03/05/2025.
//  Copyright © 2025 Konpeki. All rights reserved.
//

import SwiftUI

/// Main content view that handles authentication state and displays the appropriate UI
struct ContentView: View {
    /// Authentication view model providing current auth state
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Group {
            switch authViewModel.authState {
            case .signedIn:
                MainTabView()
                    .transition(.opacity)
                    .id("main-\(authViewModel.currentUser?.id ?? "unknown")")  // Force view refresh when user changes
            case .signedOut:
                LoginViewWrapper()
                    .transition(.opacity)
            case .loading:
                loadingView
            case .serverUnreachable:
                ConnectivityErrorView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: authViewModel.authState)
    }

    /// Loading indicator view displayed during authentication state transitions
    private var loadingView: some View {
        VStack(spacing: Design.Spacing.medium) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text("Loading...")
                .foregroundStyle(Design.Colors.darkGrey)
                .font(.system(size: Design.Typography.bodySize))
        }
    }
}

#if DEBUG
    /// Preview provider for ContentView
    struct ContentView_Previews: PreviewProvider {
        static var previews: some View {
            let networkService = NetworkService(
                baseURL: ConfigurationManager.shared.currentConfig.baseURL)
            let authService = AuthService(networkService: networkService)
            let authViewModel = AuthViewModel(authService: authService)

            return ContentView()
                .environmentObject(authViewModel)
        }
    }
#endif
