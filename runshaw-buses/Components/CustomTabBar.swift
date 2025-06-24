import SwiftUI

/// Custom tab bar item configuration
struct TabItem {
    let id: String
    let iconName: String
    let title: String
    let view: AnyView
    
    init<V: View>(id: String, iconName: String, title: String, @ViewBuilder content: () -> V) {
        self.id = id
        self.iconName = iconName
        self.title = title
        self.view = AnyView(content())
    }
}

/// Custom tab bar that matches the app's design system
struct CustomTabBar: View {
    let tabs: [TabItem]
    @Binding var selectedTab: String
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.id) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab.id
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab.id
                    }
                }
            }
        }
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

/// Individual tab bar button with improved styling
struct TabBarButton: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon container with background
                ZStack {
                    // Selected state background
                    if isSelected {
                        UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius)
                            .fill(Design.Colors.primary)
                            .frame(width: 48, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Icon
                    Image(systemName: tab.iconName)
                        .font(.system(size: 18, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : Design.Colors.darkGrey)
                        .scaleEffect(isSelected ? 1.0 : 0.9)
                }
                
                // Label
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? Design.Colors.primary : Design.Colors.darkGrey)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

/// Container view that manages tab navigation with custom tab bar
struct CustomTabNavigationView: View {
    let tabs: [TabItem]
    @State private var selectedTab: String
    
    init(tabs: [TabItem], initialTab: String? = nil) {
        self.tabs = tabs
        self._selectedTab = State(initialValue: initialTab ?? tabs.first?.id ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content area
            ZStack {
                ForEach(tabs, id: \.id) { tab in
                    if selectedTab == tab.id {
                        tab.view
                            .transition(.opacity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom tab bar
            CustomTabBar(tabs: tabs, selectedTab: $selectedTab)
                .background(Design.Colors.lightGrey.ignoresSafeArea(edges: .bottom))
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#if DEBUG
/// Preview provider for CustomTabBar
struct CustomTabBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            CustomTabBar(
                tabs: [
                    TabItem(id: "home", iconName: "house.fill", title: "Home") { Text("Home") },
                    TabItem(id: "rankings", iconName: "trophy.fill", title: "Rankings") { Text("Rankings") },
                    TabItem(id: "settings", iconName: "gearshape.fill", title: "Settings") { Text("Settings") }
                ],
                selectedTab: .constant("home")
            )
        }
        .background(Design.Colors.lightGrey)
        .previewLayout(.sizeThatFits)
    }
}
#endif
