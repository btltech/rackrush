import Foundation
import SwiftUI
import GameKit

enum GameScreen {
    case home
    case modeSelect
    case queued
    case match
    case roundResult
    case matchResult
    case dailyChallenge
}

enum MatchType: String {
    case pvp = "pvp"
    case bot = "bot"
}

enum BotDifficulty: String, CaseIterable {
    case veryEasy = "very_easy"
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
}

/// Connection mode for gameplay
enum ConnectionMode {
    case railway      // Original Socket.IO backend
    case gameCenter   // Apple Game Center
    case offline      // Local bot only (no network)
}

struct BonusTile: Identifiable {
    let id = UUID()
    let index: Int
    let type: String // "DL", "TL", "DW"
}

struct RoundResult {
    let yourWord: String
    let yourScore: Int
    let oppWord: String
    let oppScore: Int
    let winner: String
    let yourTotalScore: Int
    let oppTotalScore: Int
    let roundNumber: Int
    let totalRounds: Int
    let nextRoundStartsAt: Int? // Timestamp in ms
}

@MainActor
class GameState: ObservableObject {
    weak var socketService: SocketService? {
        didSet {
            setupMessageSubscription()
        }
    }
    
    // Connection mode - determines how matches are played
    @Published var connectionMode: ConnectionMode = .railway
    
    // Game Center service
    var gameCenterService = GameCenterService.shared
    
    // Offline bot player
    private var localBot: LocalBotPlayer?
    private var roundTimer: Timer?
    private var autoContinueWorkItem: DispatchWorkItem?
    
    // Subscription token (retained to keep subscription alive)
    private var messageSubscription: MessageSubscription?
    
    @Published var screen: GameScreen = .home
    
    // Mode selection
    @Published var selectedMode: Int = 7  // Default to Quick (7 letters)
    @Published var matchType: MatchType = .bot
    @Published var botDifficulty: BotDifficulty = .medium
    
    // Match state
    @Published var roomId: String?
    @Published var opponentName: String?
    @Published var opponentIsBot: Bool = false
    
    // Round state
    @Published var currentRound: Int = 0
    @Published var letters: [String] = []
    @Published var bonuses: [BonusTile] = []
    @Published var roundEndsAt: Int = 0
    @Published var roundDurationMs: Int = 30000 // Server-provided duration
    @Published var roundDelayMs: Int = 0 
    @Published var submitted: Bool = false
    @Published var opponentSubmitted: Bool = false
    @Published var currentWord: String = ""
    
    // Results
    @Published var lastRoundResult: RoundResult?
    @Published var myTotalScore: Int = 0
    @Published var oppTotalScore: Int = 0
    @Published var currentRoundNumber: Int = 0
    @Published var totalRounds: Int = 7
    @Published var matchWinner: String?
    @Published var roundHistory: [RoundResult] = []
    
    // Tutorial & Onboarding
    @Published var isTutorialMode: Bool = false
    @Published var showTutorialOverlay: Bool = false
    @AppStorage("hasCompletedTutorial") var hasCompletedTutorial: Bool = false
    @AppStorage("hasSeenFirstWin") var hasSeenFirstWin: Bool = false
    @AppStorage("totalMatchesPlayed") var totalMatchesPlayed: Int = 0
    @AppStorage("totalWins") var totalWins: Int = 0
    
    private func setupMessageSubscription() {
        // Cancel any existing subscription
        messageSubscription?.cancel()
        
        // Subscribe to game-related messages
        messageSubscription = socketService?.subscribe(
            to: ["queued", "matchFound", "roundStart", "opponentSubmitted", "roundResult", "matchResult", "error"]
        ) { [weak self] type, data in
            self?.handleMessage(type: type, data: data)
        }
    }
    
