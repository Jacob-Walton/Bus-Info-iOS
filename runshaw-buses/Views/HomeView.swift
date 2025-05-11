//
//  HomeView.swift
//  runshaw-buses
//
//  Created by Jacob on 03/05/2025.
//  Copyright © 2025 Konpeki. All rights reserved.
//

import SwiftUI

/// Main home screen displaying bus information and status
struct HomeView: View {
    /// Authentication view model for managing user session
    @EnvironmentObject var authViewModel: AuthViewModel
    
    /// Notification service for managing push notifications
    @EnvironmentObject var notificationService: NotificationService
    
    /// View model for bus information and status
    @StateObject private var busInfoViewModel: BusInfoViewModel
    
    /// Initialize with dependencies
    init(busInfoViewModel: BusInfoViewModel? = nil) {
        // Use provided view model or create a new one using factory
        if let viewModel = busInfoViewModel {
            _busInfoViewModel = StateObject(wrappedValue: viewModel)
        } else {
            _busInfoViewModel = StateObject(wrappedValue: BusInfoViewModel.create())
        }
    }
    
    var body: some View {
        ZStack {
            // Background color
            Design.Colors.lightGrey.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation header instead of NavigationStack
                CustomNavigationHeader(
                    busInfoViewModel: busInfoViewModel,
                    onSignOut: {
                        authViewModel.signOut()
                    }
                )
                
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        SharedHeroView(
                            title: "Runshaw Buses",
                            subtitle: "Check the latest bus arrivals",
                            height: 220,
                            contentBottomPadding: 24,
                            additionalContent: {
                                DateBadge()
                            }
                        )
                        
                        // Error message display
                        if let error = busInfoViewModel.error {
                            ErrorBanner(message: error)
                                .padding(.horizontal, Design.Spacing.medium)
                                .padding(.top, Design.Spacing.medium)
                        }
                        
                        // Main content sections
                        VStack(spacing: Design.Spacing.large) {
                            // Bus status section
                            VStack(alignment: .leading, spacing: Design.Spacing.small) {
                                Text("Bus Status")
                                    .font(.system(size: Design.Typography.heading5Size, weight: .semibold))
                                    .foregroundStyle(Design.Colors.secondary)
                                
                                // Display bus list or empty state
                                if busInfoViewModel.sortedBusKeys.isEmpty && !busInfoViewModel.isLoading {
                                    EmptyBusState()
                                } else {
                                    BusListView(busInfoViewModel: busInfoViewModel)
                                }
                            }
                            
                            // Last updated information
                            InfoSection(lastUpdated: busInfoViewModel.formattedLastUpdated())
                            
                            // Bus map section
                            if let mapUrl = busInfoViewModel.mapUrl {
                                BusMapView(mapUrl: mapUrl)
                            }
                        }
                        .padding(.horizontal, Design.Spacing.medium)
                        .padding(.top, Design.Spacing.medium)
                        .padding(.bottom, Design.Spacing.extraLarge)
                    }
                }
                .refreshable {
                    await refreshData()
                }
            }
            
            // Loading overlay
            if busInfoViewModel.isLoading {
                LoadingOverlay()
            }
        }
        .onAppear {
            // Refresh data when view appears
            busInfoViewModel.fetchBusInfo()
        }
    }
    
    /// Refreshes bus information data with a slight delay for animation
    func refreshData() async {
        // Use Task to call the non-async fetchBusInfo
        await withCheckedContinuation { continuation in
            busInfoViewModel.fetchBusInfo()
            // Minimum delay for a visible refresh animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

struct CustomNavigationHeader: View {
    let busInfoViewModel: BusInfoViewModel
    let onSignOut: () -> Void
    
    var body: some View {
        StandardHeader(
            title: "Runshaw Buses",
            leftAction: StandardHeader.HeaderAction(
                iconName: "rectangle.portrait.and.arrow.right", 
                action: onSignOut
            ),
            rightAction: StandardHeader.HeaderAction(
                iconName: "arrow.clockwise", 
                action: { busInfoViewModel.fetchBusInfo() }
            )
        )
    }
}

/// Empty state view when no buses are available
struct EmptyBusState: View {
    var body: some View {
        StandardEmptyStateView(
            iconName: "bus",
            message: "No buses currently available",
            submessage: "Pull down to refresh",
            actionTitle: "Refresh Now",
            action: {
                // This would trigger a refresh
            }
        )
    }
}

/// List view for displaying available buses and their status
struct BusListView: View {
    /// View model providing bus data
    @ObservedObject var busInfoViewModel: BusInfoViewModel
    
    var body: some View {
        VStack(spacing: Design.Spacing.small) {
            if busInfoViewModel.sortedBusKeys.isEmpty {
                Text("No buses available")
                    .foregroundColor(.red)
                    .padding()
            } else {
                // Bus count indicator
                Text("Total buses: \(busInfoViewModel.sortedBusKeys.count)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 4)
                
                // Bus list
                ForEach(busInfoViewModel.sortedBusKeys, id: \.self) { busNumber in
                    BusStatusRow(
                        busNumber: busNumber,
                        isArrived: busInfoViewModel.isBusArrived(busNumber: busNumber),
                        bay: busInfoViewModel.getBayForBus(busNumber: busNumber),
                        status: busInfoViewModel.getStatusForBus(busNumber: busNumber)
                    )
                    
                    if busInfoViewModel.sortedBusKeys.last != busNumber {
                        Divider()
                    }
                }
            }
        }
        .padding(Design.Spacing.medium)
        .background(Design.Colors.background)
        .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
        .overlay(
            UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                .stroke(Design.Colors.border, lineWidth: 1)
        )
    }
}

/// Information section showing last update time
struct InfoSection: View {
    /// Formatted last updated timestamp
    let lastUpdated: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            Text("Information")
                .font(.system(size: Design.Typography.heading5Size, weight: .semibold))
                .foregroundStyle(Design.Colors.secondary)
            
            VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(Design.Colors.primary)
                    
                    Text("Last updated: \(lastUpdated)")
                        .foregroundStyle(Design.Colors.darkGrey)
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(Design.Colors.primary)
                        
                    Text("Bus information updates automatically")
                        .font(.system(size: 14))
                        .foregroundStyle(Design.Colors.darkGrey)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Design.Spacing.medium)
            .background(Design.Colors.background)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
        }
    }
}

