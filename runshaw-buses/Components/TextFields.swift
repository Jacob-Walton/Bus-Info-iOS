import SwiftUI

/// Defines different types of text fields with appropriate input behaviors
enum TextFieldType {
    /// Standard text field with default behavior
    case text
    /// Email address field with appropriate keyboard and input settings
    case emailAddress
    /// Password field that hides input characters
    case password
    /// Phone number field with appropriate keyboard
    case phoneNumber
    /// URL field with web URL keyboard type
    case url
    /// Numeric field for number input
    case number
    
    /// Whether the field should be secure (password)
    var isSecure: Bool {
        self == .password
    }
    
    /// The keyboard type appropriate for this field
    var keyboardType: UIKeyboardType {
        switch self {
        case .emailAddress: return .emailAddress
        case .phoneNumber: return .phonePad
        case .number: return .numberPad
        case .url: return .URL
        default: return .default
        }
    }
    
    /// The text content type for this field (for autofill suggestions)
    var textContentType: UITextContentType? {
        switch self {
        case .emailAddress: return .emailAddress
        case .password: return .password
        case .phoneNumber: return .telephoneNumber
        case .url: return .URL
        default: return nil
        }
    }
    
    /// The autocapitalization behavior appropriate for this field
    var autocapitalization: UITextAutocapitalizationType {
        switch self {
        case .emailAddress, .password, .url: return .none
        default: return .sentences
        }
    }
}

// Define a ViewModifier for consistent text field styling
struct AppTextFieldStyleModifier: ViewModifier {
    var radius: CGFloat = Design.Layout.textFieldRadius
    var isFocused: Bool = false
    
    // Border color that changes based on focus state
    var borderColor: Color {
        isFocused ? Design.Colors.primary : Design.Colors.border
    }

    func body(content: Content) -> some View {
        content
            .background(Design.Colors.background)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: radius))
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: radius)
                    .stroke(borderColor, lineWidth: isFocused ? 1.5 : 1) // Slightly thicker border when focused
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused) // Smooth transition for focus changes
    }
}

// Extension to easily apply the text field style
fileprivate extension View {
    func appTextFieldStyle(radius: CGFloat = Design.Layout.textFieldRadius, isFocused: Bool = false) -> some View {
        self.modifier(AppTextFieldStyleModifier(radius: radius, isFocused: isFocused))
    }
}

struct AppTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    let type: TextFieldType
    
    // New optional parameters for overriding default behavior
    let autoCapitalization: TextInputAutocapitalization?
    let autocorrectionDisabled: Bool?
    
    // Focus state for this specific text field
    @FocusState private var isFocused: Bool
    
    // Standard internal padding for the text content within the field
    private var textContentPadding: EdgeInsets {
        EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
    }
    
    init(
        label: String,
        placeholder: String,
        text: Binding<String>,
        type: TextFieldType = .text,
        autoCapitalization: TextInputAutocapitalization? = nil,
        autocorrectionDisabled: Bool? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self._text = text
        self.type = type
        self.autoCapitalization = autoCapitalization
        self.autocorrectionDisabled = autocorrectionDisabled
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Design.Colors.darkGrey)
            }
            
            if type.isSecure {
                SecureField(placeholder, text: $text)
                    .focused($isFocused)
                    .padding(textContentPadding)
                    .appTextFieldStyle(isFocused: isFocused)
                    // Apply appropriate content type for password field
                    .textContentType(type.textContentType.map { UITextContentType(rawValue: $0.rawValue) })
            } else {
                HStack(spacing: 0) {
                    TextField(placeholder, text: $text)
                        .focused($isFocused)
                        .padding(EdgeInsets(
                            top: textContentPadding.top,
                            leading: textContentPadding.leading,
                            bottom: textContentPadding.bottom,
                            trailing: text.isEmpty ? textContentPadding.trailing : 0
                        ))
                        // Apply type-specific settings
                        .keyboardType(type.keyboardType)
                        .textContentType(type.textContentType.map { UITextContentType(rawValue: $0.rawValue) })
                        // Use override if provided, otherwise use default from type
                        .textInputAutocapitalization(autoCapitalization ?? TextInputAutocapitalization(type.autocapitalization))
                        // Use override if provided, otherwise determine based on type
                        .autocorrectionDisabled(autocorrectionDisabled ?? (type == .emailAddress || type == .password || type == .url))

                    if !text.isEmpty {
                        Button(action: {
                            self.text = ""
                            // Keep focus on the text field after clearing
                            isFocused = true
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(Color.gray.opacity(0.6))
                                .padding(.horizontal, 8)
                        }
                        .transition(.opacity.combined(with: .scale))
                    }
                }
                .appTextFieldStyle(isFocused: isFocused)
            }
        }
    }
}

// Helper extension to convert UIKit TextInputAutocapitalization to SwiftUI TextInputAutocapitalization
fileprivate extension TextInputAutocapitalization {
    init(_ uiType: UITextAutocapitalizationType) {
        switch uiType {
        case .none: self = .never
        case .words: self = .words
        case .sentences: self = .sentences
        case .allCharacters: self = .characters
        @unknown default: self = .sentences
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

/// Helper function to dismiss the keyboard
private func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
