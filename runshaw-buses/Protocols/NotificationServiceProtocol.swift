import UserNotifications


protocol NotificationServiceProtocol: UNUserNotificationCenterDelegate {
    // MARK: - Published Properties
    var notifications: [PushNotification] { get }
    var unreadCount: Int { get }
    var hasPermission: Bool { get }
    var settings: NotificationSettings { get }

    // MARK: - Permission Management
    func requestPermission()
    func checkNotificationPermission()

    // MARK: - Device Token Management
    func registerDeviceToken(_ deviceToken: Data)

    // MARK: - Notification Handling
    func addNotification(_ notification: PushNotification)
    func markAsRead(_ id: String)
    func markAllAsRead()
    func updateSettings(_ newSettings: NotificationSettings)
}
