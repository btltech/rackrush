import Foundation
import GameKit
import SwiftUI

/// Game Center Service for Apple matchmaking and real-time PvP
@MainActor
class GameCenterService: NSObject, ObservableObject {
    static let shared = GameCenterService()
    
    @Published var isAuthenticated = false
    @Published var localPlayerName = "Player"
    @Published var localPlayerId = ""
    @Published var currentMatch: GKMatch?
    @Published var matchState: MatchState = .idle
    @Published var error: String?
    
    // Match data
    @Published var opponentName = ""
    @Published var opponentId = ""
    @Published var isHost = false  // Host generates letters and manages rounds
    
    // Round data
    @Published var currentRound = 0
    @Published var letters: [String] = []
    @Published var bonuses: [(index: Int, type: String)] = []
    @Published var roundEndsAt: Int = 0
    @Published var submitted = false
    @Published var opponentSubmitted = false
    @Published var myWord = ""
    @Published var myScore = 0
    @Published var oppWord = ""
    @Published var oppScore = 0
    
    // Scores
    @Published var myTotalScore = 0
    @Published var oppTotalScore = 0
    @Published var roundHistory: [RoundResultData] = []
    @Published var matchWinner: String?
    
    // Callbacks for GameState integration
    var onMatchFound: (() -> Void)?
    var onRoundStart: (() -> Void)?
    var onOpponentSubmitted: (() -> Void)?
    var onRoundEnd: ((RoundResultData) -> Void)?
    var onMatchEnd: ((String) -> Void)?  // winner: "you", "opp", "tie"
    
    enum MatchState: String {
        case idle
        case authenticating
        case finding
        case matched
        case countdown
        case playing
        case roundEnded
        case matchEnded
    }
    
    struct RoundResultData {
        let yourWord: String
        let yourScore: Int
        let oppWord: String
        let oppScore: Int
        let winner: String
        let yourTotalScore: Int
        let oppTotalScore: Int
        let roundNumber: Int
        let totalRounds: Int
    }
    
    private var roundTimer: Timer?
    private let totalRounds = 7
    private let roundDurationSeconds = 30
    
    override private init() {
        super.init()
    }
    
    // MARK: - Authentication
    
