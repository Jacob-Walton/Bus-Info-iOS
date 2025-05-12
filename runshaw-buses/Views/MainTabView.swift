//
//  MainTabView.swift
//  runshaw-buses
//
//  Created by Jacob on 03/05/2025.
//  Copyright © 2025 Konpeki. All rights reserved.
//

import SwiftUI

/// Main tab-based navigation container for the app
struct MainTabView: View {
    /// Authentication view model for managing user session
    @EnvironmentObject var authViewModel: AuthViewModel
    
    /// Notification service for managing push notifications
    @EnvironmentObject var notificationService: NotificationService
    
    /// Currently selected tab
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            RankingsView()
                .tabItem {
                    Label("Rankings", systemImage: "trophy.fill") // Using trophy.fill for selected state
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill") // Using gearshape.fill for selected state
                }
                .tag(2)
        }
        .tint(Design.Colors.primary) // Apply the app's primary color to the tab bar items
    }
}
