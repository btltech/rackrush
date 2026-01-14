import Foundation
import SwiftUI

/// Manages daily challenge state and synchronization
class DailyChallengeManager: ObservableObject {
    static let shared = DailyChallengeManager()
    
    // MARK: - Published State
    
    @Published var todayChallenge: DailyChallenge?
    @Published var hasCompletedToday: Bool = false
    @Published var currentStreak: Int = 0
    @Published var bestScore: Int = 0
    @Published var percentileRank: Double? = nil
    @Published var isLoading: Bool = false
    
    // MARK: - Persistence
    
    @AppStorage("dailyChallengeStreak") private var storedStreak: Int = 0
    @AppStorage("lastChallengeDate") private var lastChallengeDateString: String = ""
    @AppStorage("dailyChallengeBestScore") private var storedBestScore: Int = 0
    
    private init() {
        loadTodayChallenge()
        updateStreak()
    }
    
    // MARK: - Public Methods
    
    /// Load today's challenge
    func loadTodayChallenge() {
        isLoading = true
        
        // Generate deterministic challenge based on date
        let today = Calendar.current.startOfDay(for: Date())
        let challenge = generateChallenge(for: today)
        
        todayChallenge = challenge
        
        // Check if already completed today
        if let lastDate = dateFromString(lastChallengeDateString),
           Calendar.current.isDate(lastDate, inSameDayAs: today) {
            hasCompletedToday = true
        } else {
            hasCompletedToday = false
        }
        
        currentStreak = storedStreak
        bestScore = storedBestScore
        
        isLoading = false
    }
    
    /// Submit a score for today's challenge
    func submitScore(_ score: Int, word: String) {
        guard let _ = todayChallenge, !hasCompletedToday else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        
        // Update completion status
        hasCompletedToday = true
        lastChallengeDateString = stringFromDate(today)
        
        // Update best score if higher
        if score > bestScore {
            bestScore = score
            storedBestScore = score
        }
        
        // Update streak
        updateStreak()
        storedStreak = currentStreak
        
        // Calculate percentile (mock for now - would be server-side in production)
        calculatePercentile(score: score)
        
        // Play success sound
        AudioManager.shared.playWin()
    }
    
    /// Reset for testing
    func resetChallenge() {
        hasCompletedToday = false
        lastChallengeDateString = ""
        bestScore = 0
        storedBestScore = 0
        loadTodayChallenge()
    }
    
    // MARK: - Private Methods
    
    private func generateChallenge(for date: Date) -> DailyChallenge {
        // Use date as seed for deterministic generation
        let daysSince1970 = Int(date.timeIntervalSince1970 / 86400)
        
        // Seed random generator with date
        var generator = SeededRandomGenerator(seed: UInt64(daysSince1970))
        
        // Generate 7 letters with weighted distribution
        let letters = generateLetters(using: &generator)
        
        // Generate bonus tiles
        let bonuses = generateBonuses(using: &generator)
        
        return DailyChallenge(
            id: "daily-\(daysSince1970)",
            date: date,
            letters: letters,
            bonuses: bonuses,
            participantCount: Int.random(in: 1000...5000) // Mock data
        )
    }
    
    private func generateLetters(using generator: inout SeededRandomGenerator) -> [String] {
        // Letter frequency distribution (simplified)
        let commonLetters = ["E", "A", "R", "I", "O", "T", "N", "S"]
        let uncommonLetters = ["L", "C", "U", "D", "P", "M", "H", "G", "B", "F", "Y", "W"]
        let rareLetters = ["K", "V", "X", "Z", "J", "Q"]
        
        var letters: [String] = []
        
        // Ensure at least 3 vowels
        let vowels = ["A", "E", "I", "O", "U"]
        for _ in 0..<3 {
            letters.append(vowels[Int(generator.next() % UInt64(vowels.count))])
        }
        
        // Fill remaining with weighted random
        for _ in 0..<4 {
            let roll = generator.next() % 100
            if roll < 50 {
                letters.append(commonLetters[Int(generator.next() % UInt64(commonLetters.count))])
            } else if roll < 90 {
                letters.append(uncommonLetters[Int(generator.next() % UInt64(uncommonLetters.count))])
            } else {
                letters.append(rareLetters[Int(generator.next() % UInt64(rareLetters.count))])
            }
        }
        
        return letters.shuffled(using: &generator)
    }
    
    private func generateBonuses(using generator: inout SeededRandomGenerator) -> [BonusTile] {
        var bonuses: [BonusTile] = []
        let bonusTypes = ["DL", "TL", "DW"]
        
        // Generate 2-3 bonus tiles
        let count = Int(generator.next() % 2) + 2
        var usedIndices = Set<Int>()
        
        for _ in 0..<count {
            var index: Int
            repeat {
                index = Int(generator.next() % 7)
            } while usedIndices.contains(index)
            
            usedIndices.insert(index)
            let type = bonusTypes[Int(generator.next() % UInt64(bonusTypes.count))]
            bonuses.append(BonusTile(index: index, type: type))
        }
        
        return bonuses
    }
    
    private func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        
        guard let lastDate = dateFromString(lastChallengeDateString) else {
            currentStreak = hasCompletedToday ? 1 : 0
            return
        }
        
        let daysDifference = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
        
        if daysDifference == 0 {
            // Same day - maintain streak
            currentStreak = storedStreak
        } else if daysDifference == 1 {
            // Consecutive day - increment streak
            currentStreak = storedStreak + 1
        } else {
            // Streak broken - reset
            currentStreak = hasCompletedToday ? 1 : 0
        }
    }
    
    private func calculatePercentile(score: Int) {
        // Mock percentile calculation
        // In production, this would be server-side based on all submissions
        let mockScores = [50, 65, 78, 82, 95, 103, 115, 128, 142, 156]
        let betterThanCount = mockScores.filter { $0 < score }.count
        percentileRank = Double(betterThanCount) / Double(mockScores.count) * 100
    }
    
    // MARK: - Date Helpers
    
    private func stringFromDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
    private func dateFromString(_ string: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: string)
    }
}

// MARK: - Models

struct DailyChallenge: Identifiable {
    let id: String
    let date: Date
    let letters: [String]
    let bonuses: [BonusTile]
    let participantCount: Int
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Seeded Random Generator

struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        state = seed
    }
    
    mutating func next() -> UInt64 {
        // Linear congruential generator
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return state
    }
}
