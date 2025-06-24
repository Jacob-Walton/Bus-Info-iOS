//
//  ComingSoon.swift
//  runshaw-buses
//
//  Created by Jacob on 10/06/2025.
//

import SwiftUI

struct ComingSoon: View {
    var title: String = "Coming Soon"
    var icon: String?
    var subtitle: String?
    var feature: String?

    var body: some View {
        VStack(spacing: Design.Spacing.large) {
            // Coming soon card
            VStack(alignment: .center, spacing: Design.Spacing.large) {
                if let iconName = icon {
                    Image(systemName: iconName)
                        .font(.system(size: 60))
                        .foregroundColor(Design.Colors.primary.opacity(0.8))
                }

                VStack(spacing: Design.Spacing.medium) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Design.Colors.secondary)

                    if let subtitleText = subtitle {
                        Text(subtitleText)
                            .font(.system(size: 16))
                            .foregroundColor(Design.Colors.darkGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Design.Spacing.large)
                    }
                }

                if let featureText = feature {
                    // Simple feature indicator
                    HStack(spacing: Design.Spacing.medium) {
                        Image(systemName: "rosette")
                            .foregroundColor(Design.Colors.primary)

                        Text(featureText)
                            .font(.system(size: 16))
                            .foregroundColor(Design.Colors.text)

                        Spacer()
                    }
                    .padding(Design.Spacing.medium)
                    .background(Design.Colors.lightGrey.opacity(0.5))
                    .clipShape(
                        RoundedRectangle(cornerRadius: Design.Layout.buttonRadius)
                    )
                }
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
