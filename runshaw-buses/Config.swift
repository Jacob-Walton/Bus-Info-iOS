import Foundation

/// Environment configuration protocol
protocol EnvironmentConfigurable {
    var baseURL: URL { get }
    var apiTimeout: TimeInterval { get }
    var logLevel: LogLevel { get }
}

/// Log levels for the app
enum LogLevel: String {
    case debug, info, warning, error, none
}

/// Application environment
enum Environment: String, CaseIterable {
    case development
    case staging
    case production
    
    /// Current environment based on build configuration
    static var current: Environment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}

/// Configuration manager
class ConfigurationManager {
    /// Shared instance
    static let shared = ConfigurationManager()

    /// Current active configuration
    private(set) var currentConfig: EnvironmentConfigurable
    
    /// Initlialize with current environment
    private init() {
        // Initialize with a default configuration first
        switch Environment.current {
        case .development:
            currentConfig = DevelopmentConfig()
        case .staging:
            currentConfig = StagingConfig()
        case .production:
            currentConfig = ProductionConfig()
        }
        
        // Then try to load from file and override if successful
        if let fileConfig = loadConfigFromFile() {
            currentConfig = fileConfig
            print("Loaded configuration from file: \(Environment.current.rawValue)")
        }
    }

    /// Load configuration from a file
    private func loadConfigFromFile() -> EnvironmentConfigurable? {
        let filename = "Config-\(Environment.current.rawValue)"
        return loadFromPlist(named: filename)
    }
    
    /// Load configuration from a plist file
    private func loadFromPlist(named filename: String) -> EnvironmentConfigurable? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "plist"),
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return nil
        }
        
        return FileConfig(dictionary: dict)
    }

    /// Override current configuration
    func setConfiguration(_ config: EnvironmentConfigurable) {
        currentConfig = config
    }

    /// Reload configuration from file
    func reloadFromFile() -> Bool {
        if let fileConfig = loadConfigFromFile() {
            currentConfig = fileConfig
            print("Reloaded configuration from file: \(Environment.current.rawValue)")
            return true
        }
        return false
    }
}

/// Configuration loaded from a property list file
struct FileConfig: EnvironmentConfigurable {
    private let dictionary: [String: Any]
    
    init(dictionary: [String: Any]) {
        self.dictionary = dictionary
    }
    
    var baseURL: URL {
        guard let urlString = dictionary["baseURL"] as? String,
              let url = URL(string: urlString) else {
            fatalError("Invalid baseURL in configuration file")
        }
        return url
    }
    
    var apiTimeout: TimeInterval {
        return dictionary["apiTimeout"] as? TimeInterval ?? 30.0
    }
    
    var logLevel: LogLevel {
        guard let levelString = dictionary["logLevel"] as? String,
              let level = LogLevel(rawValue: levelString) else {
            return .info
        }
        return level
    }
}


/// Development configuration
struct DevelopmentConfig: EnvironmentConfigurable {
    var baseURL: URL { URL(string: "https://rb.dev.konpeki.co.uk/api")! }
    var apiTimeout: TimeInterval { 45 }
    var logLevel: LogLevel { .debug }
}

struct StagingConfig: EnvironmentConfigurable {
    var baseURL: URL { URL(string: "https://rb.staging.konpeki.co.uk/api")! }
    var apiTimeout: TimeInterval { 60 }
    var logLevel: LogLevel { .info }
}

struct ProductionConfig: EnvironmentConfigurable {
    var baseURL: URL { URL(string: "https://rb.konpeki.co.uk/api")! }
    var apiTimeout: TimeInterval { 30 }
    var logLevel: LogLevel { .warning }
}
