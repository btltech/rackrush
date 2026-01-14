import SwiftUI

struct MatchView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.theme) var theme
    @Namespace private var tileNamespace
    @State private var timeRemaining: Int = 30
    @State private var timer: Timer?
    @State private var shakeWord = false
    @State private var showSubmitPulse = false
    @State private var lastTimerWarning: Int = 100
    @State private var showCountdown = false
    
    // Settings
    @AppStorage("showTimer") private var showTimer = true
    
    // Computed total time from server
    private var totalTime: Int {
        max(1, gameState.roundDurationMs / 1000)
    }
    
    var body: some View {
        ZStack {
            // Dynamic background
            theme.backgroundPrimary
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                MatchHeader(
                    round: gameState.currentRound,
                    totalRounds: gameState.totalRounds,
                    myTotalScore: gameState.myTotalScore,
                    oppTotalScore: gameState.oppTotalScore,
                    opponentName: gameState.opponentName ?? "Opponent",
                    isBot: gameState.opponentIsBot
                )
                
                Spacer()
                
                // Timer (conditionally shown based on settings)
                if showTimer {
                    PremiumTimerBar(
                        timeRemaining: timeRemaining,
                        totalTime: totalTime
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                
                // Word display with flying tile destinations
                AnimatedWordBuilder(
                    word: gameState.currentWord,
                    shake: shakeWord,
                    namespace: tileNamespace
                )
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Letter rack with flying tile sources
                AnimatedLetterRack(
                    letters: gameState.letters,
                    bonuses: gameState.bonuses,
                    currentWord: gameState.currentWord,
                    isSubmitted: gameState.submitted,
                    namespace: tileNamespace,
                    onLetterTap: { letter in
                        // Haptic: Tile pickup
                        HapticEngine.shared.tilePickUp()
                        // Audio: Rising note based on flow
                        AudioSynthesizer.shared.onLetterTyped()
                        // Add letter
                        gameState.addLetter(letter)
                        // Haptic: Tile drop (delayed for animation)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            HapticEngine.shared.tileDrop()
                        }
                    }
                )
                .padding(.horizontal, 16)
                
                Spacer()
                
                // Action buttons
                ActionButtonRow(
                    currentWord: gameState.currentWord,
                    isSubmitted: gameState.submitted,
                    onClear: {
                        HapticEngine.shared.wordClear()
                        AudioSynthesizer.shared.resetFlow()
                        gameState.clearWord()
                    },
                    onDelete: {
                        HapticEngine.shared.tileRemove()
                        gameState.removeLetter()
                    },
                    onSubmit: {
                        if gameState.currentWord.count >= 3 {
                            HapticEngine.shared.wordSubmit()
                            AudioSynthesizer.shared.playSuccessChord()
                            AudioSynthesizer.shared.resetFlow()
                            gameState.submitWord()
                            showSubmitPulse = true
                        } else {
                            HapticEngine.shared.error()
                            AudioSynthesizer.shared.playErrorSound()
                            shakeWord = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                shakeWord = false
                            }
                        }
                    }
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            
            // Opponent submitted overlay
            if gameState.opponentSubmitted && !gameState.submitted {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("Opponent submitted!")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(theme.warning.opacity(0.9))
                            .clipShape(Capsule())
                            .shadow(color: theme.warning.opacity(0.3), radius: 8)
                        Spacer()
                    }
                    .padding(.bottom, 100)
                }
            }
        }
        .overlay {
            if showCountdown {
                CountdownOverlay(seconds: 3) {
                    showCountdown = false
                    startTimer()
                }
            }
        }
        .overlay {
            if gameState.showTutorialOverlay {
                TutorialOverlay(gameState: gameState, isActive: $gameState.showTutorialOverlay)
            }
        }
        .onAppear {
            // Show tutorial on first bot match if not completed
            if !gameState.hasCompletedTutorial && gameState.matchType == .bot && gameState.totalMatchesPlayed == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    gameState.showTutorialOverlay = true
                }
            }
            startRoundSequence()
        }
        .onDisappear {
            timer?.invalidate()
            AudioSynthesizer.shared.resetFlow()
        }
        .onChange(of: timeRemaining) { newValue in
            // Timer haptics
            if newValue <= 5 && newValue > 0 && newValue != lastTimerWarning {
                HapticEngine.shared.timerCritical()
                lastTimerWarning = newValue
            } else if newValue <= 10 && newValue > 5 && newValue != lastTimerWarning {
                HapticEngine.shared.timerWarning()
                lastTimerWarning = newValue
            }
        }
        .onChange(of: gameState.currentRound) { _ in
            startRoundSequence()
        }
    }
    
    private func startRoundSequence() {
        timer?.invalidate() // Stop any existing timer
        
        if gameState.roundDelayMs > 0 {
            showCountdown = true
        } else {
            showCountdown = false
            startTimer()
        }
    }
    
    private func startTimer() {
        let endTime = gameState.roundEndsAt
        
        // Prevent starting timer if round hasn't truly started (e.g. initial load before sync)
        if endTime == 0 { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
            let remaining = max(0, (endTime - Int(Date().timeIntervalSince1970 * 1000)) / 1000)
            timeRemaining = remaining
            
            // Auto-stop at 0 to prevent negative
            if remaining == 0 {
                timer?.invalidate()
            }
        }
    }
}

