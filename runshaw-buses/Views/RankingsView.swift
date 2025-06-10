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

    var body: some View {
        ZStack {
            // Background color
            Design.Colors.lightGrey.ignoresSafeArea()

            VStack(spacing: 0) {
                StandardHeader(
                    title: "Bus Rankings",
                    leftAction: StandardHeader.HeaderAction(
                        iconName: "rectangle.portrait.and.arrow.right",
                        action: {}
                    ),
                    rightAction: StandardHeader.HeaderAction(
                        iconName: "arrow.clockwise",
                        action: {}
                    ))

                // Content area
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero section
                        SharedHeroView(
                            title: "Bus Rankings",
                            subtitle: "Leaderboard coming soon",
                            height: 220
                        )

                        // Coming soon content
                        VStack(spacing: Design.Spacing.large) {
                            // Coming soon card
                            VStack(alignment: .center, spacing: Design.Spacing.large) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(Design.Colors.primary.opacity(0.8))

                                VStack(spacing: Design.Spacing.medium) {
                                    Text("Coming Soon")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(Design.Colors.secondary)

                                    Text(
                                        "We're building a leaderboard to track the best bus routes."
                                    )
                                    .font(.system(size: 16))
                                    .foregroundColor(Design.Colors.darkGrey)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, Design.Spacing.large)
                                }

                                // Simple feature indicator
                                HStack(spacing: Design.Spacing.medium) {
                                    Image(systemName: "rosette")
                                        .foregroundColor(Design.Colors.primary)

                                    Text("Bus performance leaderboard")
                                        .font(.system(size: 16))
                                        .foregroundColor(Design.Colors.text)

                                    Spacer()
                                }
                                .padding(Design.Spacing.medium)
                                .background(Design.Colors.lightGrey.opacity(0.5))
                                .clipShape(
                                    RoundedRectangle(cornerRadius: Design.Layout.buttonRadius))
                            }
                            .padding(Design.Spacing.extraLarge)
                            .frame(maxWidth: .infinity)
                            .background(Design.Colors.background)
                            .clipShape(
                                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                            )
                            .overlay(
                                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                                    .stroke(Design.Colors.border, lineWidth: 1)
                            )
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

#if DEBUG
    /// Preview provider for RankingsView
    struct RankingsView_Previews: PreviewProvider {
        static var previews: some View {
            RankingsView()
                .environmentObject(AuthViewModel.create())
        }
    }
#endif
