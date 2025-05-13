import SwiftUI

/// Settings view for configuring app preferences and account options
struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var notificationService: NotificationService
    
    /// Use StateObject with a default value as a fallback if environment object is missing
    @StateObject private var fallbackBusInfoViewModel = BusInfoViewModel.create()
    
    /// Optional environment object that might not be provided
    @EnvironmentObject private var injectedBusInfoViewModel: BusInfoViewModel
    
    /// Computed property to use injected view model if available, fallback otherwise
    private var busInfoViewModel: BusInfoViewModel {
        let mirror = Mirror(reflecting: self)
        // Check if environment object was actually injected by seeing if it's initialized
        if mirror.children.contains(where: { $0.label == "_injectedBusInfoViewModel" && $0.value as? BusInfoViewModel != nil }) {
            return injectedBusInfoViewModel
        } else {
            print("Warning: Using fallback BusInfoViewModel because none was injected via environment")
            return fallbackBusInfoViewModel
        }
    }
    
    // Settings state
    @State private var enableNotifications = true // TODO: Link to actual notificationService.isSubscribed or similar
    @State private var showPreferredRoutesSeparately = true // TODO: Implement persistence and logic
    @State private var preferredRoutes: [String] = ["809", "819", "821"] // TODO: Load from user preferences
    
    // New states for improved route selection
    @State private var routeSearchText = ""
    @State private var showRoutesSection = false
    
    // Add back missing state variable
    @State private var isAddingRoute = false
    
    var body: some View {
        ZStack {
            Design.Colors.lightGrey.ignoresSafeArea()
            
            VStack(spacing: 0) {
                StandardHeader(title: "Settings",
                               leftAction: StandardHeader.HeaderAction(
                                   iconName: "rectangle.portrait.and.arrow.right",
                                   action: { }
                               ),
                               rightAction: StandardHeader.HeaderAction(
                                   iconName: "checkmark.circle",
                                   action: { }
                               ))
                
                ScrollView {
                    VStack(spacing: 0) {
                        SharedHeroView(
                            title: "Settings",
                            subtitle: "Customize your app experience",
                            height: 220
                        )
                        
                        VStack(spacing: Design.Spacing.large) {
                            preferredRoutesSection
                            notificationsSection
                            accountSection
                            aboutSection
                        }
                        .padding(.horizontal, Design.Spacing.medium)
                        .padding(.top, Design.Spacing.medium)
                        .padding(.bottom, Design.Spacing.extraLarge)
                    }
                }
            }
        }
        .sheet(isPresented: $isAddingRoute) {
            routePickerSheet
        }
    }

    // MARK: - Section Views

    private var preferredRoutesSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            Text("Preferred Bus Routes")
                .font(.system(size: Design.Typography.heading5Size, weight: .semibold))
                .foregroundStyle(Design.Colors.secondary)

            VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                // Toggle for showing preferred routes separately
                HStack {
                    VStack(alignment: .leading) {
                        Text("Show Preferred Routes Separately")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.text)
                        Text("Highlights your chosen routes in the main list.")
                             .font(.system(size: 14))
                             .foregroundColor(Design.Colors.darkGrey)
                    }
                    Spacer()
                    Toggle("", isOn: $showPreferredRoutesSeparately)
                        .labelsHidden()
                        .tint(Design.Colors.primary)
                }

                Divider()

                // Selected routes summary and expand button
                VStack(spacing: 0) {
                    Button(action: {
                        hideKeyboard() // Hide keyboard when toggling
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showRoutesSection.toggle()
                            // Load routes if expanded and needed
                            if showRoutesSection && busInfoViewModel.availableBusRoutes.isEmpty {
                                busInfoViewModel.fetchAvailableBusRoutes()
                            }
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Select Your Preferred Routes")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Design.Colors.text)
                                
                                Text(preferredRoutes.isEmpty ? 
                                     "No routes selected" : 
                                     "\(preferredRoutes.count) routes selected")
                                    .font(.system(size: 14))
                                    .foregroundColor(Design.Colors.darkGrey)
                            }
                            
                            Spacer()
                            
                            Image(systemName: showRoutesSection ? "chevron.up" : "chevron.down")
                                .foregroundColor(Design.Colors.darkGrey)
                                .frame(width: 20, height: 20)
                                .background(
                                    Circle()
                                        .fill(Color.clear)
                                        .frame(width: 30, height: 30)
                                )
                                .rotationEffect(.degrees(showRoutesSection ? 0 : 180))
                                .animation(.spring(response: 0.3), value: showRoutesSection)
                        }
                        .contentShape(Rectangle())
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Expandable routes selection section
                    if showRoutesSection {
                        VStack(spacing: Design.Spacing.small) {
                            // Search field with clear button
                            AppTextField(
                                label: "",
                                placeholder: "Search routes...",
                                text: $routeSearchText,
                                type: .text,
                                autoCapitalization: .never,
                                autocorrectionDisabled: true
                            )
                            .padding(.top, 6)
                            
                            // Loading or Content
                            Group {
                                if busInfoViewModel.isLoadingRoutes {
                                    HStack {
                                        Spacer()
                                        ProgressView()
                                            .padding()
                                        Spacer()
                                    }
                                } else {
                                    let filteredRoutes = busInfoViewModel.availableBusRoutes
                                        .filter { routeSearchText.isEmpty || $0.localizedCaseInsensitiveContains(routeSearchText) }
                                        .sorted()
                                    
                                    if filteredRoutes.isEmpty {
                                        VStack(spacing: Design.Spacing.small) {
                                            if !routeSearchText.isEmpty {
                                                Text("No matching routes found")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Design.Colors.darkGrey)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                                    .padding()
                                            } else if busInfoViewModel.availableBusRoutes.isEmpty {
                                                Text("No bus routes available")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Design.Colors.darkGrey)
                                                    .frame(maxWidth: .infinity, alignment: .center)
                                                    .padding()
                                            }
                                        }
                                        .frame(height: 100)
                                    } else {
                                        routeListView(routes: filteredRoutes)
                                    }
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                        .padding(.top, Design.Spacing.small)
                    }
                }
            }
            .padding(Design.Spacing.medium)
            .background(Design.Colors.background)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.25), value: showRoutesSection)
        }
    }
    
    // Optimized route list view with ScrollView instead of List
    private func routeListView(routes: [String]) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(routes, id: \.self) { route in
                        routeToggleRow(route: route)
                        
                        if route != routes.last {
                            Divider()
                                .padding(.leading, Design.Spacing.medium)
                        }
                    }
                }
            }
            .frame(height: min(300, CGFloat(routes.count * 44)))
        }
        .background(Design.Colors.background)
        .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius))
        .overlay(
            UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius)
                .stroke(Design.Colors.border, lineWidth: 0.5)
        )
    }
    
    // Helper view for route toggle row
    private func routeToggleRow(route: String) -> some View {
        let isSelected = preferredRoutes.contains(route)
        
        return Button(action: {
            // Use haptic feedback for selection
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            
            withAnimation(.easeInOut(duration: 0.2)) {
                toggleRoute(route)
                generator.impactOccurred()
            }
        }) {
            HStack {
                Text("Bus \(route)")
                    .font(.system(size: 16))
                    .foregroundColor(Design.Colors.text)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(isSelected ? Design.Colors.primary : Design.Colors.darkGrey.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Design.Colors.primary)
                            .frame(width: 14, height: 14)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .contentShape(Rectangle())
            .padding(.vertical, 12)
            .padding(.horizontal, Design.Spacing.medium)
            .background(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.buttonRadius)
                    .fill(isSelected ? Design.Colors.primary.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            Text("Notifications")
                .font(.system(size: Design.Typography.heading5Size, weight: .semibold))
                .foregroundStyle(Design.Colors.secondary)

            VStack(alignment: .leading, spacing: Design.Spacing.medium) {
                HStack {
                     VStack(alignment: .leading) {
                        Text("Push Notifications")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.text)
                        Text("Receive alerts for your preferred routes.")
                             .font(.system(size: 14))
                             .foregroundColor(Design.Colors.darkGrey)
                    }
                    Spacer()
                    Toggle("", isOn: $enableNotifications)
                        .labelsHidden()
                        .tint(Design.Colors.primary)
                }
            }
            .padding(Design.Spacing.medium)
            .background(Design.Colors.background)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
        }
    }

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            Text("Account")
                .font(.system(size: Design.Typography.heading5Size, weight: .semibold))
                .foregroundStyle(Design.Colors.secondary)

            VStack(alignment: .leading, spacing: 0) {
                if let user = authViewModel.currentUser {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(Design.Colors.primary)
                            .frame(width: 24, alignment: .center)
                        Text(user.email)
                            .font(.system(size: 16))
                            .foregroundColor(Design.Colors.text)
                        Spacer()
                    }
                    .padding(Design.Spacing.medium)
                    Divider()
                }

                // Change Password
                Button(action: { /* TODO: Navigate to change password screen */ }) {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(Design.Colors.primary)
                            .frame(width: 24, alignment: .center)
                        Text("Change Password")
                            .font(.system(size: 16))
                            .foregroundColor(Design.Colors.text)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(Design.Colors.darkGrey.opacity(0.7))
                    }
                }
                .padding(Design.Spacing.medium)
                
                // TODO: Add sign out button after adding primaryDestructive type
            }
            .background(Design.Colors.background)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Design.Spacing.small) {
            Text("About & Legal")
                .font(.system(size: Design.Typography.heading5Size, weight: .semibold))
                .foregroundStyle(Design.Colors.secondary)

            VStack(alignment: .leading, spacing: 0) {
                aboutRow(icon: "envelope.fill", text: "support@konpeki.co.uk", isLink: true, action: {
                    // Open email client
                    UIApplication.shared.open(URL(string: "mailto:support@konpeki.co.uk")!)
                })
                Divider()
                aboutRow(icon: "doc.text.fill", text: "Privacy Policy", isLink: true, action: { /* TODO: Open Privacy Policy URL */ })
                Divider()
                aboutRow(icon: "newspaper.fill", text: "Terms of Service", isLink: true, action: { /* TODO: Open Terms URL */ })
                Divider()
                
                // Independence Disclaimer
                VStack(alignment: .leading, spacing: Design.Spacing.tiny) {
                    HStack {
                        Image(systemName: "shield.lefthalf.filled")
                             .foregroundColor(Design.Colors.primary)
                             .frame(width: 24, alignment: .center)
                        Text("Independence Disclaimer")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Design.Colors.text)
                    }
                    Text("This app is an independent project and is not affiliated with, endorsed, or sponsored by Runshaw College.")
                        .font(.system(size: 14))
                        .foregroundColor(Design.Colors.darkGrey)
                        .padding(.leading, 24 + Design.Spacing.medium) // Align with text above
                }
                .padding(Design.Spacing.medium)
                Divider()

                // App Version
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Design.Colors.primary)
                        .frame(width: 24, alignment: .center)
                    Text("Version")
                        .font(.system(size: 16))
                        .foregroundColor(Design.Colors.text)
                    Spacer()
                    Text(getAppVersion())
                        .font(.system(size: 16))
                        .foregroundColor(Design.Colors.darkGrey)
                }
                .padding(Design.Spacing.medium)
            }
            .background(Design.Colors.background)
            .clipShape(UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius))
            .overlay(
                UnevenRoundedRectangle.appStyle(radius: Design.Layout.regularRadius)
                    .stroke(Design.Colors.border, lineWidth: 1)
            )
        }
    }

    @ViewBuilder
    private func aboutRow(icon: String, text: String, isLink: Bool = false, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Design.Colors.primary)
                    .frame(width: 24, alignment: .center)
                Text(text)
                    .font(.system(size: 16))
                    .foregroundColor(isLink ? Design.Colors.primary : Design.Colors.text)
                Spacer()
                if isLink {
                    Image(systemName: "arrow.up.right.square")
                        .foregroundColor(Design.Colors.darkGrey.opacity(0.7))
                }
            }
        }
        .disabled(action == nil)
        .padding(Design.Spacing.medium)
    }
    
    private var routePickerSheet: some View {
        NavigationView {
            List {
                if busInfoViewModel.isLoadingRoutes {
                    HStack {
                        ProgressView()
                            .padding(.trailing, 10)
                        Text("Loading available routes...")
                    }
                } else if let error = busInfoViewModel.routesError {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else {
                    Section(header: Text("Available Routes")) {
                        ForEach(busInfoViewModel.availableBusRoutes.filter { !preferredRoutes.contains($0) }, id: \.self) { route in
                            Button(action: {
                                addRoute(route)
                                isAddingRoute = false
                            }) {
                                HStack {
                                    Text("Bus \(route)")
                                        .foregroundColor(Design.Colors.text)
                                    Spacer()
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(Design.Colors.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Preferred Route")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isAddingRoute = false
                    }
                    .foregroundColor(Design.Colors.primary)
                }
            }
            .onAppear {
                // Refresh routes when the picker appears
                if busInfoViewModel.availableBusRoutes.isEmpty {
                    busInfoViewModel.fetchAvailableBusRoutes()
                }
            }
        }
    }

    // Add back the addRoute function (now uses toggleRoute)
    private func addRoute(_ route: String) {
        if !preferredRoutes.contains(route) {
            toggleRoute(route)
        }
    }

    // Updated toggle method that handles both adding and removing
    private func toggleRoute(_ route: String) {
        if preferredRoutes.contains(route) {
            preferredRoutes.removeAll { $0 == route }
        } else {
            preferredRoutes.append(route)
            preferredRoutes.sort()
        }
        // TODO: Save preferredRoutes to UserDefaults or backend
    }

    // MARK: - Helper Methods
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (Build \(build))"
    }
    
    // Add helper function to hide keyboard
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
