import SwiftUI
import Combine

// MARK: - Kids Mode Manager
/// Central manager for Kids Mode state, settings, and time tracking
class KidsModeManager: ObservableObject {
    static let shared = KidsModeManager()
    
    // MARK: - Persisted Settings
    @AppStorage("kidsModeEnabled") var isEnabled: Bool = false {
        didSet {
            // Update dictionary mode when kids mode is toggled
            Task { @MainActor in
                LocalDictionary.shared.updateMode(isKids: isEnabled)
            }
        }
    }
    @AppStorage("kidsModeAgeGroup") private var ageGroupRaw: String = AgeGroup.medium.rawValue
    @AppStorage("parentalPIN") private var storedPIN: String = ""
    @AppStorage("dailyTimeLimitMinutes") var dailyTimeLimit: Int = 30
    @AppStorage("todayPlaytimeSeconds") private var todayPlaytime: Int = 0
    @AppStorage("lastPlayDate") private var lastPlayDateString: String = ""
    
    // Online play (requires parental consent)
    @AppStorage("kidsOnlinePlayAllowed") var onlinePlayAllowed: Bool = false
    @AppStorage("kidsOnlinePlayConsentDate") private var onlineConsentDateString: String = ""
    
    // MARK: - Runtime State
    @Published var isUnlocked: Bool = false // Parent unlocked settings
    @Published var showTimeLimitWarning: Bool = false
    @Published var isTimeLimitReached: Bool = false
    @Published var showOnlineConsentDialog: Bool = false
    
    private var playTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Age Groups
    enum AgeGroup: String, CaseIterable, Identifiable {
        case young = "4-6"
        case medium = "7-9"
        case older = "10-12"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .young: return "Ages 4-6 (Easiest)"
            case .medium: return "Ages 7-9 (Easy)"
            case .older: return "Ages 10-12 (Moderate)"
            }
        }
        
        // Gameplay settings per age group
        // All ages get 30s - kids have short attention spans, longer timers = boredom
        // Difficulty comes from letter count and vocabulary, not time
        var timerSeconds: Int {
            return 30  // Same for all age groups
        }
        
        var letterCount: Int {
            switch self {
            case .young: return 5
            case .medium: return 6
            case .older: return 7
            }
        }
        
        var vowelRatio: Double {
            switch self {
            case .young: return 0.50
            case .medium: return 0.40
            case .older: return 0.35
            }
        }
        
        var allowHardLetters: Bool {
            switch self {
            case .young: return false  // No Q, X, Z, J
            case .medium: return false // Rare (handled by rack generation)
            case .older: return true
            }
        }
        
        var minWordLength: Int {
            switch self {
            case .young: return 2
            case .medium: return 3
            case .older: return 3
            }
        }
        
        var roundsPerMatch: Int {
            switch self {
            case .young: return 5
            case .medium: return 5
            case .older: return 7
            }
        }
        
        var botDifficulty: String {
            switch self {
            case .young: return "very_easy"
            case .medium: return "easy"
            case .older: return "medium"
            }
        }
    }
    
    var ageGroup: AgeGroup {
        get { AgeGroup(rawValue: ageGroupRaw) ?? .medium }
        set { 
            objectWillChange.send()  // Fire change notification for UI updates
            ageGroupRaw = newValue.rawValue 
        }
    }
    
    // MARK: - PIN Management
    var hasPIN: Bool { !storedPIN.isEmpty }
    
    func setPIN(_ pin: String) {
        storedPIN = pin
    }
    
    func verifyPIN(_ pin: String) -> Bool {
        guard hasPIN else { return true }
        let isValid = (pin == storedPIN)
        if isValid {
            isUnlocked = true
        }
        return isValid
    }
    
    func lockSettings() {
        isUnlocked = false
    }
    
    // MARK: - Time Tracking
    var remainingTimeMinutes: Int {
        let used = todayPlaytime / 60
        return max(0, dailyTimeLimit - used)
    }
    
    var todayPlaytimeFormatted: String {
        let minutes = todayPlaytime / 60
        let seconds = todayPlaytime % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func startPlaySession() {
        // Stop any existing timer first
        stopPlaySession()
        
        checkDateReset()
        
        guard isEnabled, !isTimeLimitReached else { return }
        
        playTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickPlaytime()
            }
        }
    }
    
    func stopPlaySession() {
        playTimer?.invalidate()
        playTimer = nil
    }
    
    deinit {
        playTimer?.invalidate()
    }
    
    @MainActor
    private func tickPlaytime() {
        todayPlaytime += 1
        
        let remainingSeconds = (dailyTimeLimit * 60) - todayPlaytime
        
        // Warning at 5 minutes remaining
        if remainingSeconds == 300 {
            showTimeLimitWarning = true
        }
        
        // Limit reached
        if remainingSeconds <= 0 {
            isTimeLimitReached = true
            stopPlaySession()
        }
    }
    
    private func checkDateReset() {
        let today = formattedDate(Date())
        if lastPlayDateString != today {
            // New day - reset playtime
            todayPlaytime = 0
            isTimeLimitReached = false
            showTimeLimitWarning = false
            lastPlayDateString = today
        }
    }
    
    @MainActor
    func resetTodayPlaytime() {
        todayPlaytime = 0
        isTimeLimitReached = false
        showTimeLimitWarning = false
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // MARK: - Helpers
    var shouldUseKidsTheme: Bool {
        isEnabled
    }
    
    var effectiveTimerDuration: Int {
        isEnabled ? ageGroup.timerSeconds : 30
    }
    
    /// Can play online (both enabled and consent given)
    var canPlayOnline: Bool {
        isEnabled && onlinePlayAllowed
    }
    
    // MARK: - Online Play Consent
    
    /// Record parental consent for online play
    func grantOnlineConsent() {
        onlinePlayAllowed = true
        onlineConsentDateString = formattedDate(Date())
    }
    
    /// Revoke online play permission
    func revokeOnlineConsent() {
        onlinePlayAllowed = false
        onlineConsentDateString = ""
    }
    
    /// Date when consent was given (for records)
    var onlineConsentDate: Date? {
        guard !onlineConsentDateString.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: onlineConsentDateString)
    }
    
    // MARK: - Matchmaking Data
    
    /// Data to send to server for kids mode matchmaking
    var matchmakingData: [String: Any] {
        guard isEnabled else { return [:] }
        
        return [
            "kidsMode": true,
            "ageGroup": ageGroup.rawValue,
            "timerSeconds": ageGroup.timerSeconds,
            "letterCount": ageGroup.letterCount,
            "minWordLength": ageGroup.minWordLength,
            "roundsPerMatch": ageGroup.roundsPerMatch
        ]
    }
}

// MARK: - Environment Key
struct KidsModeKey: EnvironmentKey {
    static let defaultValue: KidsModeManager = .shared
}

extension EnvironmentValues {
    var kidsMode: KidsModeManager {
        get { self[KidsModeKey.self] }
        set { self[KidsModeKey.self] = newValue }
    }
}
