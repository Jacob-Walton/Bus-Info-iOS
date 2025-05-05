import SwiftUI

struct GradientDivider: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.clear,
                Design.Colors.border.opacity(0.5),
                Design.Colors.border.opacity(0.5),
                Color.clear
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
    }
}


struct DividerWithText: View {
    let text: String
    
    var body: some View {
        HStack {
            GradientDivider()
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Design.Colors.darkGrey)
            GradientDivider()
        }
        .padding(.vertical, Design.Spacing.medium)
    }
}
