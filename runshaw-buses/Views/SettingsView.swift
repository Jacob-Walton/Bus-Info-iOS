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
    
    @State private var isAddingRoute = false

    var body: some View {
        ZStack {
            Design.Colors.lightGrey.ignoresSafeArea()
            
            VStack(spacing: 0) {
                StandardHeader(title: "Settings")
                
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

                // List of preferred routes
                Text("Your Preferred Routes")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Design.Colors.text)
                
                if preferredRoutes.isEmpty {
                    Text("No routes added yet. Tap below to add.")
                        .font(.system(size: 14))
                        .foregroundColor(Design.Colors.darkGrey)
                        .padding(.vertical, Design.Spacing.tiny)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Design.Spacing.small) {
                            ForEach(preferredRoutes, id: \.self) { route in
                                RouteChip(route: route, onRemove: { removeRoute(route) })
                            }
                        }
                        .padding(.vertical, Design.Spacing.tiny)
                    }
                }

                Button(action: { isAddingRoute = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Preferred Route")
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Design.Colors.primary)
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

    // MARK: - Helper Methods
    private func addRoute(_ route: String) {
        if !preferredRoutes.contains(route) {
            preferredRoutes.append(route)
            preferredRoutes.sort { (Int($0.filter { $0.isNumber }) ?? 0) < (Int($1.filter { $0.isNumber }) ?? 0) }
            // TODO: Save preferredRoutes to UserDefaults or backend
        }
    }

    private func removeRoute(_ route: String) {
        preferredRoutes.removeAll { $0 == route }
        // TODO: Save preferredRoutes to UserDefaults or backend
    }

    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (Build \(build))"
    }
}

/// UI Component for displaying a route with a delete option
struct RouteChip: View {
    let route: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: Design.Spacing.tiny) {
            Text(route)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Design.Colors.background)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Design.Colors.background.opacity(0.7))
            }
        }
        .padding(.horizontal, Design.Spacing.small)
        .padding(.vertical, Design.Spacing.tiny + 2)
        .background(Design.Colors.primary)
        .clipShape(Capsule())
    }
}
