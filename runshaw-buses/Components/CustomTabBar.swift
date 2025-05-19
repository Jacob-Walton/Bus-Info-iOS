import SwiftUI

/// Custom tab bar with styling consistent with the app's design system
struct CustomTabBar: View {
    /// Binding to the selected tab index
    @Binding var selectedTab: Int
    
    /// Array of tab items to display
    let tabs: [TabItem]
    
    /// Tab item definition
    struct TabItem {
        let icon: String
        let title: String
        
        init(icon: String, title: String) {
            self.icon = icon
            self.title = title
        }
    }
    
    var body: some View {
        HStack {
            ForEach(0..<tabs.count, id: \.self) { index in
                Spacer()
                
                tabButton(
                    icon: tabs[index].icon,
                    title: tabs[index].title,
                    isSelected: selectedTab == index,
                    action: { withAnimation(.easeInOut(duration: 0.2)) { selectedTab = index } }
                )
                
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .background(Design.Colors.background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Design.Colors.border),
            alignment: .top
        )
    }
    
    /// Creates a single tab button
    @ViewBuilder
    private func tabButton(icon: String, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Design.Colors.primary : Design.Colors.darkGrey)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? Design.Colors.primary : Design.Colors.darkGrey)
            }
            .frame(minWidth: 60)
        }
    }
}

/// Container view that manages custom tab navigation
struct CustomTabViewContainer<Content: View>: View {
    /// Currently selected tab index
    @Binding var selection: Int
    
    /// Content views for each tab
    let content: Content
    
    init(selection: Binding<Int>, @ViewBuilder content: () -> Content) {
        self._selection = selection
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab content
            TabView(selection: $selection) {
                content
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom tab bar
            CustomTabBar(
                selectedTab: $selection,
                tabs: [
                    .init(icon: "house", title: "Home"),
                    .init(icon: "trophy", title: "Rankings"),
                    .init(icon: "gearshape", title: "Settings")
                ]
            )
            .background(Design.Colors.background)
        }
    }
}

#if DEBUG
/// Preview provider for CustomTabViewContainer
struct CustomTabViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        TabBarPreview()
            .previewLayout(.sizeThatFits)
            .padding()
    }

    struct TabBarPreview: View {
        @State private var selectedTab = 0
        
        var body: some View {
            CustomTabViewContainer(
                selection: $selectedTab
            ) {
                Text("Home Tab")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Design.Colors.lightGrey)
                    .tag(0)
                
                Text("Rankings Tab")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Design.Colors.lightGrey)
                    .tag(1)
                
                Text("Settings Tab")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Design.Colors.lightGrey)
                    .tag(2)
            }
        }
    }
}
#endif