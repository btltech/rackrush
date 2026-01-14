import Foundation

@MainActor
struct ViralSharing {
    
    /// Generates a Wordle-style emoji grid for a match result
    static func generateEmojiGrid(from history: [RoundResult], winner: String?) -> String {
        var grid = ""
        
        for result in history {
            // win/loss/tie
            if result.winner == "you" {
                grid += "🟦" // Win (Teal in app)
            } else if result.winner == "opp" {
                grid += "🟧" // Loss (Warm/Red in app)
            } else {
                grid += "🟨" // Tie (Gold in app)
            }
        }
        
        return grid
    }
    
    /// Generates a full shareable text summary for a match
    static func generateShareText(gameState: GameState) -> String {
        let isWinner = gameState.myTotalScore > gameState.oppTotalScore
        let isTie = gameState.myTotalScore == gameState.oppTotalScore
        
        let trophy = isWinner ? "🏆" : (isTie ? "🤝" : "💀")
        let resultText = isWinner ? "VICTORY" : (isTie ? "TIE" : "DEFEAT")
        
        let grid = generateEmojiGrid(from: gameState.roundHistory, winner: gameState.matchWinner)
        
        var text = "RackRush Match \(trophy)\n"
        text += "\(resultText)\n\n"
        text += "\(grid)\n\n"
        text += "Me: \(gameState.myTotalScore) pts\n"
        text += "Opp: \(gameState.oppTotalScore) pts\n\n"
        text += "Play RackRush now! ⚡️"
        
        return text
    }
}
