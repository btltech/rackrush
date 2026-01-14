import SwiftUI

struct RoundResultView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.theme) var theme
    @State private var showContent = false
    @State private var showDefinitions = false
    @State private var yourDefinition: DictionaryService.WordDefinition?
    @State private var oppDefinition: DictionaryService.WordDefinition?
    @State private var isLoadingDefinitions = true
    @State private var definitionTask: Task<Void, Never>?
    
    var result: RoundResult? {
        gameState.lastRoundResult
    }
    
    var isWinner: Bool {
        guard let r = result else { return false }
        return r.yourScore > r.oppScore
    }
    
    var isTie: Bool {
        guard let r = result else { return false }
        return r.yourScore == r.oppScore
    }
    
    var body: some View {
        ZStack {
            theme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                // Compact Header & Round Info
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(resultText)
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundStyle(resultGradient)
                        
                        Text("ROUND \(gameState.currentRoundNumber) OF \(gameState.totalRounds)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.textMuted)
                            .tracking(1)
                    }
                    
                    Spacer()
                    
                    // Total Score Mini-Badges
                    HStack(spacing: 8) {
                        TotalScoreBadge(score: gameState.myTotalScore, isPlayer: true)
                        TotalScoreBadge(score: gameState.oppTotalScore, isPlayer: false)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Active Round Score Comparison
                if let r = result {
                    Spacer(minLength: 16) // Proportional Space
                    
                    HStack(spacing: 16) {
                        ScoreColumn(
                            label: "YOU",
                            word: r.yourWord.uppercased(),
                            score: r.yourScore,
                            isWinner: isWinner && !isTie,
                            delay: 0.2
                        )
                        
                        ScoreColumn(
                            label: gameState.opponentName?.uppercased() ?? "OPP",
                            word: r.oppWord.uppercased(),
                            score: r.oppScore,
                            isWinner: !isWinner && !isTie,
                            delay: 0.4
                        )
                    }
                    .padding(.horizontal, 20)
                    .frame(maxHeight: 160) // Slightly increased max height for breathing room
                }
                
                Spacer(minLength: 16) // Proportional Space (The requested gap)
                
                // Definitions Section (Takes available space)
                if showDefinitions {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "book.fill")
                                .font(.system(size: 12))
                                .foregroundColor(theme.primary)
                            Text("DEFINITIONS")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(theme.textMuted)
                                .tracking(1)
                        }
                        .padding(.leading, 4)
                        
                        if isLoadingDefinitions {
                            HStack {
                                ProgressView().scaleEffect(0.8)
                                Text("Loading...")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            // Scrollable list that takes available space but doesn't push off screen
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 10) {
                                    if let yourDef = yourDefinition {
                                        DefinitionCard(definition: yourDef, isYours: true)
                                    } else if let r = result, !r.yourWord.isEmpty {
                                        DefinitionCard(word: r.yourWord.uppercased(), notFound: true, isYours: true)
                                    }
                                    
                                    if let oppDef = oppDefinition {
                                        DefinitionCard(definition: oppDef, isYours: false)
                                    } else if let r = result, !r.oppWord.isEmpty {
                                        DefinitionCard(word: r.oppWord.uppercased(), notFound: true, isYours: false)
                                    }
                                }
                                .padding(.bottom, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer(minLength: 16) // Proportional Space
                
                // Next Round Countdown (Fixed at bottom)
                if let nextStart = result?.nextRoundStartsAt {
                    NextRoundTimer(targetTime: nextStart)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                } else if let r = result, r.roundNumber < r.totalRounds {
                    // Offline/Game Center mode - show Continue button
                    Button(action: {
                        AudioManager.shared.playSubmit()
                        gameState.continueAfterRound()
                    }) {
                        Text("CONTINUE")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            // Audio feedback
            if isWinner {
                AudioManager.shared.playWin()
                HapticEngine.shared.roundWon()
            } else if !isTie {
                AudioManager.shared.playLose()
                HapticEngine.shared.roundLost()
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }
            
            // Show definitions section after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.5)) {
                    showDefinitions = true
                }
                fetchDefinitions()
            }
        }
        .onDisappear {
            definitionTask?.cancel()
        }
    }
    
    private func fetchDefinitions() {
        guard let r = result else {
            isLoadingDefinitions = false
            return
        }
        
        definitionTask = Task {
            async let yourDef = DictionaryService.shared.fetchDefinition(for: r.yourWord)
            async let oppDef = DictionaryService.shared.fetchDefinition(for: r.oppWord)
            
            let (your, opp) = await (yourDef, oppDef)
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                yourDefinition = your
                oppDefinition = opp
                isLoadingDefinitions = false
            }
        }
    }
    
    var resultColor: Color {
        if isTie { return theme.warning }
        return isWinner ? theme.success : theme.error
    }
    
    var resultIcon: String {
        if isTie { return "equal.circle.fill" }
        return isWinner ? "crown.fill" : "flag.checkered"
    }
    
    var resultText: String {
        if isTie { return "TIE!" }
        return isWinner ? "YOU WIN!" : "ROUND OVER"
    }
    
    var resultGradient: LinearGradient {
        if isTie { return LinearGradient(colors: [theme.warning, theme.warning.opacity(0.8)], startPoint: .top, endPoint: .bottom) }
        return isWinner ? theme.secondaryGradient : theme.accentGradient
    }
}

