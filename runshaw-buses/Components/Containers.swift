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
                    .font(.system(size: Design.Typography.heading5Size, weight: .semibold))
                    .foregroundStyle(Design.Colors.secondary)
            }
            
            content
                .cardStyle()
        }
    }
}

struct ErrorBanner: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.system(size: 14))
            .foregroundColor(Design.Colors.accent)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Design.Colors.accentLight)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
            .padding(.bottom, Design.Spacing.small)
    }
}
