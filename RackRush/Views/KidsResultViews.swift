import SwiftUI

// MARK: - Kids Mode Round Result View
/// A kid-friendly result screen with stars, encouragement, and no "lose" messaging

struct KidsRoundResultView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.theme) var theme
    @ObservedObject private var kidsMode = KidsModeManager.shared
    @State private var showContent = false
    @State private var starsRevealed = 0
    @State private var mascotMessage = ""
    @State private var showDefinitions = false
    @State private var yourDefinition: DictionaryService.WordDefinition?
    @State private var oppDefinition: DictionaryService.WordDefinition?
    @State private var isLoadingDefinitions = true
    
    var result: RoundResult? {
        gameState.lastRoundResult
    }
    
    var isWinner: Bool {
        guard let r = result else { return false }
        return r.yourScore > r.oppScore
    }
    
    var starCount: Int {
        guard let r = result else { return 1 }
        return StarRating.starsFor(
            yourScore: r.yourScore,
            oppScore: r.oppScore,
            wordLength: r.yourWord.count
        )
    }
    
    var body: some View {
        ZStack {
            // Kid-friendly background
            theme.backgroundPrimary
                .ignoresSafeArea()
            
            // Floating decorations
            FloatingStarsBackground()
            
            VStack(spacing: 12) {
                Spacer()
                
                // Result messaging & Stars
                VStack(spacing: 8) {
                    // Animated stars
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { index in
                            StarView(
                                isFilled: index < starsRevealed,
                                delay: Double(index) * 0.3
                            )
                            .scaleEffect(0.8)
                        }
                    }
                    
                    // Encouraging message
                    Text(encouragingMessage)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .scaleEffect(showContent ? 1 : 0.8)
                }
                .padding(.top, 20)
                
                // Word Cards with integrated Definitions
                if let r = result {
                    HStack(spacing: 12) {
                        // Use a horizontal layout for landscape or compact vertical for portrait
                        // For "one page", two columns side-by-side might be best if definitions are short
                        // But words can be long. Let's stick to Vertical but compact.
                        
                        KidsWordDefinitionCard(
                            label: "YOU",
                            word: r.yourWord.uppercased(),
                            score: r.yourScore,
                            definition: yourDefinition,
                            gradient: theme.playerSelfGradient
                        )
                        
                        KidsWordDefinitionCard(
                            label: "THEM",
                            word: r.oppWord.uppercased(),
                            score: r.oppScore,
                            definition: oppDefinition,
                            gradient: theme.playerOpponentGradient
                        )
                    }
                    .padding(.horizontal, 16)
                    .opacity(showContent ? 1 : 0)
                }
                
                // Mascot (Smaller version)
                HStack {
                    KidsMascot(message: mascotMessage, mood: isWinner ? .excited : .encouraging)
                        .scaleEffect(0.9)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 4)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                // Next Round info
                if let nextStart = result?.nextRoundStartsAt {
                    KidsNextRoundTimer(targetTime: nextStart)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            animateAppearance()
            setMascotMessage()
            fetchDefinitions()
            
            // Show definitions after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showDefinitions = true
                }
            }
        }
    }
    
    private var encouragingMessage: String {
        switch starCount {
        case 3: return KidsMessages.randomWin()
        case 2: return "Good job! 👏"
        default: return KidsMessages.randomTryAgain()
        }
    }
    
    private func animateAppearance() {
        // Stars appear one by one
        for i in 0..<starCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.4 + 0.3) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    starsRevealed = i + 1
                }
            }
        }
        
        // Content fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
            showContent = true
        }
    }
    
    private func setMascotMessage() {
        guard let r = result else { return }
        
        if isWinner {
            mascotMessage = "Wow, \(r.yourWord.uppercased()) is a great word!"
        } else if r.yourWord.count >= 3 {
             mascotMessage = "Nice try with \(r.yourWord.uppercased())!"
        } else {
            mascotMessage = KidsMessages.randomEncouragement()
        }
    }
    
    private func fetchDefinitions() {
        guard let r = result else {
            isLoadingDefinitions = false
            return
        }
        
        Task {
            async let yourDef = DictionaryService.shared.fetchDefinition(for: r.yourWord)
            async let oppDef = DictionaryService.shared.fetchDefinition(for: r.oppWord)
            
            let (your, opp) = await (yourDef, oppDef)
            
            await MainActor.run {
                yourDefinition = your
                oppDefinition = opp
                isLoadingDefinitions = false
            }
        }
    }
}

