import SwiftUI

struct FormSection<Content: View>: View {
    let spacing: CGFloat
    let content: Content
    
    init(
        spacing: CGFloat = Design.Spacing.medium * 0.75,
        @ViewBuilder content: () -> Content
    ) {
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            content
        }
    }
}

struct SectionContainer<Content: View>: View {
    let title: String?
    let content: Content
    
    init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            if let title = title {
                Text(title)
                    .sectionTitleStyle()
            }
            
            content
                .cardStyle()
        }
    }
}

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: Design.Spacing.small) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(Design.Colors.accent)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(Design.Colors.accent)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Design.Colors.accentLight)
        .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
        .padding(.bottom, Design.Spacing.small)
    }
}

/// Standardized panel for content sections
struct ContentPanel<Content: View>: View {
    let title: String
    let iconName: String?
    let content: Content
    
    init(title: String, iconName: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.iconName = iconName
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            // Header with optional icon
            HStack(spacing: Design.Spacing.small) {
                if let iconName = iconName {
                    Image(systemName: iconName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Design.Colors.primary)
                }
                
                Text(title)
                    .sectionTitleStyle()
            }
            
            // Content with consistent styling
            content
                .cardStyle()
        }
    }
}