// MARK: - Definition Card
struct DefinitionCard: View {
    var definition: DictionaryService.WordDefinition? = nil
    var word: String = ""
    var notFound: Bool = false
    let isYours: Bool
    @Environment(\.theme) var theme
    
    var displayWord: String {
        definition?.word ?? word
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayWord.uppercased())
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(1)
                        .shimmer(duration: 5, delay: 1)
                    
                    if let phonetic = definition?.phonetic {
                        Text(phonetic)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textMuted)
                    }
                }
                
                Spacer()
                
                Text(isYours ? "YOURS" : "OPP")
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        isYours ? theme.secondaryGradient : theme.accentGradient
                    )
                    .clipShape(Capsule())
                    .shadow(color: (isYours ? theme.secondary : theme.accent).opacity(0.3), radius: 3)
            }
            
            Divider()
                .background(theme.surfaceHighlight.opacity(0.5))
            
            if notFound {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                    Text("Definition not listed")
                }
                .font(.system(size: 12, weight: .medium).italic())
                .foregroundColor(theme.textMuted)
            } else if let def = definition {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(def.partOfSpeech.uppercased())
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(theme.primary.opacity(0.8))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.primary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        
                        Text(def.definition)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    if let example = def.example {
                        Text("\"\(example)\"")
                            .font(.system(size: 12, weight: .medium).italic())
                            .foregroundColor(theme.textMuted)
                            .lineLimit(1)
                            .padding(.leading, 8)
                            .overlay(
                                Rectangle()
                                    .fill(theme.surfaceHighlight)
                                    .frame(width: 2)
                                    .padding(.vertical, 2),
                                alignment: .leading
                            )
                    }
                }
            }
        }
        .padding(12)
        .background(
            ZStack {
                GlassView(cornerRadius: 16, opacity: 0.8)
                
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .clear, .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: .black.opacity(0.2), radius: 15, y: 10)
    }
}

struct ScoreColumn: View {
    let label: String
    let word: String
    let score: Int
    let isWinner: Bool
    let delay: Double
    @Environment(\.theme) var theme
    
    @State private var showScore = false
    
    var body: some View {
        VStack(spacing: 10) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(theme.textMuted)
                .tracking(1)
            
            if word.isEmpty {
                Text("PASSED")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(theme.textMuted)
                    .tracking(2)
            } else {
                HStack(spacing: 4) {
                    ForEach(Array(word.enumerated()), id: \.offset) { _, char in
                        Text(String(char))
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 24, height: 28)
                            .background(theme.surfaceLight)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
                .shimmer(duration: 4, delay: delay + 0.5)
            }
            
            Text("\(score)")
                .font(.system(size: 48, weight: .black, design: .rounded))
                .foregroundStyle(isWinner ? theme.secondaryGradient : LinearGradient(colors: [theme.textSecondary, theme.textSecondary], startPoint: .top, endPoint: .bottom))
                .shadow(color: (isWinner ? theme.secondary : .clear).opacity(0.3), radius: 10)
                .scaleEffect(showScore ? 1 : 0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            ZStack {
                GlassView(cornerRadius: 24, opacity: isWinner ? 1 : 0.6)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(isWinner ? theme.primary.opacity(0.05) : Color.clear)
                    )
                
                if isWinner {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [theme.secondary.opacity(0.5), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                } else {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.surfaceHighlight, lineWidth: 1)
                }
            }
        )
        .shadow(color: (isWinner ? theme.secondary : .black).opacity(0.15), radius: 15, y: 10)
        .onAppear {
            withAnimation(.spring(response: 0.5).delay(delay)) {
                showScore = true
            }
        }
    }
}

struct TotalScoreBadge: View {
    let score: Int
    let isPlayer: Bool
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 2) {
            Text(isPlayer ? "YOU" : "OPP")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(theme.textMuted)
            Text("\(score)")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(isPlayer ? theme.secondaryGradient : theme.accentGradient)
        }
        .frame(width: 60, height: 54)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct NextRoundTimer: View {
    let targetTime: Int // Unix timestamp in ms
    @State private var timeRemaining: Int = 0
    @State private var updateTimer: Timer?
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 12) {
            if timeRemaining > 0 {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(0.8)
                
                Text("Next round starts in \(String(format: "%.1f", Double(timeRemaining) / 1000.0))s")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            } else {
                Text("Starting next round...")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            GlassView(opacity: 0.3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.surfaceHighlight, lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            updateTime()
            updateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                updateTime()
            }
        }
        .onDisappear {
            updateTimer?.invalidate()
        }
    }
    
    private func updateTime() {
        let now = Int(Date().timeIntervalSince1970 * 1000)
        timeRemaining = max(0, targetTime - now)
    }
}

