import Foundation

/// Bot personality system for varied AI opponents
enum BotPersonality: String, CaseIterable, Codable {
    case professor = "Professor Wordsworth"
    case speedDemon = "Speed Demon"
    case gambler = "The Gambler"
    
    // MARK: - Display Properties
    
    var displayName: String {
        return rawValue
    }
    
    var avatar: String {
        switch self {
        case .professor: return "🎓"
        case .speedDemon: return "⚡️"
        case .gambler: return "🎲"
        }
    }
    
    var description: String {
        switch self {
        case .professor:
            return "Prefers long, academic words. Slow but strategic."
        case .speedDemon:
            return "Submits quickly with shorter words. Fast-paced gameplay."
        case .gambler:
            return "High-risk bonus tile usage. Unpredictable scoring."
        }
    }
    
    var difficulty: String {
        switch self {
        case .professor: return "Hard"
        case .speedDemon: return "Medium"
        case .gambler: return "Medium"
        }
    }
    
    var color: String {
        switch self {
        case .professor: return "8B5CF6" // Purple
        case .speedDemon: return "F59E0B" // Orange
        case .gambler: return "EF4444" // Red
        }
    }
    
    // MARK: - Voice Lines
    
    var greetings: [String] {
        switch self {
        case .professor:
            return [
                "Greetings, wordsmith!",
                "Let us engage in lexical combat.",
                "Prepare for erudite wordplay!",
                "A battle of vocabularies awaits."
            ]
        case .speedDemon:
            return [
                "Let's go! No time to waste!",
                "Speed is key!",
                "Quick match, let's do this!",
                "Fast and furious!"
            ]
        case .gambler:
            return [
                "Feeling lucky?",
                "Let's roll the dice!",
                "High stakes, high rewards!",
                "All or nothing!"
            ]
        }
    }
    
    var victories: [String] {
        switch self {
        case .professor:
            return [
                "A most satisfactory outcome!",
                "Knowledge prevails once more.",
                "The pen is mightier indeed.",
                "Vocabulary: 1, Opponent: 0"
            ]
        case .speedDemon:
            return [
                "Too fast for you!",
                "Speed wins!",
                "Blink and you miss it!",
                "Lightning strikes again!"
            ]
        case .gambler:
            return [
                "The house always wins!",
                "Jackpot!",
                "Lady Luck smiles upon me!",
                "All in, all won!"
            ]
        }
    }
    
    var defeats: [String] {
        switch self {
        case .professor:
            return [
                "A humbling experience.",
                "Your vocabulary is impressive.",
                "I concede this round.",
                "Well played, scholar."
            ]
        case .speedDemon:
            return [
                "Not fast enough this time!",
                "You got me!",
                "Respect the speed!",
                "Next time!"
            ]
        case .gambler:
            return [
                "The dice weren't in my favor.",
                "Can't win 'em all!",
                "Better luck next time!",
                "The odds were against me."
            ]
        }
    }
    
    // MARK: - Strategy Parameters
    
    /// Preferred word length range
    var preferredWordLength: ClosedRange<Int> {
        switch self {
        case .professor: return 6...10
        case .speedDemon: return 3...5
        case .gambler: return 4...8
        }
    }
    
    /// Response time range (seconds)
    var responseTime: ClosedRange<Double> {
        switch self {
        case .professor: return 8.0...15.0
        case .speedDemon: return 2.0...5.0
        case .gambler: return 4.0...10.0
        }
    }
    
    /// Bonus tile usage probability (0.0 - 1.0)
    var bonusTilePreference: Double {
        switch self {
        case .professor: return 0.6
        case .speedDemon: return 0.3
        case .gambler: return 0.9
        }
    }
    
    /// Risk tolerance for word selection (0.0 - 1.0)
    /// Higher = more likely to try uncommon words
    var riskTolerance: Double {
        switch self {
        case .professor: return 0.8
        case .speedDemon: return 0.3
        case .gambler: return 0.7
        }
    }
    
    // MARK: - Helper Methods
    
    func randomGreeting() -> String {
        greetings.randomElement() ?? "Let's play!"
    }
    
    func randomVictory() -> String {
        victories.randomElement() ?? "I win!"
    }
    
    func randomDefeat() -> String {
        defeats.randomElement() ?? "Good game!"
    }
    
    /// Evaluate if a word fits this bot's strategy
    func evaluateWord(_ word: String, hasBonus: Bool) -> Double {
        var score = 0.0
        
        // Length preference
        let lengthMatch = preferredWordLength.contains(word.count)
        score += lengthMatch ? 1.0 : 0.3
        
        // Bonus tile preference
        if hasBonus {
            score += bonusTilePreference
        }
        
        // Risk factor (longer words = higher risk)
        let riskFactor = Double(word.count) / 10.0
        score += riskFactor * riskTolerance
        
        return score
    }
    
    /// Get random response delay based on personality
    func getResponseDelay() -> Double {
        Double.random(in: responseTime)
    }
}

/// Bot personality manager
class BotPersonalityManager: ObservableObject {
    static let shared = BotPersonalityManager()
    
    @Published var currentBot: BotPersonality = .professor
    @Published var unlockedBots: Set<BotPersonality> = Set(BotPersonality.allCases)
    
    private init() {
        loadUnlockedBots()
    }
    
    // MARK: - Public Methods
    
    func selectRandomBot() -> BotPersonality {
        let available = Array(unlockedBots)
        return available.randomElement() ?? .speedDemon
    }
    
    func unlockBot(_ bot: BotPersonality) {
        unlockedBots.insert(bot)
        saveUnlockedBots()
    }
    
    func isUnlocked(_ bot: BotPersonality) -> Bool {
        unlockedBots.contains(bot)
    }
    
    // MARK: - Persistence
    
    private func loadUnlockedBots() {
        if let data = UserDefaults.standard.data(forKey: "unlockedBots"),
           let decoded = try? JSONDecoder().decode(Set<BotPersonality>.self, from: data) {
            unlockedBots = decoded
        }
    }
    
    private func saveUnlockedBots() {
        if let encoded = try? JSONEncoder().encode(unlockedBots) {
            UserDefaults.standard.set(encoded, forKey: "unlockedBots")
        }
    }
}
