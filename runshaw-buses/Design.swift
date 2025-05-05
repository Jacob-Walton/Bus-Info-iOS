import SwiftUI

/// Design system for the Runshaw Buses application.
/// Contains standardized colors, typography, spacing, and component styles.
struct Design {
    // MARK: - Color Palette
    
    /// Standardized colors used throughout the application
    struct Colors {
        /// Primary brand color - red accent used for key actions and highlights
        static let primary = Color(hex: "#e84430")!
        /// Secondary brand color - dark blue used for headlines and secondary elements
        static let secondary = Color(hex: "#13253c")!
        /// Accent color - alternative red for supplementary UI elements
        static let accent = Color(hex: "#e74c3c")!
        /// Main background color for screens and components
        static let background = Color(hex: "#ffffff")!
        /// Main text color for optimal readability
        static let text = Color(hex: "#333333")!
        /// Light grey for subtle backgrounds and disabled states
        static let lightGrey = Color(hex: "#e9ecef")!
        /// Dark grey for secondary text and icons
        static let darkGrey = Color(hex: "#495057")!
        /// Green color for positive status indicators (bus arrived)
        static let statusArrived = Color(hex: "#28a745")!
        /// Red color for negative status indicators (bus not arrived)
        static let statusNotArrived = Color(hex: "#e74c3c")!
        
        /// Darker variant of the primary color (10% darker) - used for press states
        static let primaryDark = Color(hex: "#d63b27")!
        /// Semi-transparent primary color - used for hover states and backgrounds
        static let primaryHover = Color(primary).opacity(0.1)
        /// Darker variant of the secondary color - used for depth in UI
        static let secondaryDark = Color(hex: "#0c1726")!
        /// Lighter variant of the accent color - used for notifications and backgrounds
        static let accentLight = Color(hex: "#fad7d2")!
        /// Surface color for cards and elevated components
        static let surface = Color(hex: "#e9ecef")!
        /// Border color for dividers and outlines
        static let border = Color(hex: "#dde2e6")!
        /// Shadow color with appropriate opacity for depth
        static let shadowColor = Color.black.opacity(0.1)
        /// Alternative surface color for secondary backgrounds
        static let surfaceAlt = Color(hex: "#f7f7f7")!
    }
    
    // MARK: - Typography System
    
    /// Typography definitions for consistent text styling
    struct Typography {
        /// Available Ubuntu font styles used throughout the app
        enum UbuntuStyle: String {
            case regular = "Ubuntu-Regular"
            case italic = "Ubuntu-Italic"
            case medium = "Ubuntu-Medium"
            case mediumItalic = "Ubuntu-MediumItalic"
            case bold = "Ubuntu-Bold"
            case boldItalic = "Ubuntu-BoldItalic"
            case light = "Ubuntu-Light"
            case lightItalic = "Ubuntu-LightItalic"
        }
        
        /// Font size scale based on 16px base (1rem = 16px)
        static let heading1Size = 2.5 * 16.0 // 40px
        static let heading2Size = 2.0 * 16.0 // 32px
        static let heading3Size = 1.75 * 16.0 // 28px
        static let heading4Size = 1.5 * 16.0 // 24px
        static let heading5Size = 1.25 * 16.0 // 20px
        static let heading6Size = 1.1 * 16.0 // 17.6px
        static let bodySize = 1.0 * 16.0 // 16px
        static let smallSize = 0.875 * 16.0 // 14px
        static let xSmallSize = 0.75 * 16.0 // 12px
    }
    
    // MARK: - Spacing System
    
    /// Standardized spacing values for consistent layout
    struct Spacing {
        /// Base unit for spacing calculations (16px)
        static let unit = 16.0
        
        /// 4px - For very small gaps between elements
        static let tiny = unit * 0.25
        /// 8px - For small padding and margins
        static let small = unit * 0.5
        /// 16px - Default spacing for most UI elements
        static let medium = unit
        /// 24px - For larger separation between sections
        static let large = unit * 1.5
        /// 32px - For significant separation between major components
        static let extraLarge = unit * 2
        /// 48px - For major layout divisions
        static let huge = unit * 3
        
        /// Standard height for navigation bars
        static let navbarHeight = 70.0
    }
    
    // MARK: - Layout Properties
    
    /// Layout specifications for UI components
    struct Layout {
        /// Border radius for buttons (9px)
        static let buttonRadius = 9.0
        /// Border radius for cards and larger components (19px)
        static let regularRadius = 19.0
        
        /// Shadow configuration for dropdown menus
        static let dropdownShadow = Shadow(
            color: Colors.shadowColor,
            radius: 20,
            x: 0,
            y: 4
        )
        
        /// Shadow configuration for card elements
        static let cardShadow = Shadow(
            color: Colors.shadowColor.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        
        /// Default animation timing for transitions
        static let defaultTransition = Animation.easeInOut(duration: 0.3)
    }
    
    // MARK: - Navigation Specifications
    
    /// Styling for navigation components
    struct Navigation {
        /// Standard navigation bar height
        static let height: CGFloat = 70.0
        