    func authenticate() {
        guard !isAuthenticated else { return }
        matchState = .authenticating
        
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let error = error {
                    self?.error = "Game Center: \(error.localizedDescription)"
                    self?.matchState = .idle
                    return
                }
                
                if viewController != nil {
                    // System will show Game Center login UI
                    return
                }
                
                if GKLocalPlayer.local.isAuthenticated {
                    self?.isAuthenticated = true
                    self?.localPlayerName = GKLocalPlayer.local.displayName
                    self?.localPlayerId = GKLocalPlayer.local.gamePlayerID
                    self?.matchState = .idle
                    print("Game Center authenticated: \(GKLocalPlayer.local.displayName)")
                } else {
                    self?.error = "Game Center authentication failed"
                    self?.matchState = .idle
                }
            }
        }
    }
    
    // MARK: - Matchmaking
    
    func findMatch(minPlayers: Int = 2, maxPlayers: Int = 2) {
        guard isAuthenticated else {
            error = "Not authenticated with Game Center"
            return
        }
        
        matchState = .finding
        resetMatchData()
        
        let request = GKMatchRequest()
        request.minPlayers = minPlayers
        request.maxPlayers = maxPlayers
        request.inviteMessage = "Let's play RackRush!"
        // Set delegate to suppress warning (we handle async matchmaking, not invites)
        request.recipientResponseHandler = { _, _ in }
        
        GKMatchmaker.shared().findMatch(for: request) { [weak self] match, error in
            Task { @MainActor in
                if let error = error {
                    self?.error = "Matchmaking failed: \(error.localizedDescription)"
                    self?.matchState = .idle
                    return
                }
                
                guard let match = match else {
                    self?.error = "No match found"
                    self?.matchState = .idle
                    return
                }
                
                self?.setupMatch(match)
            }
        }
    }
    
    private func setupMatch(_ match: GKMatch) {
        currentMatch = match
        match.delegate = self
        matchState = .matched
        
        // Get opponent info (may be populated later via delegate)
        updateOpponentInfo(from: match)
        
        print("Match found! Opponent: \(opponentName), I am host: \(isHost)")
        
        onMatchFound?()
        
        // If host, start the first round after a delay
        if isHost {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.startRound()
            }
        }
    }
    
    private func updateOpponentInfo(from match: GKMatch) {
        // Try to get opponent from players array
        for player in match.players {
            if player.gamePlayerID != localPlayerId {
                opponentName = player.displayName
                opponentId = player.gamePlayerID
                
                // Determine host (player with "lower" ID is host)
                isHost = localPlayerId < opponentId
                
                print("Opponent updated: \(opponentName), I am host: \(isHost)")
                break
            }
        }
    }
    
    func cancelMatchmaking() {
        GKMatchmaker.shared().cancel()
        matchState = .idle
    }
    
    // MARK: - Round Management (Host Only)
    
    private func startRound() {
        guard isHost else { return }
        
        currentRound += 1
        
        print("🎮 Starting round \(currentRound)")
        
        // Generate letters locally
        let letterCount = 8  // Standard mode
        let (generatedLetters, generatedBonuses) = LocalRackGenerator.shared.generate(letterCount: letterCount)
        
        letters = generatedLetters
        bonuses = generatedBonuses
        
        print("🎮 Generated letters: \(letters)")
        
        // Calculate round end time
        let now = Int(Date().timeIntervalSince1970 * 1000)
        let delayMs = 3000  // 3 second countdown
        roundEndsAt = now + delayMs + (roundDurationSeconds * 1000)
        
        // Reset submission state
        submitted = false
        opponentSubmitted = false
        myWord = ""
        myScore = 0
        oppWord = ""
        oppScore = 0
        
        // Send round start to opponent
        let data = GameData(
            type: .roundStart,
            letters: letters,
            bonuses: bonuses.map { GameData.BonusData(index: $0.index, type: $0.type) },
            roundNumber: currentRound,
            endsAt: roundEndsAt
        )
        sendData(data)
        
        print("🎮 Sent round data to opponent")
        
        matchState = .countdown
        
        // Start countdown then switch to playing
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            print("🎮 Countdown done, starting play!")
            self.matchState = .playing
            self.onRoundStart?()
        }
        
        // Schedule round end
        let totalDelay = Double(delayMs + (roundDurationSeconds * 1000)) / 1000.0
        roundTimer?.invalidate()
        roundTimer = Timer.scheduledTimer(withTimeInterval: totalDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.endRound()
            }
        }
    }
    
    // MARK: - Submissions
    
    func submitWord(_ word: String) {
        guard !submitted else { return }
        
        myWord = word.uppercased()
        
        // Validate and score locally
        let validation = LocalDictionary.shared.validate(word, rack: letters)
        myScore = validation.valid ? LocalScorer.shared.calculate(
            word: word,
            rack: letters,
            bonuses: bonuses
        ) : 0
        
        submitted = true
        
        // Send submission to opponent
        let data = GameData(type: .submission, word: myWord, score: myScore)
        sendData(data)
        
        // Check if both submitted
        checkBothSubmitted()
    }
    
    private func checkBothSubmitted() {
        if submitted && opponentSubmitted {
            roundTimer?.invalidate()
            endRound()
        }
    }
    
    private func endRound() {
        guard matchState == .playing || matchState == .countdown else { return }
        
        roundTimer?.invalidate()
        
        // Determine round winner
        let winner: String
        if myScore > oppScore {
            winner = "you"
        } else if oppScore > myScore {
            winner = "opp"
        } else {
            winner = "tie"
        }
        
        // Update totals
        myTotalScore += myScore
        oppTotalScore += oppScore
        
        // Create result
        let result = RoundResultData(
            yourWord: myWord,
            yourScore: myScore,
            oppWord: oppWord,
            oppScore: oppScore,
            winner: winner,
            yourTotalScore: myTotalScore,
            oppTotalScore: oppTotalScore,
            roundNumber: currentRound,
            totalRounds: totalRounds
        )
        roundHistory.append(result)
        
        matchState = .roundEnded
        onRoundEnd?(result)
        
        // If host, send result to opponent (from their perspective)
        if isHost {
            let oppResult = GameData(
                type: .roundResult,
                roundResult: GameData.RoundResultPayload(
                    yourWord: oppWord,
                    yourScore: oppScore,
                    oppWord: myWord,
                    oppScore: myScore,
                    winner: winner == "you" ? "opp" : (winner == "opp" ? "you" : "tie"),
                    yourTotalScore: oppTotalScore,
                    oppTotalScore: myTotalScore,
                    roundNumber: currentRound,
                    totalRounds: totalRounds
                )
            )
            sendData(oppResult)
        }
        
        // Check if match is over
        if currentRound >= totalRounds {
            endMatch()
        } else if isHost {
            // Start next round after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                self.startRound()
            }
        }
    }
    
    private func endMatch() {
        matchState = .matchEnded
        
        if myTotalScore > oppTotalScore {
            matchWinner = "you"
        } else if oppTotalScore > myTotalScore {
            matchWinner = "opp"
        } else {
            matchWinner = "tie"
        }
        
        onMatchEnd?(matchWinner ?? "tie")
        
        // Clean up
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.disconnect()
        }
    }
    
    // MARK: - Data Exchange
    
    func sendData(_ data: GameData) {
        guard let match = currentMatch else { return }
        
        do {
            let encoded = try JSONEncoder().encode(data)
            try match.sendData(toAllPlayers: encoded, with: .reliable)
        } catch {
            print("Failed to send data: \(error)")
        }
    }
    
    private func handleReceivedData(_ data: GameData) {
        switch data.type {
        case .roundStart:
            // Received from host
            if let receivedLetters = data.letters,
               let receivedBonuses = data.bonuses,
               let roundNum = data.roundNumber,
               let endsAt = data.endsAt {
                currentRound = roundNum
                letters = receivedLetters
                bonuses = receivedBonuses.map { ($0.index, $0.type) }
                roundEndsAt = endsAt
                submitted = false
                opponentSubmitted = false
                myWord = ""
                myScore = 0
                oppWord = ""
                oppScore = 0
                
                matchState = .countdown
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    self.matchState = .playing
                    self.onRoundStart?()
                }
            }
            
        case .submission:
            // Opponent submitted
            opponentSubmitted = true
            oppWord = data.word ?? ""
            oppScore = data.score ?? 0
            onOpponentSubmitted?()
            checkBothSubmitted()
            
        case .roundResult:
            // Received from host (for non-host player)
            if let result = data.roundResult {
                myTotalScore = result.yourTotalScore
                oppTotalScore = result.oppTotalScore
                
                let roundResult = RoundResultData(
                    yourWord: result.yourWord,
                    yourScore: result.yourScore,
                    oppWord: result.oppWord,
                    oppScore: result.oppScore,
                    winner: result.winner,
                    yourTotalScore: result.yourTotalScore,
                    oppTotalScore: result.oppTotalScore,
                    roundNumber: result.roundNumber,
                    totalRounds: result.totalRounds
                )
                roundHistory.append(roundResult)
                matchState = .roundEnded
                onRoundEnd?(roundResult)
                
                if result.roundNumber >= result.totalRounds {
                    endMatch()
                }
            }
            
        case .matchResult:
            matchState = .matchEnded
        }
    }
    
    // MARK: - Cleanup
    
    func disconnect() {
        roundTimer?.invalidate()
        currentMatch?.disconnect()
        currentMatch = nil
        matchState = .idle
        resetMatchData()
    }
    
    private func resetMatchData() {
        opponentName = ""
        opponentId = ""
        isHost = false
        currentRound = 0
        letters = []
        bonuses = []
        roundEndsAt = 0
        submitted = false
        opponentSubmitted = false
        myWord = ""
        myScore = 0
        oppWord = ""
        oppScore = 0
        myTotalScore = 0
        oppTotalScore = 0
        roundHistory = []
        matchWinner = nil
    }
}

