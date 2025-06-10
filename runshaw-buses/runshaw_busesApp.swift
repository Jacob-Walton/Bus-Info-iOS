//
//  runshaw_busesApp.swift
//  runshaw-buses
//
//  Created by Jacob on 03/05/2025.
//  Copyright © 2025 Konpeki. All rights reserved.
//

import SwiftUI
import GoogleSignIn
import UserNotifications

/// Main application entry point
@main
struct runshaw_busesApp: App {
    /// Core network service for API communication
    private let networkService: NetworkServiceProtocol
    /// Authentication service for user management
    private let authService: AuthServiceProtocol
    /// Keychain service for secure storage
    private let keychainService: KeychainServiceProtocol
    
    /// Authentication view model for managing user state
    @StateObject private var authViewModel: AuthViewModel
    
    /// App delegate for handling system events
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate
    
    /// Initializes the application and its services
    init() {
        // Initialize core services using protocol-based architecture
        let network = NetworkService.create()
        let keychain = KeychainService.shared
        let auth = AuthService(networkService: network)
        
        // Store service references
        self.networkService = network
        self.authService = auth
        self.keychainService = keychain
        
        // Initialize view models with dependencies
        self._authViewModel = StateObject(wrappedValue: AuthViewModel(authService: auth))
        
        // Configure third-party services
        configureGoogleSignIn()
    }
    
    /// Configures Google Sign-In with client ID from Info.plist
    private func configureGoogleSignIn() {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            fatalError("Missing GIDClientID in Info.plist. Please add the Google client ID to your configuration.")
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        print("Google Sign-In configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.light)
                // Handle deep links for authentication callbacks
                .onOpenURL { url in
                    print("Handling deep link: \(url)")
                    // Process URL through Google Sign-In
                    let handled = GIDSignIn.sharedInstance.handle(url)
                    if !handled {
                        // Handle other URL schemes if needed
                        print("URL not handled by Google Sign-In")
                    }
                }
        }
    }
}

/// App delegate for handling system-level events and notifications
class AppDelegate: NSObject, UIApplicationDelegate {
    /// Called when app finishes launching, sets up notifications
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Request permission to send notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            if let error = error {
                print("Notification authorization failed: \(error.localizedDescription)")
            }
        }
        return true
    }
    
    /// Called when device successfully registers for remote notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Notify the NotificationService about the new token
        NotificationCenter.default.post(
            name: Notification.Name("ReceivedDeviceToken"),
            object: nil,
            userInfo: ["deviceToken": deviceToken]
        )
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Remote notification device token: \(tokenString)")
    }
    
    /// Called when registration for remote notifications fails
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
}