        /// Navigation border color
        static let borderColor = Colors.border
        /// Navigation border width
        static let borderWidth: CGFloat = 1.0
        
        /// Standard navigation padding
        static let padding = EdgeInsets(
            top: 0.75 * Spacing.unit,
            leading: Spacing.unit,
            bottom: 0.75 * Spacing.unit,
            trailing: Spacing.unit
        )
    }
    
    // MARK: - Component Specifications
    
    /// Styling specifications for common UI components
    struct Components {
        /// Button styling specifications
        struct Button {
            /// Primary button background color
            static let primaryBackground = Colors.primary
            /// Primary button text color
            static let primaryText = Color.white
            /// Secondary button background color
            static let secondaryBackground = Colors.secondary
            /// Secondary button text color
            static let secondaryText = Color.white
            
            /// Standard button padding
            static let padding = EdgeInsets(
                top: Spacing.small,
                leading: Spacing.medium,
                bottom: Spacing.small,
                trailing: Spacing.medium
            )
            
            /// Standard button corner radius
            static let radius = Layout.buttonRadius
        }
        
        /// Card styling specifications
        struct Card {
            /// Card background color
            static let background = Colors.background
            /// Card border color
            static let border = Colors.border
            /// Card border width
            static let borderWidth: CGFloat = 1.0
            /// Card corner radius
            static let radius = Layout.regularRadius
            /// Standard card padding
            static let padding = EdgeInsets(
                top: Spacing.medium,
                leading: Spacing.medium,
                bottom: Spacing.medium,
                trailing: Spacing.medium
            )
        }
    }
}

// MARK: - Helper Extensions

/// Extension to create Color objects from hex color codes
extension Color {
    /// Initialize a Color from a hex string (e.g. "#FF0000")
    /// - Parameter hex: Hex color string with or without # prefix
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

/// Struct for configuring shadow properties
struct Shadow {
    /// Shadow color with opacity
    let color: Color
    /// Shadow blur radius
    let radius: CGFloat
    /// Shadow x-offset
    let x: CGFloat
    /// Shadow y-offset
    let y: CGFloat
}

/// Extension for applying Ubuntu font styling to Text
extension Text {
    /// Apply Ubuntu font with specific style and size
    /// - Parameters:
    ///   - style: The Ubuntu font style variant to use
    ///   - size: Font size in points
    /// - Returns: Text with specified font applied
    func ubuntuFont(style: Design.Typography.UbuntuStyle, size: CGFloat) -> Text {
        self.font(.custom(style.rawValue, size: size))
    }
}

/// Custom shape for creating rectangles with alternating rounded corners
struct AlternatingRoundedRectangle: Shape {
    /// Corner radius for the rounded corners
    var radius: CGFloat
    
    /// Creates the path for the shape with rounded top-right and bottom-left corners
    /// - Parameter rect: The rectangle within which to draw the shape
    /// - Returns: The path representing the shape
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        
        // Top-left corner (sharp)
        path.move(to: CGPoint(x: 0, y: 0))
        // Top-right corner (rounded)
        path.addLine(to: CGPoint(x: width - radius, y: 0))
        path.addArc(
            center: CGPoint(x: width - radius, y: radius),
            radius: radius,
            startAngle: .degrees(270),
            endAngle: .degrees(0),
            clockwise: false
        )
        
        // Bottom-right corner (sharp)
        path.addLine(to: CGPoint(x: width, y: height))
        
        // Bottom-left corner (rounded)
        path.addLine(to: CGPoint(x: radius, y: height))
        path.addArc(
            center: CGPoint(x: radius, y: height - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )
        
        // Back to start
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        return path
    }
}

// MARK: - View Modifiers

/// Extensions to add design system modifiers to views
extension View {
    /// Apply standardized shadow styling to a view
    /// - Parameter shadow: Shadow configuration to apply
    /// - Returns: View with shadow applied
    func websiteShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    /// Apply standardized card styling to a view
    /// - Returns: View with card styling (background, border, shadow)
    func websiteCard() -> some View {
        self
            .background(Design.Colors.background)
            .clipShape(AlternatingRoundedRectangle(radius: Design.Layout.regularRadius))
            .overlay(
                AlternatingRoundedRectangle(radius: Design.Layout.regularRadius)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
            .websiteShadow(Design.Layout.cardShadow)
    }
    
    /// Apply standardized button styling to a view
    /// - Parameter isPrimary: Whether to use primary (true) or secondary (false) button styling
    /// - Returns: View with button styling (background, foreground, shape)
    func websiteButtonStyle(isPrimary: Bool = true) -> some View {
        self
            .padding(.horizontal, Design.Spacing.medium)
            .padding(.vertical, Design.Spacing.small)
            .background(isPrimary ? Design.Colors.primary : Design.Colors.secondary)
            .foregroundColor(.white)
            .clipShape(AlternatingRoundedRectangle(radius: Design.Layout.buttonRadius))
    }
}
