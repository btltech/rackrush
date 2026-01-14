import Foundation
import os.log

/// Structured logging utility for RackRush
/// Uses os.log for system integration and is silent in release builds
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.rackrush"
    
    // Log categories
    private static let socketLog = OSLog(subsystem: subsystem, category: "Socket")
    private static let gameLog = OSLog(subsystem: subsystem, category: "Game")
    private static let audioLog = OSLog(subsystem: subsystem, category: "Audio")
    private static let networkLog = OSLog(subsystem: subsystem, category: "Network")
    private static let uiLog = OSLog(subsystem: subsystem, category: "UI")
    
    // MARK: - Socket Logging
    
    static func socket(_ message: String, type: OSLogType = .debug) {
        #if DEBUG
        os_log("%{public}@", log: socketLog, type: type, message)
        #endif
    }
    
    static func socketError(_ message: String) {
        os_log("%{public}@", log: socketLog, type: .error, message)
    }
    
    // MARK: - Game Logging
    
    static func game(_ message: String, type: OSLogType = .debug) {
        #if DEBUG
        os_log("%{public}@", log: gameLog, type: type, message)
        #endif
    }
    
    static func gameError(_ message: String) {
        os_log("%{public}@", log: gameLog, type: .error, message)
    }
    
    // MARK: - Audio Logging
    
    static func audio(_ message: String, type: OSLogType = .debug) {
        #if DEBUG
        os_log("%{public}@", log: audioLog, type: type, message)
        #endif
    }
    
    // MARK: - Network Logging
    
    static func network(_ message: String, type: OSLogType = .debug) {
        #if DEBUG
        os_log("%{public}@", log: networkLog, type: type, message)
        #endif
    }
    
    static func networkError(_ message: String) {
        os_log("%{public}@", log: networkLog, type: .error, message)
    }
    
    // MARK: - UI Logging
    
    static func ui(_ message: String, type: OSLogType = .debug) {
        #if DEBUG
        os_log("%{public}@", log: uiLog, type: type, message)
        #endif
    }
    
    // MARK: - Generic Debug (only in DEBUG builds)
    
    static func debug(_ message: String) {
        #if DEBUG
        print("[DEBUG] \(message)")
        #endif
    }
    
    // MARK: - Error (always logged)
    
    static func error(_ message: String, category: String = "General") {
        let log = OSLog(subsystem: subsystem, category: category)
        os_log("%{public}@", log: log, type: .error, message)
    }
    
    // MARK: - Critical (always logged, creates fault)
    
    static func critical(_ message: String) {
        let log = OSLog(subsystem: subsystem, category: "Critical")
        os_log("%{public}@", log: log, type: .fault, message)
    }
}
