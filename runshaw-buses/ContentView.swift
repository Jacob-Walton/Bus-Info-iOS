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
                MainTabView() // Use our new TabView navigation instead of directly showing HomeView
                    .transition(.opacity)
                    .id("main-\(authViewModel.currentUser?.id ?? "unknown")") // Force view refresh when user changes
            case .signedOut:
                LoginView()
                    .transition(.opacity)
            case .loading:
                loadingView
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

/// Preview provider for ContentView
#Preview {
    let networkService = NetworkService(baseURL: ConfigurationManager.shared.currentConfig.baseURL)
    let authService = AuthService(networkService: networkService)
    let authViewModel = AuthViewModel(authService: authService)
    
    return ContentView()
        .environmentObject(authViewModel)
}
