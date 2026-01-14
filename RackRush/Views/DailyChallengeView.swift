import SwiftUI

struct DailyChallengeView: View {
    @StateObject private var challengeManager = DailyChallengeManager.shared
    @EnvironmentObject var gameState: GameState
    @Environment(\.theme) var theme
    
    @State private var currentWord: String = ""
    @State private var showResult = false
    @State private var submittedScore: Int = 0
    @State private var submittedWord: String = ""
    
    var body: some View {
        ZStack {
            theme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                DailyChallengeHeader(
                    streak: challengeManager.currentStreak,
                    onBack: { gameState.screen = .home }
                )
                
                if challengeManager.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(.white)
                    Text("Loading challenge...")
                        .foregroundColor(theme.textSecondary)
                        .padding()
                    Spacer()
                } else if challengeManager.hasCompletedToday {
                    // Result view
                    DailyChallengeResultView(
                        score: challengeManager.bestScore,
                        percentile: challengeManager.percentileRank,
                        streak: challengeManager.currentStreak
                    )
                } else if let challenge = challengeManager.todayChallenge {
                    Spacer()
                    
                    // Word display
                    HStack(spacing: 8) {
                        if currentWord.isEmpty {
                            Text("TAP LETTERS TO BUILD A WORD")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(theme.textMuted)
                        } else {
                            ForEach(Array(currentWord.enumerated()), id: \.offset) { _, char in
                                Text(String(char))
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(theme.primaryGradient)
                                    .frame(width: 40, height: 48)
                                    .background(theme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .frame(minHeight: 60)
                    .padding()
                    
                    // Letter rack
                    DailyLetterRack(
                        letters: challenge.letters,
                        bonuses: challenge.bonuses,
                        currentWord: $currentWord,
                        hasSubmitted: challengeManager.hasCompletedToday
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Actions
                    DailyActionButtons(
                        currentWord: $currentWord,
                        hasSubmitted: challengeManager.hasCompletedToday,
                        onSubmit: submitWord
                    )
                    .padding()
                }
            }
        }
        .onAppear {
            challengeManager.loadTodayChallenge()
        }
    }
    
    private func submitWord() {
        guard !currentWord.isEmpty, !challengeManager.hasCompletedToday else { return }
        
        // Validate word
        let validation = LocalDictionary.shared.validate(currentWord, rack: challengeManager.todayChallenge?.letters ?? [])
        
        guard validation.valid else {
            // Show error
            AudioManager.shared.playError()
            return
        }
        
        // Calculate score with bonuses
        let score = calculateScore(word: currentWord, bonuses: challengeManager.todayChallenge?.bonuses ?? [])
        
        // Submit to manager
        challengeManager.submitScore(score, word: currentWord)
        
        submittedScore = score
        submittedWord = currentWord
    }
    
    private func calculateScore(word: String, bonuses: [BonusTile]) -> Int {
        // Use proper Scrabble-style scoring from LocalScorer
        let bonusTuples = bonuses.map { (index: $0.index, type: $0.type) }
        return LocalScorer.shared.calculate(
            word: word,
            rack: challengeManager.todayChallenge?.letters ?? [],
            bonuses: bonusTuples
        )
    }
}

// MARK: - Header

struct DailyChallengeHeader: View {
    let streak: Int
    let onBack: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack {
            Button(action: {
                AudioManager.shared.playTap()
                onBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(theme.surface)
                    .clipShape(Circle())
            }
            
            Spacer()
            
            VStack(spacing: 4) {
                Text("DAILY CHALLENGE")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            // Streak badge
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 16))
                    .foregroundColor(streak > 0 ? .orange : theme.textMuted)
                Text("\(streak)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(theme.surface)
            .clipShape(Capsule())
        }
        .padding()
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}

// MARK: - Result View

struct DailyChallengeResultView: View {
    let score: Int
    let percentile: Double?
    let streak: Int
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Trophy icon
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "FFD700").opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 160, height: 160)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(theme.successGradient)
            }
            
            VStack(spacing: 8) {
                Text("Challenge Complete!")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your Score")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textSecondary)
                
                Text("\(score)")
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(theme.primaryGradient)
                
                if let percentile = percentile, percentile > 0 {
                    Text("Top \(Int(100 - percentile))%")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.success)
                        .padding(.top, 4)
                }
            }
            
            // Streak info
            if streak > 1 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak) Day Streak!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(theme.surface)
                .clipShape(Capsule())
            }
            
            Text("Come back tomorrow for a new challenge!")
                .font(.system(size: 14))
                .foregroundColor(theme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.top, 16)
            
            Spacer()
        }
        .padding(32)
    }
}

// MARK: - Letter Rack (reuse from existing)

struct DailyLetterRack: View {
    let letters: [String]
    let bonuses: [BonusTile]
    @Binding var currentWord: String
    let hasSubmitted: Bool
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: min(5, letters.count)), spacing: 8) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                PremiumTile(
                    letter: letter,
                    bonus: bonuses.first { $0.index == index }?.type,
                    isUsed: isLetterUsed(at: index),
                    isDisabled: hasSubmitted
                ) {
                    addLetter(letter)
                }
            }
        }
    }
    
    private func isLetterUsed(at index: Int) -> Bool {
        var usedIndices: [Int] = []
        for char in currentWord {
            if let idx = letters.enumerated().first(where: { !usedIndices.contains($0.offset) && $0.element == String(char) })?.offset {
                usedIndices.append(idx)
            }
        }
        return usedIndices.contains(index)
    }
    
    private func addLetter(_ letter: String) {
        guard !hasSubmitted else { return }
        
        let usedLetters = Array(currentWord)
        var availableLetters = letters
        
        for used in usedLetters {
            if let idx = availableLetters.firstIndex(of: String(used)) {
                availableLetters.remove(at: idx)
            }
        }
        
        if availableLetters.contains(letter) {
            AudioManager.shared.playTap()
            currentWord += letter
        }
    }
}

// MARK: - Action Buttons (reuse from existing)

struct DailyActionButtons: View {
    @Binding var currentWord: String
    let hasSubmitted: Bool
    let onSubmit: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                AudioManager.shared.playTap()
                currentWord = ""
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(theme.surface)
                    .clipShape(Circle())
            }
            .disabled(currentWord.isEmpty || hasSubmitted)
            
            Button(action: {
                AudioManager.shared.playTap()
                if !currentWord.isEmpty {
                    currentWord.removeLast()
                }
            }) {
                Image(systemName: "delete.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(theme.surface)
                    .clipShape(Circle())
            }
            .disabled(currentWord.isEmpty || hasSubmitted)
            
            Button(action: {
                AudioManager.shared.playSubmit()
                onSubmit()
            }) {
                HStack {
                    Image(systemName: hasSubmitted ? "checkmark" : "paperplane.fill")
                    Text(hasSubmitted ? "SUBMITTED" : "SUBMIT")
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if hasSubmitted {
                            theme.success
                        } else {
                            theme.accentGradient
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .disabled(currentWord.isEmpty || hasSubmitted)
        }
    }
}

#Preview {
    DailyChallengeView()
        .environmentObject(GameState())
}
