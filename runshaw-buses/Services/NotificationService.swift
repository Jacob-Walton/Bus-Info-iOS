import Foundation
import UserNotifications
import UIKit
import Combine

class NotificationService: NSObject, NotificationServiceProtocol, ObservableObject {
    // MARK: - Published Properties
    @Published var notifications: [PushNotification] = []
    @Published var unreadCount: Int = 0
    @Published var hasPermission: Bool = false
    @Published var settings: NotificationSettings = .default
    
    // MARK: - Shared Instance
    static let shared: any NotificationServiceProtocol & ObservableObject = NotificationService()
    
    // MARK: - Private Properties
    private let keychainService: KeychainServiceProtocol
    private let networkService: NetworkServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol = NetworkService.create(),
         keychainService: KeychainServiceProtocol = KeychainService.shared) {
        self.networkService = networkService
        self.keychainService = keychainService
        super.init()
        
        // Set delegate for notification center
        UNUserNotificationCenter.current().delegate = self
        
        // Load persisted data
        loadSettings()
        loadNotifications()
        
        // Check permission status
        checkNotificationPermission()
        
        // Listen for device token notifications
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleDeviceTokenNotification(_:)),
            name: Notification.Name("ReceivedDeviceToken"), object: nil)
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions from the user
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                
                if granted {
                    // Register with APNs if we have permission
                    UIApplication.shared.registerForRemoteNotifications()
                } else if let error = error {
                    print("Permission request error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Check current notification permission status
    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Device Token Management
    
    /// Handle device token received from AppDelegate
    @objc private func handleDeviceTokenNotification(_ notification: Notification) {
        guard let deviceToken = notification.userInfo?["deviceToken"] as? Data else { return }
        registerDeviceToken(deviceToken)
    }
    
    /// Register device token with backend
    func registerDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        guard let userId = keychainService.getCurrentUser()?.id,
              !userId.isEmpty else {
            print("Cannot register device: No user logged in")
            return
        }
        
        let registration = DeviceRegistration(
            userId: userId,
            deviceToken: tokenString,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            osVersion: UIDevice.current.systemVersion,
            notificationSettings: settings
        )
        
        guard let jsonData = try? JSONEncoder().encode(registration) else {
            print("Failed to encode device registration")
            return
        }
        
        networkService.request(
            endpoint: "api/notifications/register",
            method: .post,
            body: jsonData
        )
        .sink(receiveCompletion: { completion in
            if case .failure(let error) = completion {
                print("Failed to register device: \(error)")
            }
        }, receiveValue: { (response: NotificationRegistrationResponse) in
            print("Device registration response: \(response.message)")
        })
        .store(in: &cancellables)
    }
    
    // MARK: - UNUserNotificationCenterDelegate Methods
    
    /// Handle incoming notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               willPresent notification: UNNotification,
                               withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        handleNotification(userInfo: userInfo)
        
        // Show the notification even if app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    /// Handle notification when app opened from notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                               didReceive response: UNNotificationResponse,
                               withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleNotification(userInfo: userInfo, wasOpened: true)
        completionHandler()
    }
    
    // MARK: - Notification Handling
    
    /// Process notification payload
    private func handleNotification(userInfo: [AnyHashable: Any], wasOpened: Bool = false) {
        // Print the raw payload for debugging
        print("Received userInfo: \(userInfo)")
        
        // Extract standard APS data
        guard let aps = userInfo["aps"] as? [String: Any],
              let alert = aps["alert"] as? [String: Any],
              let title = alert["title"] as? String,
              let body = alert["body"] as? String else {
            print("Invalid APS notification format")
            return
        }
        
        // Extract custom data from root level
        let id = userInfo["id"] as? String ?? UUID().uuidString
        let typeString = userInfo["notificationType"] as? String ?? PushNotification.NotificationType.general.rawValue
        let type = PushNotification.NotificationType(rawValue: typeString) ?? .general
        
        var data: [String: String]? = nil
        if let customData = userInfo["data"] as? [String: String] {
            data = customData
        }
        
        // Create notification object
        let notification = PushNotification(
            id: id,
            title: title, // From aps.alert
            body: body,   // From aps.alert
            date: Date(),
            type: type,   // From root
            data: data,   // From root
            isRead: false
        )
        
        // Add to list and update counter
        addNotification(notification)
    }
    
    /// Add notification to the list
    func addNotification(_ notification: PushNotification) {
        DispatchQueue.main.async {
            self.notifications.insert(notification, at: 0)
            self.unreadCount += 1
            self.saveNotifications()
        }
    }
    
    /// Mark notification as read
    func markAsRead(_ id: String) {
        DispatchQueue.main.async {
            if let index = self.notifications.firstIndex(where: { $0.id == id }) {
                if !self.notifications[index].isRead {
                    self.notifications[index].isRead = true
                    self.unreadCount = max(0, self.unreadCount - 1)
                    self.saveNotifications()
                }
            }
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead() {
        DispatchQueue.main.async {
            for i in 0..<self.notifications.count {
                self.notifications[i].isRead = true
            }
            self.unreadCount = 0
            self.saveNotifications()
        }
    }
    
    /// Update notification settings
    func updateSettings(_ newSettings: NotificationSettings) {
        settings = newSettings
        saveSettings()
        
        // Re-register device with new settings
        if let userId = keychainService.getCurrentUser()?.id,
           !userId.isEmpty {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    /// Clear all badge notifications without marking notifications as read
    /// This is used when the app becomes active to reset the badge count
    func clearBadges() {
        DispatchQueue.main.async {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("Failed to clear badge count: \(error)")
                } else {
                    print("Successfully cleared badge count")
                }
            }
        }
    }
    
    // MARK: - Persistence Methods
    
    private func saveNotifications() {
        do {
            let data = try JSONEncoder().encode(Array(notifications.prefix(100))) // Limit saved notifications
            UserDefaults.standard.set(data, forKey: "savedNotifications")
            UserDefaults.standard.set(unreadCount, forKey: "unreadCount")
        } catch {
            print("Error saving notifications: \(error)")
        }
    }
    
    private func loadNotifications() {
        guard let data = UserDefaults.standard.data(forKey: "savedNotifications") else { return }
        do {
            let savedNotifications = try JSONDecoder().decode([PushNotification].self, from: data)
            notifications = savedNotifications
        } catch {
            print("Error loading notifications: \(error)")
            // Clear potentially corrupted data
            UserDefaults.standard.removeObject(forKey: "savedNotifications")
            UserDefaults.standard.removeObject(forKey: "unreadCount")
            notifications = []
            unreadCount = 0
        }
    }
    
    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: "notificationSettings")
        } catch {
            print("Error saving settings: \(error)")
        }
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: "notificationSettings") else { return }
        do {
            let savedSettings = try JSONDecoder().decode(NotificationSettings.self, from: data)
            settings = savedSettings
        } catch {
            print("Error loading settings: \(error)")
            UserDefaults.standard.removeObject(forKey: "notificationSettings")
            settings = .default // Reset to default if loading fails
        }
    }
}