// MARK: - Match Result View
struct MatchResultView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.theme) var theme
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var showFirstWinCelebration = false
    @StateObject private var achievementSystem = AchievementSystem.shared
    
    var isWinner: Bool {
        gameState.myTotalScore > gameState.oppTotalScore
    }
    
    var body: some View {
        ZStack {
            theme.backgroundPrimary
                .ignoresSafeArea()
            
            // Confetti for winner
            if showConfetti && isWinner {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                // Trophy or result
                VStack(spacing: 20) {
                    if isWinner {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(theme.successGradient)
                            .shadow(color: theme.success.opacity(0.5), radius: 20)
                    } else {
                        Image(systemName: "xmark.shield.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(theme.accentGradient)
                    }
                    
                    Text(isWinner ? "VICTORY!" : "GOOD GAME")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(isWinner ? theme.successGradient : theme.secondaryGradient)
                }
                .scaleEffect(showContent ? 1 : 0.7)
                .opacity(showContent ? 1 : 0)
                
                // Final score
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("YOU")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.textMuted)
                        Text("\(gameState.myTotalScore)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(theme.secondaryGradient)
                        Text("TOTAL")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(theme.textMuted)
                    }
                    
                    Text("-")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(theme.textMuted)
                    
                    VStack(spacing: 4) {
                        Text(gameState.opponentName?.uppercased() ?? "FRIEND")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.textMuted)
                        Text("\(gameState.oppTotalScore)")
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundStyle(theme.accentGradient)
                        Text("TOTAL")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(theme.textMuted)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 40)
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                Spacer()
                
                // Actions
                VStack(spacing: 16) {
                    // Unified Premium Share Button
                    Button(action: {
                        AudioManager.shared.playTap()
                        let text = ViralSharing.generateShareText(gameState: gameState)
                        let image = ShareCardGenerator.shared.generateShareImage(
                            myScore: gameState.myTotalScore,
                            oppScore: gameState.oppTotalScore,
                            opponentName: gameState.opponentName ?? "Opponent",
                            roundHistory: gameState.roundHistory,
                            isWin: isWinner
                        )
                        ShareSheet.share(text: text, image: image)
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.up")
                            Text("SHARE RESULTS")
                        }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.secondaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: theme.secondary.opacity(0.4), radius: 12, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.surfaceHighlight.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .padding(.bottom, 8)

                    Button(action: {
                        AudioManager.shared.playSubmit()
                        gameState.screen = .modeSelect
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("PLAY AGAIN")
                        }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(theme.primaryGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: theme.primary.opacity(0.4), radius: 12, y: 4)
                    }
                    .padding(.bottom, 8)
                    
                    Button(action: {
                        AudioManager.shared.playTap()
                        gameState.screen = .home
                    }) {
                        Text("Back to Home")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .overlay {
            if showFirstWinCelebration {
                FirstWinCelebration(isPresented: $showFirstWinCelebration)
            }
        }
        .overlay {
            if achievementSystem.showUnlockNotification, let achievement = achievementSystem.recentlyUnlocked {
                AchievementUnlockView(achievement: achievement, isPresented: $achievementSystem.showUnlockNotification)
            }
        }
        .onAppear {
            // Check for first win
            if isWinner && !gameState.hasSeenFirstWin && gameState.totalWins == 1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showFirstWinCelebration = true
                    gameState.hasSeenFirstWin = true
                }
            }
            
            // Audio & Haptic feedback
            if isWinner {
                AudioManager.shared.playWin()
                HapticEngine.shared.matchWon()
            } else {
                AudioManager.shared.playLose()
                HapticEngine.shared.roundLost()
            }
            
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                showContent = true
            }
            
            if isWinner {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showConfetti = true
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func generateShareItems() -> [Any] {
        let shareText = ShareCardGenerator.shared.generateShareText(
            myScore: gameState.myTotalScore,
            oppScore: gameState.oppTotalScore,
            opponentName: gameState.opponentName ?? "Opponent",
            roundHistory: gameState.roundHistory,
            isWin: isWinner
        )
        
        var items: [Any] = [shareText]
        
        if let shareImage = ShareCardGenerator.shared.generateShareImage(
            myScore: gameState.myTotalScore,
            oppScore: gameState.oppTotalScore,
            opponentName: gameState.opponentName ?? "Opponent",
            roundHistory: gameState.roundHistory,
            isWin: isWinner
        ) {
            items.append(shareImage)
        }
        
        return items
    }
}

#Preview("Round Result") {
    RoundResultView()
        .environmentObject(GameState())
}

#Preview("Match Result") {
    MatchResultView()
        .environmentObject(GameState())
}
