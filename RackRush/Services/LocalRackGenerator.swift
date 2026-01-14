import Foundation

/// Local Rack Generator for offline gameplay
/// Matches server-side RackGenerator.ts logic
class LocalRackGenerator {
    static let shared = LocalRackGenerator()
    
    /// Letter frequencies (weighted for good gameplay)
    private let letterWeights: [(letter: String, weight: Int)] = [
        ("E", 12), ("T", 9), ("A", 8), ("O", 8), ("I", 7), ("N", 7),
        ("S", 6), ("H", 6), ("R", 6), ("D", 4), ("L", 4), ("C", 3),
        ("U", 3), ("M", 3), ("W", 2), ("F", 2), ("G", 2), ("Y", 2),
        ("P", 2), ("B", 2), ("V", 1), ("K", 1), ("J", 1), ("X", 1),
        ("Q", 1), ("Z", 1)
    ]
    
    private let vowels: Set<String> = ["A", "E", "I", "O", "U"]
    private let rareLetters: Set<String> = ["J", "K", "Q", "X", "Z"]
    
    private init() {}
    
    /// Generate a rack with given letter count
    func generate(letterCount: Int, minVowels: Int = 2, maxRare: Int = 1) -> (letters: [String], bonuses: [(index: Int, type: String)]) {
        var letters: [String] = []
        var vowelCount = 0
        var rareCount = 0
        
        // Build weighted pool
        var pool: [String] = []
        for (letter, weight) in letterWeights {
            for _ in 0..<weight {
                pool.append(letter)
            }
        }
        
        // Generate letters
        while letters.count < letterCount {
            guard let letter = pool.randomElement() else { break }
            
            // Enforce constraints
            if rareLetters.contains(letter) {
                if rareCount >= maxRare { continue }
                rareCount += 1
            }
            
            letters.append(letter)
            if vowels.contains(letter) {
                vowelCount += 1
            }
        }
        
        // Ensure minimum vowels
        while vowelCount < minVowels {
            // Replace a consonant with a vowel
            if let idx = letters.firstIndex(where: { !vowels.contains($0) && !rareLetters.contains($0) }) {
                let vowel = ["A", "E", "I", "O", "U"].randomElement()!
                letters[idx] = vowel
                vowelCount += 1
            } else {
                break
            }
        }
        
        // Shuffle
        letters.shuffle()
        
        // Generate bonuses (1-2 bonus tiles)
        var bonuses: [(index: Int, type: String)] = []
        let bonusTypes = ["DL", "TL", "DW"]
        let bonusCount = Int.random(in: 1...2)
        var usedIndices: Set<Int> = []
        
        for _ in 0..<bonusCount {
            var idx: Int
            repeat {
                idx = Int.random(in: 0..<letterCount)
            } while usedIndices.contains(idx)
            usedIndices.insert(idx)
            
            let type = bonusTypes.randomElement()!
            bonuses.append((index: idx, type: type))
        }
        
        return (letters, bonuses)
    }
}
