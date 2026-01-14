import Foundation
import SwiftUI

class StatsManager: ObservableObject {
    static let shared = StatsManager()
    
    @Published var wins: Int
    @Published var gamesPlayed: Int
    @Published var currentStreak: Int
    @Published var maxStreak: Int
    @Published var totalScore: Int
    @Published var bestWordScore: Int
    @Published var bestWord: String
    
    private let defaults = UserDefaults.standard
    
    private init() {
        self.wins = defaults.integer(forKey: "stats_wins")
        self.gamesPlayed = defaults.integer(forKey: "stats_gamesPlayed")
        self.currentStreak = defaults.integer(forKey: "stats_currentStreak")
        self.maxStreak = defaults.integer(forKey: "stats_maxStreak")
        self.totalScore = defaults.integer(forKey: "stats_totalScore")
        self.bestWordScore = defaults.integer(forKey: "stats_bestWordScore")
        self.bestWord = defaults.string(forKey: "stats_bestWord") ?? "-"
    }
    
    var winRate: String {
        guard gamesPlayed > 0 else { return "0%" }
        let rate = Double(wins) / Double(gamesPlayed) * 100
        return String(format: "%.0f%%", rate)
    }
    
    func recordGame(won: Bool, score: Int) {
        gamesPlayed += 1
        totalScore += score
        
        if won {
            wins += 1
            currentStreak += 1
            if currentStreak > maxStreak {
                maxStreak = currentStreak
            }
        } else {
            currentStreak = 0
        }
        
        save()
    }
    
    func checkBestWord(word: String, score: Int) {
        if score > bestWordScore {
            bestWordScore = score
            bestWord = word
            save()
        }
    }
    
    private func save() {
        defaults.set(wins, forKey: "stats_wins")
        defaults.set(gamesPlayed, forKey: "stats_gamesPlayed")
        defaults.set(currentStreak, forKey: "stats_currentStreak")
        defaults.set(maxStreak, forKey: "stats_maxStreak")
        defaults.set(totalScore, forKey: "stats_totalScore")
        defaults.set(bestWordScore, forKey: "stats_bestWordScore")
        defaults.set(bestWord, forKey: "stats_bestWord")
    }
}