// MARK: - Animated Word Builder (Flying Tile Destinations)
struct AnimatedWordBuilder: View {
    let word: String
    let shake: Bool
    let namespace: Namespace.ID
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            if word.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textMuted)
                    
                    Text("TAP LETTERS")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textMuted)
                        .tracking(1)
                }
            } else {
                ForEach(Array(word.enumerated()), id: \.offset) { index, char in
                    if KidsModeManager.shared.isEnabled {
                        // Kids Style Builder Tile
                        Text(String(char))
                            .font(KidsTypography.tileLetter)
                            .foregroundColor(.white)
                            .frame(width: 48, height: 56) // Slightly larger for kids
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(
                                        LinearGradient(
                                            colors: [KidsColors.tileColor(for: String(char)), KidsColors.tileColor(for: String(char)).opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.2), radius: 2, y: 2)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.4), lineWidth: 2)
                            )
                            .matchedGeometryEffect(id: "letter_\(index)_\(char)", in: namespace, isSource: false)
                            .transition(.scale)
                    } else {
                        // Premium Style Builder Tile
                        Text(String(char))
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryGradient)
                            .frame(width: 42, height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: Corners.md)
                                    .fill(theme.surface)
                                    .shadow(color: theme.primary.opacity(0.2), radius: 8, y: 4)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Corners.md)
                                    .stroke(theme.primary.opacity(0.4), lineWidth: 1.5)
                            )
                            .matchedGeometryEffect(id: "letter_\(index)_\(char)", in: namespace, isSource: false)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.5).combined(with: .opacity),
                                removal: .scale(scale: 0.8).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: Corners.lg)
                .fill(theme.backgroundSecondary.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: Corners.lg)
                        .stroke(theme.surfaceHighlight.opacity(0.5), lineWidth: 1)
                )
        )
        .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: word)
    }
}

// MARK: - Animated Letter Rack (Flying Tile Sources)
struct AnimatedLetterRack: View {
    let letters: [String]
    let bonuses: [BonusTile]
    let currentWord: String
    let isSubmitted: Bool
    let namespace: Namespace.ID
    let onLetterTap: (String) -> Void
    @Environment(\.theme) var theme
    
    private func isUsed(_ letter: String, at index: Int) -> Bool {
        var usedIndices: [Int] = []
        for char in currentWord {
            if let idx = letters.enumerated().first(where: { !usedIndices.contains($0.offset) && $0.element == String(char) })?.offset {
                usedIndices.append(idx)
            }
        }
        return usedIndices.contains(index)
    }
    
    private func wordIndex(for rackIndex: Int) -> Int? {
        var usedIndices: [Int] = []
        var wordPositions: [Int: Int] = [:]
        
        for (wordIdx, char) in currentWord.enumerated() {
            if let idx = letters.enumerated().first(where: { !usedIndices.contains($0.offset) && $0.element == String(char) })?.offset {
                usedIndices.append(idx)
                wordPositions[idx] = wordIdx
            }
        }
        return wordPositions[rackIndex]
    }
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: min(5, letters.count))
        
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                let used = isUsed(letter, at: index)
                let bonus = bonuses.first { $0.index == index }?.type
                
                ZStack {
                    // Placeholder when tile is "flying"
                    if used {
                        RoundedRectangle(cornerRadius: Corners.md)
                            .fill(theme.surface.opacity(0.3))
                            .frame(height: 72)
                    }
                    
                    // Actual tile (hidden when used)
                    if !used {
                        if KidsModeManager.shared.isEnabled {
                            KidsTile(
                                letter: letter,
                                isUsed: false,
                                isDisabled: isSubmitted,
                                onTap: {
                                    if !used && !isSubmitted {
                                        onLetterTap(letter)
                                    }
                                }
                            )
                            .scaleEffect(0.8) // Scale down slightly to fit grid
                            .matchedGeometryEffect(
                                id: "letter_\(wordIndex(for: index) ?? index)_\(letter)",
                                in: namespace,
                                isSource: true
                            )
                        } else {
                            PremiumTile(
                                letter: letter,
                                bonus: bonus,
                                isUsed: false,
                                isDisabled: isSubmitted
                            ) {
                                if !used && !isSubmitted {
                                    onLetterTap(letter)
                                }
                            }
                            .matchedGeometryEffect(
                                id: "letter_\(wordIndex(for: index) ?? index)_\(letter)",
                                in: namespace,
                                isSource: true
                            )
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: currentWord)
    }
}

