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
    
    /// Bus info view model for managing bus information
    @EnvironmentObject var busInfoViewModel: BusInfoViewModel
    
    /// Tab items configuration
    private var tabItems: [TabItem] {
        [
            TabItem(id: "home", iconName: "house.fill", title: "Home") {
                HomeView()
            },
            TabItem(id: "rankings", iconName: "trophy.fill", title: "Rankings") {
                RankingsView()
            },
            TabItem(id: "settings", iconName: "gearshape.fill", title: "Settings") {
                SettingsView()
            }
        ]
    }
    
    var body: some View {
        CustomTabNavigationView(
            tabs: tabItems,
            initialTab: "home"
        )
    }
}
