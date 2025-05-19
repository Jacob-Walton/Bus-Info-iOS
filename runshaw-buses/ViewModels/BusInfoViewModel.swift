import Combine
import Foundation
import SwiftUI

class BusInfoViewModel: ObservableObject {
    /// Published properties for UI updates
    @Published var busData: [String: BusData] = [:]
    @Published var lastUpdated: String?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var mapUrl: URL?
    @Published var filterText: String = ""  // For filtering bus data

    /// Bus routes for picker (abstract this to the SettingsView later)
    @Published var availableBusRotues: [String] = []
    @Published var isLoadingRoutes: Bool = false
    @Published var routesError: String?

    private var allSortedBusKeys: [String] = []  // Stores all bus keys, sorted, before filtering
    private var busInfoService: BusInfoServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 60  // Refresh every minute

    /// Initialize the view model with a bus info service
    /// - Parameter busInfoService: The service to fetch bus data
    init(busInfoService: BusInfoServiceProtocol) {
        self.busInfoService = busInfoService

        // Initial fetch
        fetchBusInfo()

        // Set up a timer to refresh the bus data every minute
        setupRefreshTimer()

        // Update bus map
        updateBusMap()

        #if DEBUG
            // Log the map URL for debugging
            print("Current map URL: \(mapUrl?.absoluteString ?? "No URL")")
        #endif

        // Observe changes to filterText and update available bus routes
        $filterText
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateFilteredBusKeys()
            }
            .store(in: &cancellables)