// MARK: - Kids Word Definition Card
struct KidsWordDefinitionCard: View {
    let label: String
    let word: String
    let score: Int
    let definition: DictionaryService.WordDefinition?
    let gradient: LinearGradient
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 8) {
            // Header: Word + Score
            VStack(spacing: 4) {
                Text(label)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textMuted)
                
                Text(word)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(gradient)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                Text("+\(score)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(gradient)
                    .clipShape(Capsule())
            }
            
            Divider()
            
            // Definition Section
            if let def = definition {
                VStack(spacing: 4) {
                    Text(def.definition)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Pronunciation Button
                    PronunciationButton(word: word)
                        .scaleEffect(0.8)
                }
            } else {
                Text("Learning...")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textMuted)
                    .italic()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Animated Star View
struct StarView: View {
    let isFilled: Bool
    let delay: Double
    @Environment(\.theme) var theme
    
    @State private var scale: CGFloat = 0
    @State private var rotation: Double = -30
    
    var body: some View {
        Image(systemName: isFilled ? "star.fill" : "star")
            .font(.system(size: 50))
            .foregroundStyle(
                isFilled
                    ? (theme.successGradient) // Using success gradient for filled stars in kids mode
                    : LinearGradient(colors: [theme.textMuted.opacity(0.3)], startPoint: .top, endPoint: .bottom)
            )
            .shadow(color: isFilled ? .orange.opacity(0.5) : .clear, radius: 10)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onChange(of: isFilled) { filled in
                if filled {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                        scale = 1.2
                        rotation = 0
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            scale = 1.0
                        }
                    }
                }
            }
            .onAppear {
                if !isFilled {
                    scale = 0.8
                    rotation = 0
                }
            }
    }
}

// MARK: - Floating Stars Background
struct FloatingStarsBackground: View {
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<8, id: \.self) { i in
                FloatingStar(
                    size: CGFloat.random(in: 12...24),
                    x: CGFloat.random(in: 0...geo.size.width),
                    y: CGFloat.random(in: 0...geo.size.height),
                    duration: Double.random(in: 3...6)
                )
            }
        }
        .ignoresSafeArea()
    }
}

struct FloatingStar: View {
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat
    let duration: Double
    @Environment(\.theme) var theme
    
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0.3
    
    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: size))
            .foregroundColor(theme.accent.opacity(opacity))
            .position(x: x, y: y + offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = -20
                    opacity = 0.6
                }
            }
    }
}

// MARK: - Kids Next Round Timer
struct KidsNextRoundTimer: View {
    let targetTime: Int // Timestamp in ms
    @Environment(\.theme) var theme
    @State private var remainingSeconds: Int = 0
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Next round in...")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(KidsColors.textSecondary)
            
            HStack(spacing: 4) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                Text("\(remainingSeconds)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
            }
            .foregroundColor(theme.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 6, y: 3)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startTimer() {
        updateRemaining()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            updateRemaining()
        }
    }
    
    private func updateRemaining() {
        let now = Int(Date().timeIntervalSince1970 * 1000)
        let remaining = (targetTime - now) / 1000
        remainingSeconds = max(0, remaining)
    }
}

// MARK: - Kids Match End View
struct KidsMatchEndView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.theme) var theme
    let matchWon: Bool
    let onPlayAgain: () -> Void
    
    @State private var showContent = false
    @State private var confettiActive = false
    
    var body: some View {
        ZStack {
            theme.backgroundPrimary
                .ignoresSafeArea()
            
            // Confetti for wins
            if matchWon && confettiActive {
                KidsConfettiView()
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                // Trophy or encouragement
                VStack(spacing: 20) {
                    if matchWon {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(theme.successGradient)
                            .shadow(color: theme.success.opacity(0.4), radius: 20)
                        
                        Text("CHAMPION! 🏆")
                            .font(KidsTypography.title)
                            .foregroundColor(theme.textPrimary)
                    } else {
                        // Friendly "great game" message
                        Image(systemName: "hands.clap.fill")
                            .font(.system(size: 80))
                            .foregroundColor(theme.secondary)
                        
                        Text("Great Game! 🌟")
                            .font(KidsTypography.title)
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    Text(matchWon ? "You're a word wizard!" : "You're getting better!")
                        .font(KidsTypography.body)
                        .foregroundColor(theme.textSecondary)
                }
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                
                // Final scores
                HStack(spacing: 40) {
                    VStack {
                        Text("You")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textSecondary)
                        Text("\(gameState.myTotalScore)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.playerSelfGradient)
                                    .shadow(color: .black.opacity(0.1), radius: 6)
                            )
                    }
                    
                    Text("vs")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textMuted)
                    
                    VStack {
                        Text(gameState.opponentName ?? "THEM")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textSecondary)
                        Text("\(gameState.oppTotalScore)")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(theme.playerOpponentGradient)
                                    .shadow(color: .black.opacity(0.1), radius: 6)
                            )
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                // Play Again button
                Button(action: onPlayAgain) {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Play Again!")
                    }
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(theme.primaryGradient)
                    .clipShape(Capsule())
                    .shadow(color: theme.success.opacity(0.4), radius: 10, y: 5)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
            
            if matchWon {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    confettiActive = true
                }
            }
        }
    }
}

// MARK: - Kids Confetti
struct KidsConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geo in
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(x: particle.x, y: particle.y)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            generateParticles()
        }
    }
    
    private func generateParticles() {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                color: KidsColors.tileColors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: -100...UIScreen.main.bounds.height)
            )
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var x: CGFloat
    var y: CGFloat
}

#Preview {
    KidsRoundResultView()
        .environmentObject(GameState())
}
