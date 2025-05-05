import SwiftUI

struct AppTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    
    init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Design.Colors.darkGrey)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldBorderStyle()
            } else {
                TextField(placeholder, text: $text)
                    .textFieldBorderStyle()
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
            }
        }
    }
}

struct CustomCheckbox: View {
    var isChecked: Bool
    
    var body: some View {
        ZStack {
            // Background and border
            UnevenRoundedRectangle(
                cornerRadii: .init(
                    topLeading: 0,
                    bottomLeading: 4,
                    bottomTrailing: 0,
                    topTrailing: 4
                )
            )
            .strokeBorder(
                isChecked ? Design.Colors.primary : Design.Colors.border,
                lineWidth: 2
            )
            .background(
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 0,
                        bottomLeading: 4,
                        bottomTrailing: 0,
                        topTrailing: 4
                    )
                )
                .fill(isChecked ? Design.Colors.primary : Design.Colors.background)
            )
            .frame(width: 18, height: 18)
            
            // Inner white square (not checkmark) when checked
            if isChecked {
                UnevenRoundedRectangle(
                    cornerRadii: .init(
                        topLeading: 0,
                        bottomLeading: 2,
                        bottomTrailing: 0,
                        topTrailing: 2
                    )
                )
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .transition(
                    .asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    )
                )
            }
        }
        .contentShape(Rectangle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isChecked)
    }
}

struct RememberMeRow: View {
    @Binding var isChecked: Bool
    
    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isChecked.toggle()
                }
            }) {
                HStack(spacing: 8) {
                    CustomCheckbox(isChecked: isChecked)
                    
                    Text("Remember me")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Design.Colors.text)
                }
            }
            
            Spacer()
            
            Button(action: {
                // Handle forgot password
            }) {
                Text("Forgot password?")
                    .font(.system(size: 13))
                    .foregroundColor(Design.Colors.primary)
            }
        }
    }
}