    private func handleMessage(type: String, data: [String: Any]) {
        switch type {
        case "queued":
            screen = .queued
            
        case "matchFound":
            roomId = data["roomId"] as? String
            if let opponent = data["opponent"] as? [String: Any] {
                opponentName = opponent["name"] as? String
                opponentIsBot = opponent["isBot"] as? Bool ?? false
            }
            screen = .match
            myTotalScore = 0
            oppTotalScore = 0
            currentRoundNumber = 0
            
        case "roundStart":
            currentRound = data["round"] as? Int ?? 0
            letters = data["letters"] as? [String] ?? []
            if let bonusData = data["bonuses"] as? [[String: Any]] {
                bonuses = bonusData.compactMap { dict in
                    guard let index = dict["index"] as? Int,
                          let type = dict["type"] as? String else { return nil }
                    return BonusTile(index: index, type: type)
                }
            }
            // Use relative duration for accurate local timing (avoids clock drift)
            let durationMs = data["durationMs"] as? Int ?? 30000
            let delayMs = data["delayMs"] as? Int ?? 0
            
            roundDurationMs = durationMs
            roundDelayMs = delayMs
            
            // Calculate endsAt based on local time + delay + duration
            roundEndsAt = Int(Date().timeIntervalSince1970 * 1000) + delayMs + durationMs
            
            submitted = false
            opponentSubmitted = false
            currentWord = ""
            screen = .match
            
        case "opponentSubmitted":
            opponentSubmitted = true
            
        case "roundResult":
            lastRoundResult = RoundResult(
                yourWord: data["yourWord"] as? String ?? "",
                yourScore: data["yourScore"] as? Int ?? 0,
                oppWord: data["oppWord"] as? String ?? "",
                oppScore: data["oppScore"] as? Int ?? 0,
                winner: data["winner"] as? String ?? "",
                yourTotalScore: data["yourTotalScore"] as? Int ?? 0,
                oppTotalScore: data["oppTotalScore"] as? Int ?? 0,
                roundNumber: data["roundNumber"] as? Int ?? 1,
                totalRounds: data["totalRounds"] as? Int ?? 3,
                nextRoundStartsAt: data["nextRoundStartsAt"] as? Int
            )
            myTotalScore = lastRoundResult?.yourTotalScore ?? 0
            oppTotalScore = lastRoundResult?.oppTotalScore ?? 0
            if let result = lastRoundResult {
                roundHistory.append(result)
                
                // Stats: Best Word
                if result.yourScore > 0 {
                    StatsManager.shared.checkBestWord(word: result.yourWord, score: result.yourScore)
                }
            }
            
            screen = .roundResult
            
        case "matchResult":
            myTotalScore = data["yourTotalScore"] as? Int ?? 0
            oppTotalScore = data["oppTotalScore"] as? Int ?? 0
            matchWinner = data["winner"] as? String
            
            // Stats: Game Record
            let won = myTotalScore > oppTotalScore
            StatsManager.shared.recordGame(won: won, score: myTotalScore)
            
            screen = .matchResult
            
        case "error":
            print("Server error: \(data["message"] ?? "")")
            
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    func setMode(_ mode: Int) {
        selectedMode = mode
    }
    
    func setMatchType(_ type: MatchType) {
        matchType = type
    }
    
    func setBotDifficulty(_ difficulty: BotDifficulty) {
        botDifficulty = difficulty
    }
    
    func goToModeSelect() {
        screen = .modeSelect
    }
    
    func goHome() {
        screen = .home
        socketService?.leave()
        reset()
    }
    
    func startQueue() {
        // Check if Kids Mode is enabled and get settings
        let kidsManager = KidsModeManager.shared
        var kidsModeSettings: [String: Any]? = nil
        
        // Block PvP entirely if Kids Mode is on but online consent is off
        if kidsManager.isEnabled && matchType == .pvp && !kidsManager.canPlayOnline {
            // Cannot play online PvP without parental consent
            // Silently switch to bot match instead
            matchType = .bot
        }
        
        if kidsManager.isEnabled && kidsManager.canPlayOnline && matchType == .pvp {
            // Send kids mode settings for safe matchmaking
            kidsModeSettings = kidsManager.matchmakingData
        }
        
        socketService?.queue(
            mode: selectedMode,
            matchType: matchType.rawValue,
            botDifficulty: matchType == .bot ? botDifficulty.rawValue : nil,
            kidsMode: kidsModeSettings
        )
    }
    
    func addLetter(_ letter: String) {
        guard !submitted else { return }
        
        let usedLetters = Array(currentWord)
        var availableLetters = letters
        
        for used in usedLetters {
            if let idx = availableLetters.firstIndex(of: String(used)) {
                availableLetters.remove(at: idx)
            }
        }
        
        if availableLetters.contains(letter) {
            currentWord += letter
        }
    }
    
    func removeLetter() {
        guard !submitted, !currentWord.isEmpty else { return }
        currentWord.removeLast()
    }
    
    func clearWord() {
        guard !submitted else { return }
        currentWord = ""
    }
    
    func submitWord() {
        guard !submitted, !currentWord.isEmpty else { return }
        
        switch connectionMode {
        case .railway:
            socketService?.submitWord(currentWord)
            submitted = true
        case .gameCenter:
            // Send to opponent via Game Center (handles scoring)
            gameCenterService.submitWord(currentWord)
            submitted = true
        case .offline:
            // Offline mode - mark as submitted and check if round should end
            submitted = true
            checkRoundEnd()
        }
    }
    
    func continueAfterRound() {
        // Cancel auto-continue if user tapped manually
        autoContinueWorkItem?.cancel()
        autoContinueWorkItem = nil
        
        if connectionMode == .offline {
            // Offline mode - start next round locally
            startOfflineRound()
        } else {
            // Railway/Game Center - server handles next round
            screen = .match
        }
    }
    
    // MARK: - Offline Bot Match
    
    /// Start an offline bot match (no network required)
    func startOfflineBotMatch() {
        connectionMode = .offline
        
        let kidsManager = KidsModeManager.shared
        let isKids = kidsManager.isEnabled
        let difficulty: LocalBotPlayer.Difficulty
        
        if isKids {
            difficulty = LocalBotPlayer.Difficulty(rawValue: kidsManager.ageGroup.botDifficulty) ?? .veryEasy
        } else {
            switch botDifficulty {
            case .veryEasy: difficulty = .veryEasy
            case .easy: difficulty = .easy
            case .medium: difficulty = .medium
            case .hard: difficulty = .hard
            }
        }
        
        localBot = LocalBotPlayer(difficulty: difficulty, isKidsMode: isKids)
        
        // Setup match
        roomId = "offline-\(UUID().uuidString)"
        opponentName = localBot?.name
        opponentIsBot = true
        myTotalScore = 0
        oppTotalScore = 0
        currentRoundNumber = 0
        roundHistory = []
        
        // Start first round immediately to populate letters
        startOfflineRound()
        
        // Show match screen after brief delay for animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.screen = .match
        }
    }
    
    /// Start an offline round
    private func startOfflineRound() {
        // Increment round FIRST so roundDelayMs check is correct
        currentRoundNumber += 1
        currentRound = currentRoundNumber
        
        // Generate rack locally
        let letterCount = selectedMode
        let (generatedLetters, generatedBonuses) = LocalRackGenerator.shared.generate(letterCount: letterCount)
        
        letters = generatedLetters
        bonuses = generatedBonuses.map { BonusTile(index: $0.index, type: $0.type) }
        
        // Get timer from kids mode or default
        let kidsManager = KidsModeManager.shared
        let timerSeconds = kidsManager.isEnabled ? kidsManager.ageGroup.timerSeconds : 30
        roundDurationMs = timerSeconds * 1000
        // Only show 3-2-1 countdown for first round
        roundDelayMs = currentRoundNumber == 1 ? 3000 : 0
        roundEndsAt = Int(Date().timeIntervalSince1970 * 1000) + roundDelayMs + roundDurationMs
        
        submitted = false
        opponentSubmitted = false
        currentWord = ""
        
        // NOW change screen - view will see correct roundDelayMs
        screen = .match
        
        // Schedule bot submission
        let bonusTuples = generatedBonuses
        localBot?.scheduleSubmission(letters: letters, bonuses: bonusTuples) { [weak self] word, score in
            guard let self = self else { return }
            self.opponentSubmitted = true
            // Store bot's word/score for round end
            self.botLastWord = word
            self.botLastScore = score
            
            // Check if both submitted
            self.checkRoundEnd()
        }
        
        // Schedule round timeout
        roundTimer?.invalidate()
        roundTimer = Timer.scheduledTimer(withTimeInterval: Double(roundDelayMs + roundDurationMs) / 1000.0, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.endOfflineRound()
            }
        }
    }
    
