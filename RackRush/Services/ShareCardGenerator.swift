import SwiftUI
import UIKit

/// Generates shareable emoji grid cards for match results (Wordle-style)
class ShareCardGenerator {
    static let shared = ShareCardGenerator()
    
    private init() {}
    
    /// Generate shareable text for a match result
    func generateShareText(
        myScore: Int,
        oppScore: Int,
        opponentName: String,
        roundHistory: [RoundResult],
        isWin: Bool
    ) -> String {
        var text = "RackRush Daily 🏆\n"
        text += isWin ? "VICTORY\n\n" : "GOOD GAME\n\n"
        
        // Emoji grid representing round wins
        let emojiGrid = generateEmojiGrid(roundHistory: roundHistory)
        text += emojiGrid + "\n\n"
        
        // Score summary
        text += "Me: \(myScore) pts\n"
        text += "\(opponentName): \(oppScore) pts\n\n"
        
        text += "Play now! ⚡️"
        
        return text
    }
    
    /// Generate emoji grid from round history
    private func generateEmojiGrid(roundHistory: [RoundResult]) -> String {
        var grid = ""
        
        for result in roundHistory {
            let emoji: String
            if result.yourScore > result.oppScore {
                emoji = "🟦" // Win - blue
            } else if result.yourScore < result.oppScore {
                emoji = "🟧" // Loss - orange
            } else {
                emoji = "🟨" // Tie - yellow
            }
            grid += emoji
        }
        
        return grid
    }
    
    /// Generate a visual share card image
    func generateShareImage(
        myScore: Int,
        oppScore: Int,
        opponentName: String,
        roundHistory: [RoundResult],
        isWin: Bool
    ) -> UIImage? {
        let width: CGFloat = 400
        let height: CGFloat = 500
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        
        let image = renderer.image { context in
            // Background gradient
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: [
                    UIColor(red: 0.11, green: 0.11, blue: 0.15, alpha: 1.0).cgColor,
                    UIColor(red: 0.15, green: 0.15, blue: 0.20, alpha: 1.0).cgColor
                ] as CFArray,
                locations: [0.0, 1.0]
            )!
            
            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: width/2, y: 0),
                end: CGPoint(x: width/2, y: height),
                options: []
            )
            
            // Title
            let titleText = "RackRush"
            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 36, weight: .black),
                .foregroundColor: UIColor.white
            ]
            let titleSize = titleText.size(withAttributes: titleAttributes)
            titleText.draw(
                at: CGPoint(x: (width - titleSize.width) / 2, y: 40),
                withAttributes: titleAttributes
            )
            
            // Result
            let resultText = isWin ? "VICTORY! 🏆" : "GOOD GAME"
            let resultAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: isWin ? UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0) : UIColor.white
            ]
            let resultSize = resultText.size(withAttributes: resultAttributes)
            resultText.draw(
                at: CGPoint(x: (width - resultSize.width) / 2, y: 100),
                withAttributes: resultAttributes
            )
            
            // Emoji grid
            let emojiGrid = generateEmojiGrid(roundHistory: roundHistory)
            let emojiAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40)
            ]
            let emojiSize = emojiGrid.size(withAttributes: emojiAttributes)
            emojiGrid.draw(
                at: CGPoint(x: (width - emojiSize.width) / 2, y: 160),
                withAttributes: emojiAttributes
            )
            
            // Scores
            let scoreY: CGFloat = 240
            
            // Your score
            let yourScoreText = "YOU"
            let yourScoreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.lightGray
            ]
            yourScoreText.draw(
                at: CGPoint(x: 80, y: scoreY),
                withAttributes: yourScoreAttributes
            )
            
            let yourScoreValue = "\(myScore)"
            let yourScoreValueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .black),
                .foregroundColor: UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 1.0)
            ]
            yourScoreValue.draw(
                at: CGPoint(x: 80, y: scoreY + 20),
                withAttributes: yourScoreValueAttributes
            )
            
            // Opponent score
            let oppScoreText = opponentName.uppercased()
            let oppScoreAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .bold),
                .foregroundColor: UIColor.lightGray
            ]
            let oppScoreSize = oppScoreText.size(withAttributes: oppScoreAttributes)
            oppScoreText.draw(
                at: CGPoint(x: width - 80 - oppScoreSize.width, y: scoreY),
                withAttributes: oppScoreAttributes
            )
            
            let oppScoreValue = "\(oppScore)"
            let oppScoreValueAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 48, weight: .black),
                .foregroundColor: UIColor(red: 1.0, green: 0.6, blue: 0.4, alpha: 1.0)
            ]
            let oppScoreValueSize = oppScoreValue.size(withAttributes: oppScoreValueAttributes)
            oppScoreValue.draw(
                at: CGPoint(x: width - 80 - oppScoreValueSize.width, y: scoreY + 20),
                withAttributes: oppScoreValueAttributes
            )
            
            // Footer
            let footerText = "Play now! ⚡️"
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 18, weight: .semibold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.8)
            ]
            let footerSize = footerText.size(withAttributes: footerAttributes)
            footerText.draw(
                at: CGPoint(x: (width - footerSize.width) / 2, y: height - 60),
                withAttributes: footerAttributes
            )
        }
        
        return image
    }
    
    /// Share match result via activity controller
    func shareMatchResult(
        from viewController: UIViewController,
        myScore: Int,
        oppScore: Int,
        opponentName: String,
        roundHistory: [RoundResult],
        isWin: Bool
    ) {
        let shareText = generateShareText(
            myScore: myScore,
            oppScore: oppScore,
            opponentName: opponentName,
            roundHistory: roundHistory,
            isWin: isWin
        )
        
        let shareImage = generateShareImage(
            myScore: myScore,
            oppScore: oppScore,
            opponentName: opponentName,
            roundHistory: roundHistory,
            isWin: isWin
        )
        
        var activityItems: [Any] = [shareText]
        if let image = shareImage {
            activityItems.append(image)
        }
        
        let activityController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Exclude some activity types
        activityController.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .print
        ]
        
        // For iPad
        if let popover = activityController.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        viewController.present(activityController, animated: true)
    }
}
