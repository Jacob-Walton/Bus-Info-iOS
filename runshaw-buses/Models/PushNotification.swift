//
//  PushNotification.swift
//  runshaw-buses
//
//  Created by Jacob on 03/05/2025.
//  Copyright © 2025 Konpeki. All rights reserved.
//

import Foundation

/// Model for registering a device with the backend notification service
struct DeviceRegistration: Codable {
    /// User identifier for associating notifications with specific user
    let userId: String
    
    /// Device token from APNS for targeting this specific device
    let deviceToken: String
    
    /// Device platform identifier - always "ios" for this app
    let deviceType: String = "ios"
    
    /// Current app version for compatibility tracking
    let appVersion: String
    
    /// Device OS version for compatibility tracking
    let osVersion: String
    
    /// User's notification preference settings
    let notificationSettings: NotificationSettings
}

/// User preferences for notification delivery
struct NotificationSettings: Codable {
    /// Whether to receive notifications about bus arrivals
    var busArrivalNotifications: Bool = true
    
    /// Whether to receive notifications about service updates
    var serviceUpdateNotifications: Bool = true
    
    /// Specific bus numbers the user is interested in receiving notifications about
    var specificBuses: [String] = []
    
    /// Default notification settings for new users
    static var `default`: NotificationSettings {
        return NotificationSettings()
    }
}

/// Model representing a push notification received by the app
struct PushNotification: Identifiable, Codable {
    /// Unique identifier for the notification
    let id: String
    
    /// Notification title
    let title: String
    
    /// Notification body text
    let body: String
    
    /// Timestamp when the notification was received
    let date: Date
    
    /// Type of notification for categorization and filtering
    let type: NotificationType
    
    /// Additional data payload associated with the notification
    let data: [String: String]?
    
    /// Whether the notification has been read by the user
    var isRead: Bool = false
    
    /// Notification category types
    enum NotificationType: String, Codable {
        /// Notification about a bus arrival
        case alert
        
        /// Notification about service changes or issues
        case schedule
        
        /// General notifications not fitting other categories
        case general
    }
    
    /// Initialize a new notification
    /// - Parameters:
    ///   - id: Unique identifier (default: random UUID)
    ///   - title: Notification title
    ///   - body: Notification content
    ///   - date: Timestamp (default: current date)
    ///   - type: Notification category (default: general)
    ///   - data: Optional additional data
    ///   - isRead: Read status (default: false)
    init(id: String = UUID().uuidString, title: String, body: String, date: Date = Date(), 
         type: NotificationType = .general, data: [String: String]? = nil, isRead: Bool = false) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.type = type
        self.data = data
        self.isRead = isRead
    }
}

/// Response from notification device registration endpoint
struct NotificationRegistrationResponse: Codable {
    /// Whether registration was successful
    let success: Bool
    
    /// Status message from server
    let message: String
}
