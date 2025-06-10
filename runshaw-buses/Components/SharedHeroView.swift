import SwiftUI

/// Shared hero banner component that can be used across different screens
struct SharedHeroView<AdditionalContent: View>: View {
    /// Main title displayed in the hero
    let title: String
    
    /// Optional subtitle displayed below the title
    let subtitle: String?
    
    /// Height of the hero banner
    let height: CGFloat
    
    /// Optional custom content to display above the title
    let additionalContent: AdditionalContent?
    
    /// Whether to animate the gradient overlay
    let animateGradient: Bool
    
    /// Optional custom padding for the bottom content
    let contentBottomPadding: CGFloat
    
    @State private var isAnimating = false
    
    /// Initialize with required parameters and optional customizations with additional content
    init(
        title: String,
        subtitle: String? = nil,
        height: CGFloat = 220,
        animateGradient: Bool = true,
        contentBottomPadding: CGFloat = 32,
        @ViewBuilder additionalContent: () -> AdditionalContent
    ) {
        self.title = title
        self.subtitle = subtitle
        self.height = height
        self.animateGradient = animateGradient
        self.contentBottomPadding = contentBottomPadding
        self.additionalContent = additionalContent()
    }
    
    /// Initialize without additional content
    init(
        title: String,
        subtitle: String? = nil,
        height: CGFloat = 220,
        animateGradient: Bool = true,
        contentBottomPadding: CGFloat = 32
    ) where AdditionalContent == EmptyView {
        self.title = title
        self.subtitle = subtitle
        self.height = height
        self.animateGradient = animateGradient
        self.contentBottomPadding = contentBottomPadding
        self.additionalContent = nil
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            Image("runshaw")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Design.Colors.secondary.opacity(0.85),
                            Design.Colors.secondary.opacity(0.7),
                            Design.Colors.primary.opacity(animateGradient && isAnimating ? 0.5 : 0.2)
                        ]),
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    )
                    .animation(animateGradient ? Animation.easeInOut(duration: 3).repeatForever(autoreverses: true) : nil, value: isAnimating)
                )
                .clipShape(
                    HeroWave()
                )
                .shadow(color: Design.Colors.shadowColor, radius: 15, x: 0, y: 5)
            
            // Content overlay
            VStack(alignment: .leading, spacing: 4) {
                if let additionalContent = additionalContent {
                    additionalContent
                        .padding(.bottom, 8)
                }
                
                // Main title
                Text(title)
                    .font(.system(size: 38, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 1)
                
                // Optional subtitle
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: Design.Typography.bodySize))
                        .fontWeight(.medium)
                        .foregroundStyle(Color.white)
                }
                
                // Decorative element
                Rectangle()
                    .fill(Design.Colors.primary)
                    .frame(width: 60, height: 4)
                    .padding(.top, 4)
                    .padding(.bottom, 12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, height * 0.25)
        }
        .padding(.bottom, 10)
        .ignoresSafeArea(edges: .horizontal)
        .onAppear {
            if animateGradient {
                withAnimation {
                    isAnimating = true
                }
            }
        }
    }
}

/// Custom hero shape with stylized bottom edge
struct HeroWave: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: width, y: 0))
        path.addLine(to: CGPoint(x: width, y: height - 40))
        
        // Curved bottom edge
        path.addCurve(
            to: CGPoint(x: 0, y: height - 20),
            control1: CGPoint(x: width * 0.75, y: height + 15),
            control2: CGPoint(x: width * 0.25, y: height - 40)
        )
        
        path.closeSubpath()
        return path
    }
}

#if DEBUG
/// Preview for SharedHeroView
struct SharedHeroView_Previews: PreviewProvider {
    static var previews: some View {
        SharedHeroView(
            title: "Welcome Back",
            subtitle: "Check the latest bus arrivals",
            height: 220,
            animateGradient: true,
            contentBottomPadding: 32
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
#endif