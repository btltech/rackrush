import Foundation
import SwiftUI

/// Achievement system for tracking player milestones
class AchievementSystem: ObservableObject {
    static let shared = AchievementSystem()
    
    @Published var unlockedAchievements: Set<String> = []
    @Published var recentlyUnlocked: Achievement?
    @Published var showUnlockNotification = false
    
    @AppStorage("unlockedAchievementsData") private var unlockedData: Data = Data()
    
    private init() {
        loadUnlockedAchievements()
    }
    
    // MARK: - Achievement Definitions
    
    static let allAchievements: [Achievement] = [
        // Vocabulary
        Achievement(
            id: "first_word",
            title: "First Steps",
            description: "Submit your first word",
            icon: "text.bubble.fill",
            category: .vocabulary,
            requirement: 1
        ),
        Achievement(
            id: "word_master_100",
            title: "Word Master",
            description: "Submit 100 valid words",
            icon: "book.fill",
            category: .vocabulary,
            requirement: 100
        ),
        Achievement(
            id: "sesquipedalian",
            title: "Sesquipedalian",
            description: "Play a 10+ letter word",
            icon: "text.alignleft",
            category: .vocabulary,
            requirement: 10
        ),
        Achievement(
            id: "lexicon_lord",
            title: "Lexicon Lord",
            description: "Submit 500 valid words",
            icon: "books.vertical.fill",
            category: .vocabulary,
            requirement: 500
        ),
        
        // Speed
        Achievement(
            id: "lightning_round",
            title: "Lightning Round",
            description: "Submit a word in under 5 seconds",
            icon: "bolt.fill",
            category: .speed,
            requirement: 5
        ),
        Achievement(
            id: "speed_demon",
            title: "Speed Demon",
            description: "Win 10 rounds in under 10 seconds each",
            icon: "hare.fill",
            category: .speed,
            requirement: 10
        ),
        Achievement(
            id: "flash_master",
            title: "Flash Master",
            description: "Complete 50 speed rounds (<10s)",
            icon: "flame.fill",
            category: .speed,
            requirement: 50
        ),
        
        // Consistency
        Achievement(
            id: "beginner",
            title: "Beginner",
            description: "Win your first match",
            icon: "star.fill",
            category: .consistency,
            requirement: 1
        ),
        Achievement(
            id: "week_warrior",
            title: "Week Warrior",
            description: "Play 7 days in a row",
            icon: "calendar.badge.clock",
            category: .consistency,
            requirement: 7
        ),
        Achievement(
            id: "month_master",
            title: "Month Master",
            description: "Play 30 days in a row",
            icon: "calendar.badge.checkmark",
            category: .consistency,
            requirement: 30
        ),
        Achievement(
            id: "daily_devotee",
            title: "Daily Devotee",
            description: "Complete 50 daily challenges",
            icon: "sun.max.fill",
            category: .consistency,
            requirement: 50
        ),
        
        // Mastery
        Achievement(
            id: "perfect_game",
            title: "Perfect Game",
            description: "Win all 7 rounds in a match",
            icon: "crown.fill",
            category: .mastery,
            requirement: 7
        ),
        Achievement(
            id: "win_streak_5",
            title: "On Fire",
            description: "Win 5 matches in a row",
            icon: "flame.circle.fill",
            category: .mastery,
            requirement: 5
        ),
        Achievement(
            id: "win_streak_10",
            title: "Unstoppable",
            description: "Win 10 matches in a row",
            icon: "trophy.fill",
            category: .mastery,
            requirement: 10
        ),
        Achievement(
            id: "century_club",
            title: "Century Club",
            description: "Win 100 matches",
            icon: "100.circle.fill",
            category: .mastery,
            requirement: 100
        ),
        Achievement(
            id: "high_scorer",
            title: "High Scorer",
            description: "Score 200+ points in a match",
            icon: "chart.line.uptrend.xyaxis",
            category: .mastery,
            requirement: 200
        ),
        
        // Special
        Achievement(
            id: "bonus_hunter",
            title: "Bonus Hunter",
            description: "Use 50 bonus tiles",
            icon: "sparkles",
            category: .special,
            requirement: 50
        ),
        Achievement(
            id: "comeback_king",
            title: "Comeback King",
            description: "Win after being down 50+ points",
            icon: "arrow.uturn.up.circle.fill",
            category: .special,
            requirement: 50
        ),
        Achievement(
            id: "social_butterfly",
            title: "Social Butterfly",
            description: "Share 10 match results",
            icon: "square.and.arrow.up.fill",
            category: .special,
            requirement: 10
        ),
        Achievement(
            id: "word_wizard",
            title: "Word Wizard",
            description: "Play words starting with every letter A-Z",
            icon: "wand.and.stars",
            category: .special,
            requirement: 26
        ),
        Achievement(
            id: "dictionary_diver",
            title: "Dictionary Diver",
            description: "Look up 100 word definitions",
            icon: "book.pages.fill",
            category: .special,
            requirement: 100
        )
    ]
    
