import Foundation
import Combine
import SwiftUI

class BusInfoViewModel: ObservableObject {
    // Published properties for UI updates
    @Published var busData: [String: BusData] = [:]
    @Published var lastUpdated: String?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var sortedBusKeys: [String] = []
    @Published var mapUrl: URL?
    
    private var busInfoService: BusInfoServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 60 // Refresh every minute
    
    init(busInfoService: BusInfoServiceProtocol) {
        self.busInfoService = busInfoService
        
        // Initial fetch
        fetchBusInfo()
        
        // Set up auto-refresh
        setupRefreshTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    func setupRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.fetchBusInfo()
        }
    }
    
    func fetchBusInfo() {
        isLoading = true
        error = nil
        
        print("Fetching bus info...")
        
        busInfoService.getBusInfo()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                
                if case .failure(let error) = completion {
                    if case .unauthorized = error {
                        self.error = "Authorization failed. Please sign in again."
                    } else if case .decodingError = error {
                        self.error = "Error processing server response. Please try again later."
                        print("Decoding error: \(error.localizedDescription)")
                    } else {
                        self.error = "Failed to load bus information: \(error.localizedDescription)"
                    }
                }
            } receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // Debug the received data
                print("Received bus data with \(response.busData.count) buses")
                
                self.busData = response.busData
                self.lastUpdated = response.lastUpdated
                self.error = nil
                
                // Sort bus numbers for consistent display
                let sorted = response.busData.keys.sorted { (lhs, rhs) -> Bool in
                    // Try to sort numerically if possible
                    if let leftNum = Int(lhs.filter { $0.isNumber }),
                       let rightNum = Int(rhs.filter { $0.isNumber }) {
                        return leftNum < rightNum
                    }
                    // Otherwise sort alphabetically
                    return lhs < rhs
                }
                
                print("Setting sorted keys to \(sorted.count) buses")
                
                // Force update on main thread and ensure UI refreshes
                DispatchQueue.main.async {
                    self.sortedBusKeys = sorted
                    print("Keys set: \(self.sortedBusKeys.count)")
                    
                    // Force a UI refresh
                    self.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }

    // Format the last updated timestamp into a readable string
    func formattedLastUpdated() -> String {
        guard let lastUpdated = lastUpdated else {
            return "Unknown"
        }
        
        // First try with ISO8601DateFormatter which handles timezone properly
        let isoFormatter = ISO8601DateFormatter()
        var date: Date?
        
        // Try to parse the date with ISO formatter (preserves timezone info)
        date = isoFormatter.date(from: lastUpdated)
        
        // If that fails, try custom formatters as fallback
        if date == nil {
            let customFormatters = [
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss"
            ]
            
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
            
            for format in customFormatters {
                dateFormatter.dateFormat = format
                if let parsedDate = dateFormatter.date(from: lastUpdated) {
                    date = parsedDate
                    break
                }
            }
        }
        
        // If we have a valid date, format it for display in user's timezone
        if let date = date {
            let calendar = Calendar.current
            
            // Create time formatter using user's timezone
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            timeFormatter.timeZone = TimeZone.current  // User's local timezone
            let timeString = timeFormatter.string(from: date)
            
            // Use calendar with user's timezone for proper "today"/"yesterday" calculations
            var userCalendar = Calendar.current
            userCalendar.timeZone = TimeZone.current
            
            if userCalendar.isDateInToday(date) {
                return "Today at \(timeString)"
            } else if userCalendar.isDateInYesterday(date) {
                return "Yesterday at \(timeString)"
            } else {
                let fullFormatter = DateFormatter()
                fullFormatter.dateStyle = .medium
                fullFormatter.timeStyle = .none
                fullFormatter.timeZone = TimeZone.current  // User's local timezone
                return "\(fullFormatter.string(from: date)) at \(timeString)"
            }
        }
        
        #if DEBUG
        print("Failed to parse date string: \(lastUpdated)")
        #endif
        
        // Return the raw string if all parsing attempts fail
        return lastUpdated
    }
    
    // Check if a bus has arrived
    func isBusArrived(busNumber: String) -> Bool {
        guard let bus = busData[busNumber], let status = bus.status else {
            print("No status found for bus \(busNumber)")
            return false
        }

        if status.contains("Not arrived") {
            return false
        }
        
        return true
    }
    
    // Get bay information for a bus
    func getBayForBus(busNumber: String) -> String? {
        return busData[busNumber]?.bay
    }
    
    // Get status text for a bus
    func getStatusForBus(busNumber: String) -> String {
        guard let bus = busData[busNumber] else {
            print("No bus data found for \(busNumber)")
            return "Unknown"
        }
        
        // Return status if present, otherwise "Unknown"
        return bus.status ?? "Unknown"
    }
}

// MARK: - Factory Method

extension BusInfoViewModel {
    static func create() -> BusInfoViewModel {
        return BusInfoViewModel(
            busInfoService: BusInfoService.create()
        )
    }
}
