//
//  RankingsView.swift
//  runshaw-buses
//
//  Created by Jacob on 03/05/2025.
//  Copyright © 2025 Konpeki. All rights reserved.
//

import SwiftUI

/// Placeholder view for the upcoming Bus Rankings feature
struct RankingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var busInfoViewModel: BusInfoViewModel

    var body: some View {
        ZStack {
            // Background color
            Design.Colors.lightGrey.ignoresSafeArea()

            VStack(spacing: 0) {
                StandardHeader(
                    title: "Bus Rankings",
                    leftAction: StandardHeader.HeaderAction(
                        iconName: "rectangle.portrait.and.arrow.right",
                        action: {
                            authViewModel.signOut()
                        }
                    ),
                    rightAction: StandardHeader.HeaderAction(
                        iconName: "arrow.clockwise",
                        action: {
                            busInfoViewModel.fetchBusRankings()
                        }
                    )
                )

                // Content area
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section
                        SharedHeroView(
                            title: "Bus Rankings",
                            subtitle: heroSubtitle,
                            height: 220
                        )

                        // Rankings content
                        VStack(spacing: Design.Spacing.medium) {
                            if busInfoViewModel.isLoadingRankings {
                                // Loading state
                                VStack(spacing: Design.Spacing.medium) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                    Text("Loading rankings...")
                                        .font(.system(size: 16))
                                        .foregroundColor(Design.Colors.darkGrey)
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .padding()
                            } else if let error = busInfoViewModel.rankingsError {
                                // Error state
                                VStack(spacing: Design.Spacing.large) {
                                    ErrorBanner(message: error)
                                        .padding(.horizontal, Design.Spacing.medium)
                                    
                                    VStack(spacing: Design.Spacing.medium) {
                                        AppButton(title: "Retry") {
                                            busInfoViewModel.fetchBusRankings()
                                        }
                                        .padding(.horizontal, Design.Spacing.medium)
                                    }
                                }
                                .padding(.top, Design.Spacing.medium)
                            } else if !busInfoViewModel.isLoadingRankings && busInfoViewModel.busRankings.isEmpty {
                                // Empty state - only show when we've finished loading and have no data
                                VStack(spacing: Design.Spacing.medium) {
                                    Image(systemName: "tray.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(Design.Colors.darkGrey.opacity(0.7))
                                    Text("No Rankings Available")
                                        .font(.system(size: Design.Typography.heading5Size, weight: .semibold))
                                        .foregroundColor(Design.Colors.text)
                                    Text("There are currently no bus rankings to display. Please check back later or try refreshing.")
                                        .font(.system(size: 16))
                                        .foregroundColor(Design.Colors.darkGrey)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, Design.Spacing.large)
                                }
                                .frame(maxWidth: .infinity, minHeight: 200)
                                .padding(Design.Spacing.large)
                            } else {
                                // Success state with data
                                VStack(spacing: Design.Spacing.large) {
                                    // Podium for top 3
                                    if busInfoViewModel.busRankings.count >= 3 {
                                        ContentPanel(title: "Top Performers", iconName: "trophy.fill") {
                                            PodiumView(rankings: Array(busInfoViewModel.busRankings.prefix(3)))
                                        }
                                        .padding(.horizontal, Design.Spacing.medium)
                                    }
                                    
                                    // Complete rankings list
                                    ContentPanel(title: "Complete Rankings", iconName: "list.number") {
                                        VStack(spacing: Design.Spacing.small) {
                                            ForEach(busInfoViewModel.busRankings, id: \.service) { ranking in
                                                CompactRankingCard(ranking: ranking)
                                                
                                                if ranking.service != busInfoViewModel.busRankings.last?.service {
                                                    Divider()
                                                        .padding(.horizontal, Design.Spacing.small)
                                                }
                                            }
                                        }
                                        .padding(.vertical, Design.Spacing.small)
                                        .animation(.easeInOut(duration: 0.3), value: busInfoViewModel.busRankings)
                                    }
                                    .padding(.horizontal, Design.Spacing.medium)
                                }
                                .padding(.vertical, Design.Spacing.large)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Trigger initial load of rankings when view appears
            if busInfoViewModel.busRankings.isEmpty && !busInfoViewModel.isLoadingRankings && busInfoViewModel.rankingsError == nil {
                busInfoViewModel.fetchBusRankings()
            }
        }
    }

    /// Computed property for hero subtitle that properly handles all states
    private var heroSubtitle: String {
        if busInfoViewModel.isLoadingRankings {
            return "Loading..."
        } else if busInfoViewModel.rankingsError != nil {
            return "Error loading rankings"
        } else if !busInfoViewModel.isLoadingRankings && busInfoViewModel.busRankings.isEmpty {
            return "No rankings available"
        } else {
            return "Updated \(busInfoViewModel.formattedRankingsLastUpdated())"
        }
    }
}

struct PodiumView: View {
    let rankings: [BusRanking]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: Design.Spacing.medium) {
            // 2nd place (left)
            if rankings.count > 1 {
                PodiumPosition(ranking: rankings[1], height: 75)
            }
            
            // 1st place (center, tallest)
            if rankings.count > 0 {
                PodiumPosition(ranking: rankings[0], height: 100)
            }
            
            // 3rd place (right)
            if rankings.count > 2 {
                PodiumPosition(ranking: rankings[2], height: 50)
            }
        }
        .padding(.vertical, Design.Spacing.large)
    }
}

