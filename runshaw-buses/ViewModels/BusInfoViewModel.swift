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
        
        // Print the raw date string for debugging
        print("Attempting to parse date: \(lastUpdated)")
        
        // Try to parse the timestamp from the API format
        let dateFormatter = DateFormatter()
        // Use POSIX locale to ensure consistent parsing regardless of user's region settings
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        // Set the correct format (ISO 8601)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" 
        
        if let date = dateFormatter.date(from: lastUpdated) {
            // Format for display
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .short
            // Use current locale for display formatting
            displayFormatter.locale = Locale.current 
            return displayFormatter.string(from: date)
        } else {
            // Log failure if parsing fails
            print("Failed to parse date string: \(lastUpdated) with format \(dateFormatter.dateFormat ?? "nil")")
        }
        
        // Return the raw string if parsing fails
        return lastUpdated
    }
    
    // Check if a bus has arrived
    func isBusArrived(busNumber: String) -> Bool {
        guard let bus = busData[busNumber], let status = bus.status else {
            print("No status found for bus \(busNumber)")
            return false
        }

        if status.contains("Not Arrived") {
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
