import Foundation

/// Local Bot Player for offline gameplay
/// Matches server-side BotPlayer.ts logic
class LocalBotPlayer {
    enum Difficulty: String, CaseIterable {
        case veryEasy = "very_easy"
        case easy = "easy"
        case medium = "medium"
        case hard = "hard"
    }
    
    let id: String
    let name: String
    let difficulty: Difficulty
    
    /// Bot delays (seconds) - faster for adults, they don't want to wait
    private let delays: [Difficulty: (min: Double, max: Double)] = [
        .veryEasy: (8.0, 15.0),   // Still gives player time to feel ahead
        .easy: (6.0, 12.0),
        .medium: (4.0, 8.0),
        .hard: (2.0, 5.0)         // Fast and challenging
    ]
    
    init(difficulty: Difficulty = .medium, isKidsMode: Bool = false) {
        self.id = "bot-\(UUID().uuidString)"
        self.difficulty = difficulty
        self.name = isKidsMode ? LocalBotPlayer.generateKidsName() : LocalBotPlayer.generateRandomName()
    }
    
    /// Schedule bot submission with callback
    func scheduleSubmission(letters: [String], bonuses: [(index: Int, type: String)], onSubmit: @escaping (String, Int) -> Void) {
        let delay = getDelay()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            // Find valid words using local dictionary
            let validWords = LocalDictionary.shared.findValidWords(letters: letters)
            
            if validWords.isEmpty {
                onSubmit("", 0)
                return
            }
            
            // Score all words with length bonus consideration
            let scoredWords = validWords.map { word -> (word: String, score: Int, length: Int) in
                let score = LocalScorer.shared.calculate(word: word, rack: letters, bonuses: bonuses)
                return (word, score, word.count)
            }.sorted { 
                // Sort by score, then by length as tiebreaker
                if $0.score != $1.score {
                    return $0.score > $1.score
                }
                return $0.length > $1.length
            }
            
            // Pick word based on difficulty
            let (word, score, _) = self.pickWord(scoredWords)
            onSubmit(word, score)
        }
    }
    
    /// Pick word based on difficulty level - improved logic
    private func pickWord(_ scoredWords: [(word: String, score: Int, length: Int)]) -> (String, Int, Int) {
        let total = scoredWords.count
        guard total > 0 else { return ("", 0, 0) }
        
        var pickIndex: Int
        
        switch difficulty {
        case .veryEasy:
            // Pick from bottom 50% - often short/low-scoring words
            let bottomHalf = max(1, total / 2)
            pickIndex = total - Int.random(in: 1...bottomHalf)
            
        case .easy:
            // Pick from 40-70% range - below average but not terrible
            let start = Int(Double(total) * 0.3)
            let end = Int(Double(total) * 0.7)
            pickIndex = Int.random(in: start...max(start, end))
            
        case .medium:
            // Pick from top 40% - competitive but beatable
            let top40 = max(1, Int(Double(total) * 0.4))
            pickIndex = Int.random(in: 0..<top40)
            
        case .hard:
            // 70% chance of picking THE best word, 30% top 3
            if Double.random(in: 0...1) < 0.7 {
                pickIndex = 0
            } else {
                pickIndex = Int.random(in: 0..<min(3, total))
            }
        }
        
        // Clamp index
        pickIndex = min(pickIndex, total - 1)
        pickIndex = max(pickIndex, 0)
        
        return scoredWords[pickIndex]
    }
    
    /// Get random delay based on difficulty
    private func getDelay() -> Double {
        let range = delays[difficulty] ?? (4.0, 8.0)
        return Double.random(in: range.min...range.max)
    }
    
    // MARK: - Name Generation
    
    private static let adjectives = [
        "Swift", "Clever", "Quick", "Sharp", "Bright", "Bold", "Keen", "Witty",
        "Smart", "Agile", "Noble", "Grand", "Prime", "Elite", "Alpha", "Mega"
    ]
    
    private static let nouns = [
        "Fox", "Hawk", "Wolf", "Bear", "Lion", "Tiger", "Eagle", "Falcon",
        "Raven", "Cobra", "Viper", "Phoenix", "Dragon", "Knight", "Wizard", "Ninja"
    ]
    
    private static let kidsAdjectives = [
        "Happy", "Brave", "Clever", "Quick", "Bright", "Cool", "Swift", "Lucky"
    ]
    
    private static let kidsNouns = [
        "Panda", "Tiger", "Eagle", "Dolphin", "Fox", "Owl", "Wolf", "Bear"
    ]
    
    static func generateRandomName() -> String {
        let adj = adjectives.randomElement()!
        let noun = nouns.randomElement()!
        let num = Int.random(in: 0...99)
        return "\(adj)\(noun)\(num) (Bot)"
    }
    
    static func generateKidsName() -> String {
        let adj = kidsAdjectives.randomElement()!
        let noun = kidsNouns.randomElement()!
        return "\(adj)\(noun)"
    }
}