// MARK: - Match Header
struct MatchHeader: View {
    let round: Int
    let totalRounds: Int
    let myTotalScore: Int
    let oppTotalScore: Int
    let opponentName: String
    let isBot: Bool
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 12) {
            // Round indicator
            HStack(spacing: 4) {
                Text("ROUND")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textMuted)
                    .tracking(2)
                Text("\(round)/\(totalRounds)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(theme.textSecondary)
            }
            
            // Total score display
            HStack(spacing: 32) {
                VStack(spacing: 4) {
                    Text("YOU")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                    
                    Text("\(myTotalScore)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.playerSelfGradient)
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        )
                        
                    
                    Text("PTS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(theme.textMuted)
                }
                
                ScoreBar(myScore: myTotalScore, oppScore: oppTotalScore)
                    .frame(height: 8)
                    .frame(maxWidth: .infinity)
                
                
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        if isBot {
                            Image(systemName: "cpu")
                                .font(.system(size: 10))
                        }
                        Text(opponentName.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(theme.textSecondary)
                    
                    Text("\(oppTotalScore)")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.playerOpponentGradient)
                                .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        )
                        
                    
                    Text("PTS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(theme.textMuted)
                }
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 24)
        .animation(.spring(response: 0.3), value: myTotalScore)
        .animation(.spring(response: 0.3), value: oppTotalScore)
    }
}

// MARK: - Premium Circular Timer
struct PremiumTimerBar: View {
    let timeRemaining: Int
    let totalTime: Int
    @Environment(\.theme) var theme
    
    private var progress: Double {
        max(0, min(1, Double(timeRemaining) / Double(totalTime)))
    }
    
    private var timerColor: Color {
        theme.timerColor(remaining: timeRemaining)
    }
    
    private var timerGradient: LinearGradient {
        timeRemaining <= 5 ? 
            LinearGradient(colors: [theme.error, theme.error.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
            (timeRemaining <= 15 ? 
                LinearGradient(colors: [theme.warning, theme.warning.opacity(0.7)], startPoint: .top, endPoint: .bottom) :
                LinearGradient(colors: [theme.success, theme.success.opacity(0.7)], startPoint: .top, endPoint: .bottom))
    }
    
    private var isCritical: Bool {
        timeRemaining <= 5
    }
    
    private var isWarning: Bool {
        timeRemaining <= 15 && timeRemaining > 5
    }
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(theme.surface, lineWidth: 10)
                .frame(width: 130, height: 130)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    timerGradient,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 130, height: 130)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.5), value: progress)
            
            // Time display
            VStack(spacing: -4) {
                Text("\(timeRemaining)")
                    .font(Typography.timer)
                    .foregroundColor(timerColor)
                    
                    .animation(.spring(response: 0.3), value: timeRemaining)
                
                Text("SEC")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textMuted)
                    .tracking(2)
            }
        }
        .pulsing(when: isCritical, intensity: 0.03)
        .glow(color: timerColor, radius: isCritical ? 15 : 8, when: isCritical || isWarning)
    }
}

// MARK: - Word Builder
struct WordBuilder: View {
    let word: String
    let shake: Bool
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            if word.isEmpty {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textMuted)
                    
                    Text("TAP LETTERS")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textMuted)
                        .tracking(1)
                }
            } else {
                ForEach(Array(word.enumerated()), id: \.offset) { index, char in
                    Text(String(char))
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryGradient)
                        .frame(width: 42, height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: Corners.md)
                                .fill(AppColors.surface)
                                .shadow(color: AppColors.primary.opacity(0.2), radius: 8, y: 4)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Corners.md)
                                .stroke(AppColors.primary.opacity(0.4), lineWidth: 1.5)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .frame(minHeight: 80)
        .background(
            RoundedRectangle(cornerRadius: Corners.lg)
                .fill(AppColors.backgroundSecondary.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: Corners.lg)
                        .stroke(AppColors.surfaceHighlight.opacity(0.5), lineWidth: 1)
                )
        )
        .modifier(ShakeEffect(animatableData: shake ? 1 : 0))
        .animation(.spring(response: 0.3), value: word)
    }
}

