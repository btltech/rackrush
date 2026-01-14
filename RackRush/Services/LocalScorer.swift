import Foundation

/// Local Scorer for offline score calculation
/// Matches server-side Scorer.ts logic
class LocalScorer {
    static let shared = LocalScorer()
    
    /// Letter point values (Scrabble-style)
    private let letterValues: [Character: Int] = [
        "A": 1, "B": 3, "C": 3, "D": 2, "E": 1, "F": 4, "G": 2, "H": 4, "I": 1,
        "J": 8, "K": 5, "L": 1, "M": 3, "N": 1, "O": 1, "P": 3, "Q": 10, "R": 1,
        "S": 1, "T": 1, "U": 1, "V": 4, "W": 4, "X": 8, "Y": 4, "Z": 10
    ]
    
    /// Length bonuses
    private let lengthBonuses: [Int: Int] = [
        6: 2,
        7: 5,
        8: 8,
        9: 12,
        10: 12
    ]
    
    private init() {}
    
    /// Calculate score for a word with bonus tiles
    func calculate(word: String, rack: [String], bonuses: [(index: Int, type: String)]) -> Int {
        guard !word.isEmpty else { return 0 }
        
        let upperWord = word.uppercased()
        
        // Map each letter in word to rack position
        guard let usedIndices = mapWordToRack(upperWord, rack: rack) else {
            return 0 // Word can't be built from rack
        }
        
        // Create bonus lookup
        var bonusMap: [Int: String] = [:]
        for bonus in bonuses {
            bonusMap[bonus.index] = bonus.type
        }
        
        var baseScore = 0
        var wordMultiplier = 1
        
        // Calculate letter scores with bonuses
        for (i, char) in upperWord.enumerated() {
            let rackIdx = usedIndices[i]
            var letterScore = letterValues[char] ?? 0
            
            // Apply letter bonuses
            if let bonusType = bonusMap[rackIdx] {
                switch bonusType {
                case "DL":
                    letterScore *= 2
                case "TL":
                    letterScore *= 3
                case "DW":
                    wordMultiplier *= 2
                default:
                    break
                }
            }
            
            baseScore += letterScore
        }
        
        // Apply word multiplier
        var finalScore = baseScore * wordMultiplier
        
        // Apply length bonus
        let lengthBonus = lengthBonuses[upperWord.count] ?? (upperWord.count > 10 ? 12 : 0)
        finalScore += lengthBonus
        
        return finalScore
    }
    
    /// Map each character in word to a rack index
    private func mapWordToRack(_ word: String, rack: [String]) -> [Int]? {
        let rackUpper = rack.map { $0.uppercased() }
        var usedIndices: Set<Int> = []
        var result: [Int] = []
        
        for char in word {
            var found = false
            for (i, letter) in rackUpper.enumerated() {
                if letter.first == char && !usedIndices.contains(i) {
                    usedIndices.insert(i)
                    result.append(i)
                    found = true
                    break
                }
            }
            if !found { return nil }
        }
        
        return result
    }
    
    /// Get base letter value (for UI display)
    func getLetterValue(_ letter: String) -> Int {
        guard let char = letter.uppercased().first else { return 0 }
        return letterValues[char] ?? 0
    }
}
