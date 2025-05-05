import SwiftUI

struct AppButton: View {
    enum ButtonType {
        case primary
        case secondary
        case outline
    }
    
    let title: String
    let type: ButtonType
    let isLoading: Bool
    let action: () -> Void
    
    init(
        title: String,
        type: ButtonType = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.type = type
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint:
                            type == .outline ? Design.Colors.secondary : .white))
                        .scaleEffect(0.8)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .opacity(isLoading ? 0.7 : 1)
            .applyButtonStyle(for: type)
        }
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

extension View {
    @ViewBuilder
    func applyButtonStyle(for type: AppButton.ButtonType) -> some View {
        switch type {
        case .primary:
            self.primaryButtonStyle()
        case .secondary:
            self.secondaryButtonStyle()
        case .outline:
            self.outlineButtonStyle()
        }
    }
}

struct SocialSignInButton: View {
    let iconName: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .outlineButtonStyle()
    }
}

struct IconTextButton: View {
    let iconName: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(Design.Colors.primary)
        }
    }
}

#Preview {
    VStack {
        VStack {
            HStack {
                AppButton(title: "Hello World", type: .primary, action: { })
                AppButton(title: "Hello World", type: .secondary, action: { })
                AppButton(title: "Hello World", type: .outline, action: { })
            }
            HStack {
                SocialSignInButton(iconName: "microsoft-logo", label: "Microsoft", action: { })
                SocialSignInButton(iconName: "google-logo", label: "Google", action: { })
            }
        }
        .padding(Design.Spacing.medium)
        .websiteCard()
    }
    .padding(Design.Spacing.medium)
}