/// Map view for displaying bus lanes layout
struct BusMapView: View {
    /// URL for the map image
    let mapUrl: URL
    
    /// Controls whether map is shown in full-screen mode
    @State private var isFullScreen = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            Text("Bus Lane Map")
                .font(.system(size: Design.Typography.heading5Size, weight: .semibold))
                .foregroundStyle(Design.Colors.secondary)
            
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: mapUrl) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                isFullScreen = true
                            }
                    case .failure:
                        VStack {
                            Image(systemName: "map")
                                .font(.system(size: 40))
                                .foregroundStyle(Design.Colors.darkGrey.opacity(0.5))
                            Text("Map unavailable")
                                .foregroundStyle(Design.Colors.darkGrey)
                        }
                        .frame(maxWidth: .infinity, minHeight: 150)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
                .overlay(
                    UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                        .stroke(Design.Colors.border, lineWidth: 1)
                )
                
                // Expand button
                Button(action: {
                    isFullScreen = true
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .padding(8)
                        .background(Design.Colors.secondary.opacity(0.7))
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }
                .padding(Design.Spacing.small)
            }
        }
        .fullScreenCover(isPresented: $isFullScreen) {
            FullScreenMapView(mapUrl: mapUrl, isPresented: $isFullScreen)
        }
    }
}

/// Row displaying status information for a single bus
struct BusStatusRow: View {
    /// Bus route number/identifier
    let busNumber: String
    
    /// Whether the bus has arrived
    let isArrived: Bool
    
    /// Bay number where the bus is located (optional)
    let bay: String?
    
    /// Status description text
    let status: String
    
    var body: some View {
        HStack(spacing: Design.Spacing.medium) {
            // Bus number with styled background
            Text(busNumber)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Design.Colors.background)
                .frame(minWidth: 50)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(isArrived ? Design.Colors.statusArrived : Design.Colors.statusNotArrived)
                .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
            
            // Status text
            Text(status)
                .font(.system(size: 16))
                .foregroundColor(Design.Colors.text)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Bay information
            if let bay = bay {
                HStack {
                    Text("Bay")
                        .font(.system(size: 14))
                        .foregroundStyle(Design.Colors.darkGrey)
                    
                    Text(bay)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Design.Colors.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Design.Colors.lightGrey)
                        .clipShape(UnevenRoundedRectangle.appStyle(radius: 6))
                }
            } else {
                Text("--")
                    .font(.system(size: 16))
                    .foregroundStyle(Design.Colors.darkGrey)
            }
        }
        .padding(.vertical, Design.Spacing.small)
        .padding(.horizontal, Design.Spacing.small)
        .contentShape(Rectangle())
    }
}

/// Loading overlay displayed during data fetching
struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.1)
                .ignoresSafeArea()
            
            StandardLoadingIndicator()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        // Setup mock services
        let mockNetworkService = MockNetworkService()
        let mockKeychainService = MockKeychainService()
        let mockAuthService = MockAuthService()
        let mockBusInfoService = MockBusInfoService()
        let mockNotificationService = MockNotificationService()
        
        // Configure mock data
        mockKeychainService.setupTestUser()
        
        // Setup sample bus data
        let sampleBusData: [String: BusData] = [
            "115": BusData(status: "Arrived", bay: "T1", id: 1),
            "123": BusData(status: "Arrived", bay: "B3", id: 2),
            "137": BusData(status: "Arrived", bay: "C5", id: 3),
            "142": BusData(status: "Arrived", bay: "A1", id: 4),
            "160": BusData(status: "Not arrived", bay: nil, id: 5)
        ]
        
        mockBusInfoService.setMockBusInfo(busData: sampleBusData)
        
        // Create view models
        let authViewModel = AuthViewModel(
            authService: mockAuthService,
            keychainService: mockKeychainService
        )
        
        let busInfoViewModel = BusInfoViewModel(
            busInfoService: mockBusInfoService
        )
        
        // Add sample notifications
        mockNotificationService.addSampleNotifications()
        
        // Return the HomeView with mock services
        return HomeView(busInfoViewModel: busInfoViewModel)
            .environmentObject(authViewModel)
            .environmentObject(mockNotificationService)
            .preferredColorScheme(.light)
    }
}
#endif