    // MARK: - Public Methods
    
    /// Check and unlock achievements based on event
    func checkAchievements(event: AchievementEvent) {
        let newUnlocks = AchievementSystem.allAchievements.filter { achievement in
            !unlockedAchievements.contains(achievement.id) && achievement.isUnlocked(for: event)
        }
        
        for achievement in newUnlocks {
            unlockAchievement(achievement)
        }
    }
    
    /// Get progress for a specific achievement
    func progress(for achievementId: String, current: Int) -> Double {
        guard let achievement = AchievementSystem.allAchievements.first(where: { $0.id == achievementId }) else {
            return 0
        }
        return min(1.0, Double(current) / Double(achievement.requirement))
    }
    
    /// Get all unlocked achievements
    func getUnlockedAchievements() -> [Achievement] {
        AchievementSystem.allAchievements.filter { unlockedAchievements.contains($0.id) }
    }
    
    /// Get locked achievements
    func getLockedAchievements() -> [Achievement] {
        AchievementSystem.allAchievements.filter { !unlockedAchievements.contains($0.id) }
    }
    
    // MARK: - Private Methods
    
    private func unlockAchievement(_ achievement: Achievement) {
        unlockedAchievements.insert(achievement.id)
        recentlyUnlocked = achievement
        showUnlockNotification = true
        saveUnlockedAchievements()
        
        // Play sound
        AudioManager.shared.playWin()
    }
    
    private func loadUnlockedAchievements() {
        if let decoded = try? JSONDecoder().decode(Set<String>.self, from: unlockedData) {
            unlockedAchievements = decoded
        }
    }
    
    private func saveUnlockedAchievements() {
        if let encoded = try? JSONEncoder().encode(unlockedAchievements) {
            unlockedData = encoded
        }
    }
}

// MARK: - Models

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: Int
    
    func isUnlocked(for event: AchievementEvent) -> Bool {
        switch (id, event) {
        case ("first_word", .wordSubmitted):
            return true
        case ("beginner", .matchWon):
            return true
        case ("lightning_round", .fastWord(let seconds)):
            return seconds < requirement
        case ("sesquipedalian", .longWord(let length)):
            return length >= requirement
        case ("perfect_game", .perfectMatch):
            return true
        case ("high_scorer", .highScore(let score)):
            return score >= requirement
        case ("comeback_king", .comeback(let deficit)):
            return deficit >= requirement
        default:
            return false
        }
    }
}

enum AchievementCategory: String, Codable, CaseIterable {
    case vocabulary = "Vocabulary"
    case speed = "Speed"
    case consistency = "Consistency"
    case mastery = "Mastery"
    case special = "Special"
    
    var color: Color {
        switch self {
        case .vocabulary: return Color(hex: "8B5CF6")
        case .speed: return Color(hex: "F59E0B")
        case .consistency: return Color(hex: "06D6A0")
        case .mastery: return Color(hex: "FFD700")
        case .special: return Color(hex: "EC4899")
        }
    }
}

enum AchievementEvent {
    case wordSubmitted
    case matchWon
    case fastWord(seconds: Int)
    case longWord(length: Int)
    case perfectMatch
    case highScore(score: Int)
    case comeback(deficit: Int)
    case dailyChallengeComplete
    case shareResult
    case definitionLookup
}
