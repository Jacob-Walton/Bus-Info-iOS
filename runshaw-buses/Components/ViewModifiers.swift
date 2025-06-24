import SwiftUI

// MARK: - View Modifiers

struct PrimaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Design.Spacing.medium)
            .padding(.vertical, Design.Spacing.small)
            .background(Design.Colors.primary)
            .foregroundStyle(.white)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
    }
}

struct SecondaryButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Design.Spacing.medium)
            .padding(.vertical, Design.Spacing.small)
            .background(Design.Colors.secondary)
            .foregroundStyle(.white)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
    }
}

struct OutlineButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Design.Spacing.medium)
            .padding(.vertical, Design.Spacing.small)
            .background(Design.Colors.background)
            .foregroundStyle(Design.Colors.secondary)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
    }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Design.Spacing.medium)
            .background(Design.Colors.background)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
    }
}

struct TextFieldBorderStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Design.Colors.background)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius)
                    .stroke(Design.Colors.border, lineWidth: 1.5)
            )
    }
}

struct TabBarStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Design.Spacing.medium)
            .padding(.vertical, Design.Spacing.small)
            .background(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                    .fill(Design.Colors.background)
                    .shadow(color: Design.Colors.shadowColor.opacity(0.15), radius: 12, x: 0, y: -4)
            )
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                    .stroke(Design.Colors.border.opacity(0.5), lineWidth: 0.5),
                alignment: .top
            )
            .padding(.horizontal, Design.Spacing.small)
            .padding(.bottom, Design.Spacing.tiny)
    }
}

// MARK: - View Extensions

extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(PrimaryButtonStyle())
    }
    
    func secondaryButtonStyle() -> some View {
        self.modifier(SecondaryButtonStyle())
    }
    
    func outlineButtonStyle() -> some View {
        self.modifier(OutlineButtonStyle())
    }
    
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
    
    func textFieldBorderStyle() -> some View {
        self.modifier(TextFieldBorderStyle())
    }
    
    func tabBarStyle() -> some View {
        self.modifier(TabBarStyle())
    }
    
    /// Standard section title styling
    func sectionTitleStyle() -> some View {
        self.font(.system(size: Design.Typography.heading5Size, weight: .semibold))
            .foregroundStyle(Design.Colors.secondary)
    }
}

// MARK: - Shape Extensions
extension UnevenRoundedRectangle {
    static func appStyle(radius: CGFloat) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            cornerRadii: .init(
                topLeading: 0,
                bottomLeading: radius,
                bottomTrailing: 0,
                topTrailing: radius
                )
        )
    }
}
