import SwiftUI

/// Standard header style used across the app
struct StandardHeader: View {
    /// Title displayed in the header
    let title: String
    
    /// Optional left action button configuration
    let leftAction: HeaderAction?
    
    /// Optional right action button configuration
    let rightAction: HeaderAction?
    
    /// Header action configuration
    struct HeaderAction {
        let iconName: String
        let action: () -> Void
        
        init(iconName: String, action: @escaping () -> Void) {
            self.iconName = iconName
            self.action = action
        }
    }
    
    /// Initialize with optional actions
    init(
        title: String,
        leftAction: HeaderAction? = nil,
        rightAction: HeaderAction? = nil
    ) {
        self.title = title
        self.leftAction = leftAction
        self.rightAction = rightAction
    }
    
    var body: some View {
        HStack {
            if let leftAction = leftAction {
                Button(action: leftAction.action) {
                    Image(systemName: leftAction.iconName)
                        .foregroundStyle(Design.Colors.primary)
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 24, height: 24)
                        .padding(10)
                        .background(Design.Colors.background)
                        .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
                        .overlay(
                            UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius)
                                .stroke(Design.Colors.border, lineWidth: 1)
                        )
                }
                .frame(width: 44)
            } else {
                Spacer().frame(width: 44)
            }
            
            Spacer()
            
            // Title and logo
            HStack(spacing: Design.Spacing.small) {
                Image("logo-full")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(UnevenRoundedRectangle.appStyle(radius: 8))
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Design.Colors.secondary)
            }
            
            Spacer()
            
            if let rightAction = rightAction {
                Button(action: rightAction.action) {
                    Image(systemName: rightAction.iconName)
                        .foregroundStyle(Design.Colors.primary)
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 24, height: 24)
                        .padding(10)
                        .background(Design.Colors.background)
                        .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
                        .overlay(
                            UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius)
                                .stroke(Design.Colors.border, lineWidth: 1)
                        )
                }
                .frame(width: 44)
            } else {
                Spacer().frame(width: 44)
            }
        }
        .padding(.vertical, Design.Spacing.medium)
        .padding(.horizontal, Design.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(Design.Colors.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Design.Colors.border),
            alignment: .bottom
        )
    }
}

/// Standard empty state view
struct StandardEmptyStateView: View {
    /// Icon name from SF Symbols
    let iconName: String
    
    /// Main message to display
    let message: String
    
    /// Optional secondary message
    let submessage: String?
    
    /// Optional action button
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        iconName: String,
        message: String,
        submessage: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.iconName = iconName
        self.message = message
        self.submessage = submessage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: Design.Spacing.medium) {
            Image(systemName: iconName)
                .font(.system(size: 40))
                .foregroundStyle(Design.Colors.darkGrey.opacity(0.6))
            
            Text(message)
                .font(.system(size: Design.Typography.bodySize, weight: .medium))
                .foregroundStyle(Design.Colors.darkGrey)
                .multilineTextAlignment(.center)
                
            if let submessage = submessage {
                Text(submessage)
                    .font(.system(size: 14))
                    .foregroundStyle(Design.Colors.darkGrey)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, Design.Spacing.medium)
                        .padding(.vertical, 8)
                }
                .primaryButtonStyle()
                .padding(.top, Design.Spacing.small)
            }
        }
        .padding(Design.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(Design.Colors.background)
        .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
        .overlay(
            UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                .stroke(Design.Colors.border, lineWidth: 1)
        )
    }
}

/// Standard loading indicator with consistent styling
struct StandardLoadingIndicator: View {
    /// Optional loading message
    let message: String?
    
    /// Whether to show overlay background
    let showBackground: Bool
    
    init(message: String? = "Loading...", showBackground: Bool = true) {
        self.message = message
        self.showBackground = showBackground
    }
    
    var body: some View {
        VStack(spacing: Design.Spacing.medium) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Design.Colors.primary))
            
            if let message = message {
                Text(message)
                    .foregroundStyle(Design.Colors.darkGrey)
                    .font(.system(size: 16, weight: .medium))
            }
        }
        .padding(Design.Spacing.large)
        .background(showBackground ? Design.Colors.background.opacity(0.9) : Color.clear)
        .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
        .shadow(color: showBackground ? Design.Colors.shadowColor : Color.clear, radius: 15, x: 0, y: 5)
    }
}

#Preview {
    StandardHeader(
        title: "Runshaw Buses",
        leftAction: StandardHeader.HeaderAction(
            iconName: "rectangle.portrait.and.arrow.right",
            action: {}
        ),
        rightAction: StandardHeader.HeaderAction(
            iconName: "arrow.clockwise",
            action: {}
        )
    )
    Spacer()
}
