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

private struct AppStyleShape: Shape {
    let radius: CGFloat
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tl: CGFloat = 0
        let tr: CGFloat = radius
        let bl: CGFloat = radius
        let br: CGFloat = 0
        let w = rect.width
        let h = rect.height

        // Start at top-left
        path.move(to: CGPoint(x: 0, y: 0))
        // Top edge
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        // Top-right corner
        if tr > 0 {
            path.addArc(center: CGPoint(x: w - tr, y: tr), radius: tr, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        }
        // Right edge
        path.addLine(to: CGPoint(x: w, y: h - br))
        // Bottom-right corner
        if br > 0 {
            path.addArc(center: CGPoint(x: w - br, y: h - br), radius: br, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        }
        // Bottom edge
        path.addLine(to: CGPoint(x: bl, y: h))
        // Bottom-left corner
        if bl > 0 {
            path.addArc(center: CGPoint(x: bl, y: h - bl), radius: bl, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        }
        // Left edge
        path.addLine(to: CGPoint(x: 0, y: tl))
        // Top-left corner
        if tl > 0 {
            path.addArc(center: CGPoint(x: tl, y: tl), radius: tl, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        }
        path.closeSubpath()
        return path
    }
}

extension UnevenRoundedRectangle {
    static func appStyle(radius: CGFloat) -> some Shape {
        AppStyleShape(radius: radius)
    }
}
