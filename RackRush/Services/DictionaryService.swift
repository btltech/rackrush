import Foundation

/// Thread-safe actor for fetching word definitions from the Free Dictionary API
actor DictionaryService {
    static let shared = DictionaryService()
    
    private let baseURL = "https://api.dictionaryapi.dev/api/v2/entries/en/"
    private var cache: [String: WordDefinition] = [:]
    private var localKidsDefinitions: [String: String] = [:]
    private var isLocalKidsLoaded = false
    
    struct WordDefinition: Sendable {
        let word: String
        let phonetic: String?
        let partOfSpeech: String
        let definition: String
        let example: String?
    }
    
    /// Load local kids definitions from bundled JSON file
    private func loadLocalKidsDefinitions() {
        guard !isLocalKidsLoaded else { return }
        isLocalKidsLoaded = true
        
        guard let url = Bundle.main.url(forResource: "kids_definitions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            print("DictionaryService: Could not load local kids definitions")
            return
        }
        
        localKidsDefinitions = json
        print("DictionaryService: Loaded \(localKidsDefinitions.count) local kids definitions")
    }
    
    func fetchDefinition(for word: String) async -> WordDefinition? {
        let normalizedWord = word.lowercased()
        let upperWord = word.uppercased()
        
        // Check cache first (actor-isolated, so thread-safe)
        if let cached = cache[normalizedWord] {
            return cached
        }
        
        // For Kids Mode: check local definitions first (works offline)
        if KidsModeManager.shared.isEnabled {
            loadLocalKidsDefinitions()
            
            if let localDef = localKidsDefinitions[upperWord] {
                let wordDef = WordDefinition(
                    word: upperWord,
                    phonetic: nil,
                    partOfSpeech: "word",
                    definition: localDef,
                    example: nil
                )
                cache[normalizedWord] = wordDef
                return wordDef
            }
        }
        
        guard let encoded = normalizedWord.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: baseURL + encoded) else {
            return nil
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check for valid response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                   let firstResult = json.first,
                   let wordDef = parseDictionaryAPIResponse(firstResult, originalWord: word) {
                    
                    cache[normalizedWord] = wordDef
                    return wordDef
                }
            }
            
            // Tier 2: Fallback to Datamuse API (very high coverage)
            if let datamuseDef = await fetchFromDatamuse(for: normalizedWord) {
                cache[normalizedWord] = datamuseDef
                return datamuseDef
            }
            
            // Tier 3: Stemming Fallback (try removing common suffixes)
            if let stemmedDef = await tryStemmedWord(normalizedWord) {
                cache[normalizedWord] = stemmedDef
                return stemmedDef
            }
            
            return nil
        } catch {
            return nil
        }
    }
    
    private func parseDictionaryAPIResponse(_ result: [String: Any], originalWord: String) -> WordDefinition? {
        let phonetic = result["phonetic"] as? String
        
        guard let meanings = result["meanings"] as? [[String: Any]],
              let firstMeaning = meanings.first,
              let partOfSpeech = firstMeaning["partOfSpeech"] as? String,
              let definitions = definitionsFrom(meaning: firstMeaning),
              let firstDef = definitions.first,
              let definition = firstDef["definition"] as? String else {
            return nil
        }
        
        let example = firstDef["example"] as? String
        
        return WordDefinition(
            word: originalWord.uppercased(),
            phonetic: phonetic,
            partOfSpeech: partOfSpeech,
            definition: definition,
            example: example
        )
    }
    
    private func definitionsFrom(meaning: [String: Any]) -> [[String: Any]]? {
        return meaning["definitions"] as? [[String: Any]]
    }
    
    // MARK: - Datamuse Fallback
    private func fetchFromDatamuse(for word: String) async -> WordDefinition? {
        let urlString = "https://api.datamuse.com/words?sp=\(word)&md=d&max=1"
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
                  let firstResult = json.first,
                  let defs = firstResult["defs"] as? [String],
                  let firstRawDef = defs.first else {
                return nil
            }
            
            // Datamuse format: "n\tdefinition"
            let components = firstRawDef.components(separatedBy: "\t")
            let posAbbr = components.count > 1 ? components[0] : "n"
            let definition = components.count > 1 ? components[1] : components[0]
            
            let posMapping: [String: String] = [
                "n": "noun", "v": "verb", "adj": "adjective", "adv": "adverb", "u": "unknown"
            ]
            
            return WordDefinition(
                word: word.uppercased(),
                phonetic: nil,
                partOfSpeech: posMapping[posAbbr] ?? "word",
                definition: definition.prefix(1).uppercased() + definition.dropFirst(),
                example: nil
            )
        } catch {
            return nil
        }
    }
    
    // MARK: - Stemming Fallback
    private func tryStemmedWord(_ word: String) async -> WordDefinition? {
        let suffixes = ["s", "es", "ed", "ing", "ly"]
        
        for suffix in suffixes {
            if word.hasSuffix(suffix) {
                let stem = String(word.dropLast(suffix.count))
                if stem.count >= 3 {
                    // Recursive call to fetch root definition but keep original word
                    if let def = await fetchDefinition(for: stem) {
                        return WordDefinition(
                            word: word.uppercased(),
                            phonetic: def.phonetic,
                            partOfSpeech: def.partOfSpeech,
                            definition: "(Form of \(stem)): \(def.definition)",
                            example: def.example
                        )
                    }
                }
            }
        }
        return nil
    }

    
    func fetchDefinitions(for words: [String]) async -> [String: WordDefinition] {
        var results: [String: WordDefinition] = [:]
        
        // Use TaskGroup but each task calls back into the actor
        await withTaskGroup(of: (String, WordDefinition?).self) { group in
            for word in words where !word.isEmpty {
                group.addTask {
                    // This call is properly isolated to the actor
                    let definition = await self.fetchDefinition(for: word)
                    return (word, definition)
                }
            }
            
            for await (word, definition) in group {
                if let def = definition {
                    results[word.uppercased()] = def
                }
            }
        }
        
        return results
    }
    
    /// Clear the cache (useful for testing or memory pressure)
    func clearCache() {
        cache.removeAll()
    }
    
    /// Get cache statistics
    func cacheStats() -> (count: Int, words: [String]) {
        return (cache.count, Array(cache.keys))
    }
}