struct PodiumPosition: View {
    let ranking: BusRanking
    let height: CGFloat
    
    private var podiumColor: Color {
        switch ranking.rank {
        case 1: return Color(hex: "#FFD700")! // Gold
        case 2: return Color(hex: "#C0C0C0")! // Silver
        case 3: return Color(hex: "#CD7F32")! // Bronze
        default: return Design.Colors.darkGrey // Fallback, though rank should be 1, 2, or 3 here
        }
    }
    
    private var podiumIconName: String {
        switch ranking.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "rosette"
        default: return "questionmark.circle.fill" // Fallback
        }
    }
    
    var body: some View {
        VStack(spacing: Design.Spacing.small) {
            // Icon and service info
            VStack(spacing: 4) {
                Image(systemName: podiumIconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(podiumColor)
                
                Text(ranking.service)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Design.Colors.text)
                
                Text("\(ranking.score)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Design.Colors.darkGrey)
            }
            
            // Podium base
            VStack(spacing: 0) {
                Text("\(ranking.rank)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Rectangle()
                    .fill(podiumColor)
                    .frame(width: 70, height: height)
                    .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
            }
        }
    }
}

struct CompactRankingCard: View {
    let ranking: BusRanking

    var body: some View {
        HStack(spacing: Design.Spacing.medium) {
            // Rank badge
            Text("\(ranking.rank)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(rankColor)
                .clipShape(UnevenRoundedRectangle.appStyle(radius: 6))
            
            // Service name
            VStack(alignment: .leading, spacing: 2) {
                Text("Bus \(ranking.service)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Design.Colors.text)
                
                if ranking.rank <= 3 {
                    HStack(spacing: 4) {
                        Image(systemName: medalIcon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(medalColor)
                        
                        Text(positionText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(medalColor)
                    }
                }
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(ranking.score)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Design.Colors.secondary)
                
                Text("points")
                    .font(.system(size: 12))
                    .foregroundColor(Design.Colors.darkGrey)
            }
        }
        .padding(.horizontal, Design.Spacing.medium)
        .padding(.vertical, Design.Spacing.small)
    }

    private var rankColor: Color {
        switch ranking.rank {
        case 1: return Color(hex: "#FFD700")! // Gold
        case 2: return Color(hex: "#C0C0C0")! // Silver
        case 3: return Color(hex: "#CD7F32")! // Bronze
        default: return Design.Colors.darkGrey
        }
    }
    
    private var medalIcon: String {
        switch ranking.rank {
        case 1: return "crown.fill"
        case 2: return "medal.fill"
        case 3: return "rosette"
        default: return ""
        }
    }
    
    private var medalColor: Color {
        switch ranking.rank {
        case 1: return Color(hex: "#FFD700")! // Gold
        case 2: return Color(hex: "#C0C0C0")! // Silver
        case 3: return Color(hex: "#CD7F32")! // Bronze
        default: return Design.Colors.darkGrey
        }
    }
    
    private var positionText: String {
        switch ranking.rank {
        case 1: return "1st Place"
        case 2: return "2nd Place"
        case 3: return "3rd Place"
        default: return ""
        }
    }
}

#if DEBUG
    /// Preview provider for RankingsView
    struct RankingsView_Previews: PreviewProvider {
        static var previews: some View {
            RankingsView()
                .environmentObject(AuthViewModel.create())
                .environmentObject(BusInfoViewModel.create())
        }
    }
#endif