// MARK: - GKMatchDelegate

extension GameCenterService: GKMatchDelegate {
    nonisolated func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        Task { @MainActor in
            do {
                let gameData = try JSONDecoder().decode(GameData.self, from: data)
                handleReceivedData(gameData)
            } catch {
                print("Failed to decode game data: \(error)")
            }
        }
    }
    
    nonisolated func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        Task { @MainActor in
            switch state {
            case .connected:
                print("Player connected: \(player.displayName)")
                // Update opponent info
                if player.gamePlayerID != self.localPlayerId {
                    self.opponentName = player.displayName
                    self.opponentId = player.gamePlayerID
                    self.isHost = self.localPlayerId < self.opponentId
                    print("Opponent set: \(self.opponentName), I am host: \(self.isHost)")
                    
                    // If we're now the host and haven't started, start the round
                    if self.isHost && self.currentRound == 0 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.startRound()
                        }
                    }
                }
            case .disconnected:
                print("Player disconnected: \(player.displayName)")
                self.error = "Opponent disconnected"
                self.matchWinner = "you"  // Win by forfeit
                self.matchState = .matchEnded
                onMatchEnd?("you")
            default:
                break
            }
        }
    }
    
    nonisolated func match(_ match: GKMatch, didFailWithError error: Error?) {
        Task { @MainActor in
            self.error = "Match error: \(error?.localizedDescription ?? "Unknown")"
            self.matchState = .idle
        }
    }
}

// MARK: - Game Data Types

struct GameData: Codable {
    enum DataType: String, Codable {
        case roundStart
        case submission
        case roundResult
        case matchResult
    }
    
    let type: DataType
    var letters: [String]?
    var bonuses: [BonusData]?
    var word: String?
    var score: Int?
    var roundNumber: Int?
    var endsAt: Int?
    var roundResult: RoundResultPayload?
    
    struct BonusData: Codable {
        let index: Int
        let type: String
    }
    
    struct RoundResultPayload: Codable {
        let yourWord: String
        let yourScore: Int
        let oppWord: String
        let oppScore: Int
        let winner: String
        let yourTotalScore: Int
        let oppTotalScore: Int
        let roundNumber: Int
        let totalRounds: Int
    }
}