// MARK: - Factory Method for Dependency Injection

extension NotificationService {
    /// Create a notification service with configuration from the environment
    static func create() -> any NotificationServiceProtocol & ObservableObject {
        return NotificationService.shared
    }
}

// MARK: - Mock Notification Service for Testing

#if DEBUG
// TODO: Implement the mock service properly
class MockNotificationService: NSObject, NotificationServiceProtocol, ObservableObject {
    // MARK: - Published Properties
    @Published var notifications: [PushNotification] = []
    @Published var unreadCount: Int = 0
    @Published var hasPermission: Bool = true
    @Published var settings: NotificationSettings = .default
    
    // MARK: - Initialization
    override init() {
        super.init()
    }
    
    // MARK: - Test Setup Methods
    
    /// Add sample notifications for testing
    func addSampleNotifications() {
        let types: [PushNotification.NotificationType] = [.general, .schedule, .alert]
        
        for i in 0..<5 {
            let type = types[i % types.count]
            let notification = PushNotification(
                id: UUID().uuidString,
                title: "Test Notification \(i+1)",
                body: "This is a test notification for \(type.rawValue)",
                date: Date().addingTimeInterval(-Double(i * 3600)),
                type: type,
                data: ["key": "value\(i)"],
                isRead: i > 2 // First 3 are unread
            )
            
            addNotification(notification)
        }
    }
    
    /// Mock receiving a push notification
    func simulatePushNotification(title: String, body: String, type: PushNotification.NotificationType = .general, data: [String: String]? = nil) {
        let notification = PushNotification(
            id: UUID().uuidString,
            title: title,
            body: body,
            date: Date(),
            type: type,
            data: data,
            isRead: false
        )
        
        addNotification(notification)
    }
    
    // MARK: - Permission Management
    
    func requestPermission() {
        // Always succeed in mock
        DispatchQueue.main.async {
            self.hasPermission = true
        }
    }
    
    func checkNotificationPermission() {
        // No-op in mock
    }
    
    // MARK: - Device Token Management
    
    func registerDeviceToken(_ deviceToken: Data) {
        print("[MOCK] Registered device token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
        // No actual registration in mock
    }
    
    // MARK: - Notification Handling
    
    func addNotification(_ notification: PushNotification) {
        DispatchQueue.main.async {
            var mutableNotification = notification
            if !mutableNotification.isRead {
                self.unreadCount += 1
            }
            self.notifications.insert(mutableNotification, at: 0)
        }
    }
    
    func markAsRead(_ id: String) {
        DispatchQueue.main.async {
            if let index = self.notifications.firstIndex(where: { $0.id == id }) {
                if !self.notifications[index].isRead {
                    self.notifications[index].isRead = true
                    self.unreadCount = max(0, self.unreadCount - 1)
                }
            }
        }
    }
    
    func markAllAsRead() {
        DispatchQueue.main.async {
            for i in 0..<self.notifications.count {
                self.notifications[i].isRead = true
            }
            self.unreadCount = 0
        }
    }
    
    func updateSettings(_ newSettings: NotificationSettings) {
        settings = newSettings
    }
    
    /// Clear all badge notifications without marking notifications as read
    func clearBadges() {
        print("[MOCK] Cleared badge count")
    }
    
    // MARK: - UNUserNotificationCenterDelegate stubs
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.banner, .sound, .badge])
        } else {
            completionHandler([.alert, .sound, .badge])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
}
#endif