// MARK: - Premium Letter Rack
struct PremiumLetterRack: View {
    let letters: [String]
    let bonuses: [BonusTile]
    let currentWord: String
    let isSubmitted: Bool
    let onLetterTap: (String) -> Void
    
    private func isUsed(_ letter: String, at index: Int) -> Bool {
        var usedIndices: [Int] = []
        for char in currentWord {
            if let idx = letters.enumerated().first(where: { !usedIndices.contains($0.offset) && $0.element == String(char) })?.offset {
                usedIndices.append(idx)
            }
        }
        return usedIndices.contains(index)
    }
    
    var body: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: min(5, letters.count))
        
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                let used = isUsed(letter, at: index)
                let bonus = bonuses.first { $0.index == index }?.type
                
                PremiumTile(
                    letter: letter,
                    bonus: bonus,
                    isUsed: used,
                    isDisabled: isSubmitted
                ) {
                    if !used && !isSubmitted {
                        onLetterTap(letter)
                    }
                }
            }
        }
    }
}

// PremiumTile moved to Components/PremiumTile.swift

// MARK: - Action Button Row
struct ActionButtonRow: View {
    let currentWord: String
    let isSubmitted: Bool
    let onClear: () -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 12) {
            // Clear button
            ActionButton(
                icon: "xmark",
                color: theme.surfaceLight,
                action: onClear
            )
            .disabled(currentWord.isEmpty || isSubmitted)
            .opacity(currentWord.isEmpty || isSubmitted ? 0.5 : 1)
            
            // Delete button
            ActionButton(
                icon: "delete.left.fill",
                color: theme.surfaceLight,
                action: onDelete
            )
            .disabled(currentWord.isEmpty || isSubmitted)
            .opacity(currentWord.isEmpty || isSubmitted ? 0.5 : 1)
            
            // Submit button
            Button(action: onSubmit) {
                HStack(spacing: 10) {
                    Image(systemName: isSubmitted ? "checkmark" : "paperplane.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text(isSubmitted ? "SUBMITTED" : "SUBMIT")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .tracking(0.5)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background {
                    if isSubmitted {
                        theme.success
                    } else if currentWord.count >= 3 {
                        theme.primaryGradient
                    } else {
                        theme.surfaceLight
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .shadow(color: currentWord.count >= 3 && !isSubmitted ? theme.primary.opacity(0.4) : .clear, radius: 12, y: 4)
            }
            .disabled(isSubmitted)
        }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(color)
                .clipShape(Circle())
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
    }
}

#Preview {
    MatchView()
        .environmentObject(GameState())
}
// CountdownOverlay

struct CountdownOverlay: View {
    let seconds: Int
    let onFinished: () -> Void
    @Environment(\.theme) var theme
    
    @State private var currentCount: Int
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var countdownTimer: Timer?
    
    init(seconds: Int, onFinished: @escaping () -> Void) {
        self.seconds = seconds
        self.onFinished = onFinished
        _currentCount = State(initialValue: seconds)
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            if currentCount > 0 {
                Text("\(currentCount)")
                    .font(.system(size: 120, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .shadow(color: theme.primary.opacity(0.5), radius: 20, x: 0, y: 10)
            } else {
                Text("GO!")
                    .font(.system(size: 80, weight: .black, design: .rounded))
                    .foregroundColor(theme.success)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .shadow(color: theme.success.opacity(0.5), radius: 20, x: 0, y: 10)
            }
        }
        .onAppear {
            animateCountdown()
        }
        .onDisappear {
            countdownTimer?.invalidate()
        }
    }
    
    private func animateCountdown() {
        // Initial state
        scale = 0.5
        opacity = 0
        
        
        // Sequence
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            scale = 1.2
            opacity = 1
        }
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if currentCount > 1 {
                currentCount -= 1
                
                // Reset animation
                scale = 0.5
                opacity = 0
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.2
                    opacity = 1
                }
            } else if currentCount == 1 {
                currentCount = 0 // "GO!"
                
                // Reset animation
                scale = 0.5
                opacity = 0
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.5
                    opacity = 1
                }
                
                // Finish shortly after
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    onFinished()
                }
                timer.invalidate()
            }
        }
    }
}