    // Bot's last submission (for round end)
    private var botLastWord: String = ""
    private var botLastScore: Int = 0
    
    /// Check if round should end (both submitted)
    private func checkRoundEnd() {
        if submitted && opponentSubmitted {
            roundTimer?.invalidate()
            endOfflineRound()
        }
    }
    
    /// End the offline round and calculate results
    private func endOfflineRound() {
        roundTimer?.invalidate()
        
        // Calculate player's score
        let playerWord = currentWord.isEmpty ? "" : currentWord
        let validation = LocalDictionary.shared.validate(playerWord, rack: letters)
        let playerScore = validation.valid ? LocalScorer.shared.calculate(
            word: playerWord,
            rack: letters,
            bonuses: bonuses.map { ($0.index, $0.type) }
        ) : 0
        
        // Determine winner
        let winner: String
        if playerScore > botLastScore {
            winner = "you"
        } else if botLastScore > playerScore {
            winner = "opp"
        } else {
            winner = "tie"
        }
        
        // Update totals
        myTotalScore += playerScore
        oppTotalScore += botLastScore
        
        // Stats
        if playerScore > 0 {
            StatsManager.shared.checkBestWord(word: playerWord, score: playerScore)
        }
        
        // Create round result
        let kidsManager = KidsModeManager.shared
        let roundsPerMatch = kidsManager.isEnabled ? kidsManager.ageGroup.roundsPerMatch : 7
        
        lastRoundResult = RoundResult(
            yourWord: validation.valid ? playerWord.uppercased() : "",
            yourScore: playerScore,
            oppWord: botLastWord.uppercased(),
            oppScore: botLastScore,
            winner: winner,
            yourTotalScore: myTotalScore,
            oppTotalScore: oppTotalScore,
            roundNumber: currentRoundNumber,
            totalRounds: roundsPerMatch,
            nextRoundStartsAt: nil
        )
        
        if let result = lastRoundResult {
            roundHistory.append(result)
        }
        
        // Check if match is over
        if currentRoundNumber >= roundsPerMatch {
            // Match finished
            matchWinner = myTotalScore > oppTotalScore ? "you" : (myTotalScore < oppTotalScore ? "opp" : "tie")
            StatsManager.shared.recordGame(won: myTotalScore > oppTotalScore, score: myTotalScore)
            
            // Track stats
            totalMatchesPlayed += 1
            if matchWinner == "you" {
                totalWins += 1
                
                // Check achievements
                AchievementSystem.shared.checkAchievements(event: .matchWon)
                
                // Check for perfect game
                let wonAllRounds = roundHistory.allSatisfy { $0.yourScore > $0.oppScore }
                if wonAllRounds {
                    AchievementSystem.shared.checkAchievements(event: .perfectMatch)
                }
                
                // Check for high score
                AchievementSystem.shared.checkAchievements(event: .highScore(score: myTotalScore))
                
                // Check for comeback - calculate max deficit we overcame
                var maxDeficit = 0
                var runningPlayerScore = 0
                var runningOppScore = 0
                for round in roundHistory {
                    runningOppScore += round.oppScore
                    let deficitBeforeRound = runningOppScore - runningPlayerScore
                    if deficitBeforeRound > maxDeficit {
                        maxDeficit = deficitBeforeRound
                    }
                    runningPlayerScore += round.yourScore
                }
                if maxDeficit >= 50 {
                    AchievementSystem.shared.checkAchievements(event: .comeback(deficit: maxDeficit))
                }
            }
            
            screen = .roundResult
            // After showing round result, show match result
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.screen = .matchResult
            }
        } else {
            screen = .roundResult
            // Auto-continue to next round after delay (like online version)
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                if self.connectionMode == .offline {
                    self.startOfflineRound()
                }
                self.autoContinueWorkItem = nil
            }
            self.autoContinueWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.0, execute: workItem)
        }
        
        // Reset for next round
        botLastWord = ""
        botLastScore = 0
    }
    
    /// Continue to next offline round
    func continueOfflineRound() {
        if currentRoundNumber < totalRounds {
            startOfflineRound()
        }
    }
    
    // MARK: - Game Center Match
    
    /// Setup Game Center callbacks (call once on init)
    func setupGameCenterCallbacks() {
        gameCenterService.onMatchFound = { [weak self] in
            guard let self = self else { return }
            self.roomId = "gc-\(UUID().uuidString)"
            self.opponentName = self.gameCenterService.opponentName
            self.opponentIsBot = false
            self.myTotalScore = 0
            self.oppTotalScore = 0
            self.currentRoundNumber = 0
            self.roundHistory = []
            self.screen = .match
        }
        
        gameCenterService.onRoundStart = { [weak self] in
            guard let self = self else { return }
            let gc = self.gameCenterService
            self.currentRound = gc.currentRound
            self.currentRoundNumber = gc.currentRound
            self.letters = gc.letters
            self.bonuses = gc.bonuses.map { BonusTile(index: $0.index, type: $0.type) }
            self.roundEndsAt = gc.roundEndsAt
            self.roundDurationMs = 30000
            // Only show 3-2-1 countdown for first round (match offline behavior)
            self.roundDelayMs = gc.currentRound == 1 ? 3000 : 0
            self.submitted = false
            self.opponentSubmitted = false
            self.currentWord = ""
            self.screen = .match
        }
        
        gameCenterService.onOpponentSubmitted = { [weak self] in
            self?.opponentSubmitted = true
        }
        
        gameCenterService.onRoundEnd = { [weak self] result in
            guard let self = self else { return }
            self.lastRoundResult = RoundResult(
                yourWord: result.yourWord,
                yourScore: result.yourScore,
                oppWord: result.oppWord,
                oppScore: result.oppScore,
                winner: result.winner,
                yourTotalScore: result.yourTotalScore,
                oppTotalScore: result.oppTotalScore,
                roundNumber: result.roundNumber,
                totalRounds: result.totalRounds,
                nextRoundStartsAt: nil
            )
            self.myTotalScore = result.yourTotalScore
            self.oppTotalScore = result.oppTotalScore
            
            if result.yourScore > 0 {
                StatsManager.shared.checkBestWord(word: result.yourWord, score: result.yourScore)
            }
            
            if let lastResult = self.lastRoundResult {
                self.roundHistory.append(lastResult)
            }
            
            self.screen = .roundResult
        }
        
        gameCenterService.onMatchEnd = { [weak self] winner in
            guard let self = self else { return }
            self.matchWinner = winner
            StatsManager.shared.recordGame(won: winner == "you", score: self.myTotalScore)
            
            // Show match result after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.screen = .matchResult
            }
        }
    }
    
    /// Start Game Center matchmaking
    func startGameCenterMatch() {
        connectionMode = .gameCenter
        
        // Setup callbacks if not done
        setupGameCenterCallbacks()
        
        // Authenticate if needed
        if !gameCenterService.isAuthenticated {
            gameCenterService.authenticate()
        }
        
        screen = .queued
        
        // Wait for auth then find match
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if self.gameCenterService.isAuthenticated {
                self.gameCenterService.findMatch()
            } else {
                // Wait more for auth
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    if self.gameCenterService.isAuthenticated {
                        self.gameCenterService.findMatch()
                    } else {
                        self.screen = .home
                        // Still not authenticated - could show error
                    }
                }
            }
        }
    }
    
    private func reset() {
        roomId = nil
        opponentName = nil
        opponentIsBot = false
        currentRound = 0
        letters = []
        bonuses = []
        roundEndsAt = 0
        submitted = false
        opponentSubmitted = false
        currentWord = ""
        lastRoundResult = nil
        myTotalScore = 0
        oppTotalScore = 0
        currentRoundNumber = 0
        matchWinner = nil
        roundHistory = []
        roundTimer?.invalidate()
        localBot = nil
        botLastWord = ""
        botLastScore = 0
        gameCenterService.disconnect()
    }
}
