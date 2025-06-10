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
                    Label("Rankings", systemImage: "trophy.fill")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .tint(Design.Colors.primary)
    }
}
