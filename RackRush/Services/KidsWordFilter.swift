import Foundation

// MARK: - Kids Word Filter
/// Filters inappropriate words for child-safe gameplay

class KidsWordFilter {
    static let shared = KidsWordFilter()
    
    // MARK: - Blocklist Categories
    
    /// Universal blocklist - inappropriate for all ages
    private let universalBlocklist: Set<String> = [
        // Profanity (common)
        "ass", "arse", "damn", "darn", "hell", "crap",
        "piss", "shit", "fuck", "bitch", "slut", "whore",
        "cock", "dick", "pussy", "tits", "boob", "nude",
        "naked", "sexy", "porn", "sex", "rape", "molest",
        
        // Slurs (abbreviated list - would be expanded)
        "fag", "homo", "retard", "spaz", "gimp",
        
        // Violence
        "kill", "murder", "stab", "shoot", "gun", "bomb",
        "dead", "death", "die", "died", "blood", "bleed",
        "gore", "torture", "hang", "drown", "strangle",
        "weapon", "knife", "sword", "bullet", "war",
        
        // Drugs & Alcohol
        "drug", "drugs", "cocaine", "heroin", "meth",
        "weed", "marijuana", "pot", "drunk", "beer",
        "wine", "vodka", "whiskey", "alcohol", "smoke",
        "vape", "cigarette", "tobacco",
        
        // Adult concepts
        "divorce", "affair", "adultery", "pregnant",
        "abortion", "condom",
        
        // Hate/negativity
        "hate", "hater", "loser", "stupid", "dumb",
        "idiot", "moron", "ugly", "fat", "skinny",
        
        // Gambling
        "gamble", "betting", "casino", "poker"
    ]
    
    /// Scary words - filtered for ages 4-6
    private let scaryWordsForYoung: Set<String> = [
        // Monsters/scary
        "monster", "ghost", "zombie", "vampire", "witch",
        "demon", "devil", "evil", "scary", "creepy",
        "dark", "darkness", "nightmare", "scream",
        
        // Mild violence (okay for older kids)
        "fight", "punch", "kick", "hit", "hurt",
        "pain", "ache", "sick", "ill", "fever",
        
        // Danger
        "danger", "dangerous", "poison", "toxic",
        "fire", "burn", "drown", "fall", "crash",
        
        // Negative emotions (can be confusing for young kids)
        "sad", "angry", "mad", "cry", "crying",
        "fear", "afraid", "scared", "worry", "worried"
    ]
    
    /// Complex/mature words - filtered for ages 4-6
    private let complexWordsForYoung: Set<String> = [
        // Financial
        "money", "bank", "debt", "loan", "tax",
        
        // Legal/political
        "court", "judge", "jail", "prison", "police",
        "crime", "criminal", "guilty", "arrest",
        
        // Medical
        "hospital", "surgery", "cancer", "disease"
    ]
    
    // MARK: - Filtering
    
    /// Check if word is appropriate for the given age group
    func isAppropriate(_ word: String, forAge ageGroup: KidsModeManager.AgeGroup) -> Bool {
        let lowercased = word.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Empty or too short
        guard lowercased.count >= 2 else { return false }
        
        // Universal blocklist applies to all
        if universalBlocklist.contains(lowercased) {
            return false
        }
        
        // Check for blocklist words contained in longer words
        for blocked in universalBlocklist {
            if lowercased.contains(blocked) && lowercased.count > blocked.count {
                // Word contains blocked substring
                // Only block if it's a recognizable compound
                if lowercased.hasPrefix(blocked) || lowercased.hasSuffix(blocked) {
                    return false
                }
            }
        }
        
        // Age-specific filtering
        switch ageGroup {
        case .young:
            // Filter scary and complex words for youngest
            if scaryWordsForYoung.contains(lowercased) { return false }
            if complexWordsForYoung.contains(lowercased) { return false }
        case .medium:
            // Only filter very scary words
            let veryScary: Set<String> = ["monster", "demon", "devil", "zombie", "vampire"]
            if veryScary.contains(lowercased) { return false }
        case .older:
            // Universal blocklist only
            break
        }
        
        return true
    }
    
    /// Filter a list of words for appropriateness
    func filterWords(_ words: [String], forAge ageGroup: KidsModeManager.AgeGroup) -> [String] {
        words.filter { isAppropriate($0, forAge: ageGroup) }
    }
    
    /// Get a kid-friendly rejection message
    func rejectionMessage(for ageGroup: KidsModeManager.AgeGroup) -> String {
        switch ageGroup {
        case .young:
            return "Try another word! 🌟"
        case .medium:
            return "Let's try a different word! ✨"
        case .older:
            return "That word isn't available. Try another!"
        }
    }
}

// MARK: - Safe Rack Generation
extension KidsWordFilter {
    
    /// Letters to exclude for young children (too difficult)
    private var hardLetters: Set<Character> {
        ["Q", "X", "Z", "J"]
    }
    
    /// Common, easy letters for kids
    private var easyLetters: [Character] {
        ["A", "E", "I", "O", "U", // Vowels
         "T", "N", "S", "R", "L", // Common consonants
         "C", "D", "M", "P", "B", // More common
         "G", "H", "K", "W", "Y"] // Moderately common
    }
    
    /// Generate a kid-friendly letter rack
    func generateKidsRack(for ageGroup: KidsModeManager.AgeGroup) -> [Character] {
        var rack: [Character] = []
        let count = ageGroup.letterCount
        let vowelCount = Int(Double(count) * ageGroup.vowelRatio)
        
        let vowels: [Character] = ["A", "E", "I", "O", "U"]
        let consonants: [Character] = ageGroup.allowHardLetters
            ? ["B", "C", "D", "F", "G", "H", "J", "K", "L", "M", "N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"]
            : ["B", "C", "D", "F", "G", "H", "K", "L", "M", "N", "P", "R", "S", "T", "V", "W", "Y"]
        
        // Add vowels
        for _ in 0..<vowelCount {
            rack.append(vowels.randomElement()!)
        }
        
        // Add consonants
        for _ in vowelCount..<count {
            rack.append(consonants.randomElement()!)
        }
        
        // Shuffle
        rack.shuffle()
        
        return rack
    }
    
    /// Validate that a rack can form at least one valid word
    func rackHasValidWord(_ rack: [Character], ageGroup: KidsModeManager.AgeGroup) -> Bool {
        // Simple check: if it has a vowel and 2+ consonants, likely valid
        let vowelCount = rack.filter { "AEIOU".contains($0) }.count
        let consonantCount = rack.count - vowelCount
        return vowelCount >= 1 && consonantCount >= 1
    }
}