        // Fetch available bus routes
        fetchAvailableBusRoutes()
    }

    deinit {
        // Invalidate the timer when the view model is deallocated
        refreshTimer?.invalidate()
    }

    /// Set up a timer to refresh bus data periodically
    func setupRefreshTimer() {
        refreshTimer?.invalidate()  // Invalidate any existing timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) {
            [weak self] _ in
            self?.fetchBusInfo()
        }
    }

    /// Fetch latest bus map URL (with token query parameter)
    func updateBusMap() {
        do {
            try mapUrl = busInfoService.getMapUrl()
        } catch NetworkError.unauthorized {
            print("Failed to fetch map URL: Unauthorized")
        } catch {
            print("Unexpected error when trying to fetch map URL: \(error.localizedDescription)")
        }
    }

    /// Fetch bus data from the service
    func fetchBusInfo() {
        isLoading = true
        error = nil

        #if DEBUG
            print("Fetching bus info...")
        #endif

        busInfoService.fetchBusInfo()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoading = false

                    if case .failure(let error) = completion {
                        if case .unauthorized = error {
                            self.error = "Unauthorized access. Please log in again."
                        } else if case .decodingError = error {
                            #if DEBUG
                                print("Decoding error: \(error.localizedDescription)")
                            #endif

                            self.error = "Error processing server response. Please try again later."
                        } else {
                            #if DEBUG
                                print(
                                    "Failed to load bus information: \(error.localizedDescription)")
                            #endif

                            self.error = "Failed to load bus information. Please try again later."
                        }
                    }
                },
                receiveValue: { [weak self] response in
                    guard let self = self else { return }

                    #if DEBUG
                        print("Received bus data with \(response.busData.count) entries.")
                    #endif

                    self.busData = response.busData
                    self.lastUpdated = response.lastUpdated
                    self.error = nil

                    // Sort bus keys and store them
                    let sorted = response.busData.keys.sorted { (lhs, rhs) -> Bool in
                        // Try to sort numerically first
                        if let leftNum = Int(lhs.filter { $0.isNumber }),
                            let rightNum = Int(rhs.filter { $0.isNumber })
                        {
                            return leftNum < rightNum
                        }

                        // If not numeric, sort alphabetically
                        return lhs < rhs
                    }

                    #if DEBUG
                        print("Setting allSortedBusKeys to \(sorted.count) entries.")
                    #endif

                    self.allSortedBusKeys = sorted

                    // Force update of UI
                    DispatchQueue.main.async {
                        self.updateFilteredBusKeys()
                        #if DEBUG
                            print("Keys set: \(self.allSortedBusKeys)")
                        #endif

                        // Update map URL
                        self.updateBusMap()

                        // Force a UI refresh
                        self.objectWillChange.send()
                    }
                }
            )
            .store(in: &cancellables)
    }

    /// Updates `sortedBusKeys` based on the current filter text
    private func updateFilteredBusKeys() {
        if filterText.isEmpty {
            // If no filter, show all sorted bus keys
            filteredBusKeys = allSortedBusKeys
        } else {
            // Filter the bus keys based on the filter text
            filteredBusKeys = allSortedBusKeys.filter {
                $0.localizedCaseInsensitiveContains(filterText)
            }
        }
    }

    /// The total number of buses fetched, before any filtering
    /// - Returns: The total number of buses
    var allBusKeysCount: Int {
        return busData.count
    }

    /// Format the last updated time
    /// - Returns: A formatted string representing the last updated time
    func formattedLastUpdated() -> String {
        guard let lastUpdated = lastUpdated else {
            return "Unknown"
        }

        // First try with ISO8601DateFormatter
        let isoFormatter = ISO8601DateFormatter()
        var date: Date?

        // Try to parse the date with ISO formatter (preserving time zone)
        date = isoFormatter.date(from: lastUpdated)

        // If that fails, try custom formatters
        if date == nil {
            let customFormatter = [
                "yyyy-MM-dd'T'HH:mm:ss'Z'",
                "yyyy-MM-dd'T'HH:mm:ssZ",
                "yyyy-MM-dd'T'HH:mm:ss"
            ]

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

            for format in customFormatter {
                dateFormatter.dateFormat = format
                if let parsedDate = dateFormatter.date(from: lastUpdated) {
                    date = parsedDate
                    break
                }
            }
        }

        // If we have valid date, format it for display in user's local time zone
        if let date = date {
            // Create a new date formatter for display
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            timeFormatter.timeZone = TimeZone.current // Set to user's local time zone
            let timeString = timeFormatter.string(from: date)

            // Use calendar with user's timezone for "today"/"yesterday" calculation
            var userCalendar = Calendar.current
            userCalendar.timeZone = TimeZone.current

            if userCalendar.isDateInToday(date) {
                return "Today at \(timeString)"
            } else if userCalendar.isDateInYesterday(date) {
                return "Yesterday at \(timeString)"
            } else {
                // Format the date to include the day of the week
                let weekdayFormatter = DateFormatter()
                weekdayFormatter.dateFormat = "EEEE 'at' HH:mm:ss"
                weekdayFormatter.timeZone = TimeZone.current
                let weekdayString = weekdayFormatter.string(from: date)
                return weekdayString
            }
        }

        #if DEBUG
            print("Failed to parse last updated date: \(lastUpdated)")
        #endif

        // Return raw string if parsing fails
        return lastUpdated
    }

    /// Check if a bus has arrived
    /// - Parameter busNumber: The bus number to check
    /// - Returns: `true` if the bus has arrived, `false` otherwise
    func isBusArrived(busNumber: String) -> Bool {
        guard let bus = busData[busNumber], let status = bus.status else {
            #if DEBUG
                print("Bus \(busNumber) not found or status is nil.")
            #endif
            return false
        }

        if status.contains("Not arrived") {
            return false
        }

        return true
    }

    /// Get bay information for a bus
    /// - Parameter busNumber: The bus number to check
    /// - Returns: The bay information for the bus, or `nil` if not found
    func getBayForBus(busNumber: String) -> String? {
        return busData[busNumber]?.bay
    }

    /// Get status text for a bus
    /// - Parameter busNumber: The bus number to check
    /// - Returns: The status text for the bus, or "Unknown" if not found
    func getStatusText(busNumber: String) -> String? {
        guard let bus = busData[busNumber] else {
            #if DEBUG
                print("Bus \(busNumber) not found.")
            #endif
            return "Unknown"
        }

        // Return the status text or "Unknown" if nil
        return bus.status ?? "Unknown"
    }

    /// Fetch available bus routes from the API
    func fetchAvailableBusRoutes() {
        isLoadingRoutes = true
        routesError = nil

        busInfoService.getBusRoutes()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    guard let self = self else { return }
                    self.isLoadingRoutes = false

                    if case .failure(let error) = completion {
                        if case .unauthorized = error {
                            self.routesError = "Unauthorized access. Please log in again."
                        } else {
                            #if DEBUG
                                print("Failed to load bus routes: \(error.localizedDescription)")
                            #endif

                            self.routesError = "Failed to load bus routes. Please try again later."
                        }
                    }
                },
                receiveValue: { [weak self] routes in
                    guard let self = self else { return }
                    
                    #if DEBUG
                        print("Received \(routes.count) bus routes.")
                    #endif

                    // Sort the routes
                    let sorted = routes.sorted { (lhs, rhs) -> Bool in
                        // Try to sort numerically first
                        if let leftNum = Int(lhs.filter { $0.isNumber }),
                            let rightNum = Int(rhs.filter { $0.isNumber })
                        {
                            return leftNum < rightNum
                        }

                        // If not numeric, sort alphabetically
                        return lhs < rhs
                    }

                    #if DEBUG
                        print("Setting available bus routes to \(sorted.count) entries.")
                    #endif

                    self.availableBusRotues = sorted
                }
            )
            .store(in: &cancellables)
    }
}

// MARK: - Factory Method

extension BusInfoViewModel {
    /// Factory method to create an instance of `BusInfoViewModel`
    /// - Returns: A new instance of `BusInfoViewModel`
    static func create() -> BusInfoViewModel {
        let busInfoService = BusInfoService.create()
        return BusInfoViewModel(busInfoService: busInfoService)
    }
}