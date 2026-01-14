import SwiftUI

struct ModeSelectView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var socketService: SocketService
    @Environment(\.theme) var theme
    @State private var selectedMode: Int = 7  // Default to Quick (7 letters)
    @State private var selectedDifficulty: String = "medium"
    @State private var isQueued = false
    @State private var appearAnimation = false
    
    let modes = [
        (size: 7, name: "Quick", desc: "7 letters", time: "25s"),
        (size: 8, name: "Classic", desc: "8 letters", time: "30s"),
        (size: 9, name: "Extended", desc: "9 letters", time: "35s"),
        (size: 10, name: "Expert", desc: "10 letters", time: "45s")
    ]
    
    let difficulties = [
        (id: "easy", name: "Easy", emoji: "🌱", desc: "Relaxed pace"),
        (id: "medium", name: "Medium", emoji: "⚡", desc: "Balanced"),
        (id: "hard", name: "Hard", emoji: "🔥", desc: "Competitive")
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundPrimary
                .ignoresSafeArea()
            
            // New ambient particles for polish
            AmbientParticlesView()
                .opacity(0.5)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        AudioManager.shared.playTap()
                        gameState.screen = .home
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(theme.textSecondary)
                        .padding(8)
                        .background(GlassView(opacity: 0.2))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Text(gameState.matchType == .pvp ? "PLAY ONLINE" : "VS BOT")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textMuted)
                        .tracking(2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Mode selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("GAME MODE")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(theme.textMuted)
                                .tracking(1.5)
                                .padding(.leading, 4)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(modes, id: \.size) { mode in
                                    ModeCard(
                                        size: mode.size,
                                        name: mode.name,
                                        desc: mode.desc,
                                        time: mode.time,
                                        isSelected: selectedMode == mode.size
                                    ) {
                                        AudioManager.shared.playSelect()
                                        selectedMode = mode.size
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .offset(y: appearAnimation ? 0 : 30)
                        .opacity(appearAnimation ? 1 : 0)
                        
                        // Difficulty (for bot only)
                        if gameState.matchType == .bot {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("DIFFICULTY")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(theme.textMuted)
                                .tracking(1.5)
                                .padding(.leading, 4)
                                
                                HStack(spacing: 12) {
                                    ForEach(difficulties, id: \.id) { diff in
                                        DifficultyCard(
                                            id: diff.id,
                                            name: diff.name,
                                            emoji: diff.emoji,
                                            desc: diff.desc,
                                            isSelected: selectedDifficulty == diff.id
                                        ) {
                                            AudioManager.shared.playSelect()
                                            selectedDifficulty = diff.id
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .offset(y: appearAnimation ? 0 : 30)
                            .opacity(appearAnimation ? 1 : 0)
                            .animation(.spring(response: 0.6).delay(0.1), value: appearAnimation)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.top, 32)
                }
                
                // Start button
                VStack(spacing: 16) {
                    if isQueued {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Finding opponent...")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(GlassView(opacity: 0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.primary.opacity(0.5), lineWidth: 1)
                        )
                        .modifier(PulsingModifier(isActive: true))
                        
                        Button(action: {
                            AudioManager.shared.playTap()
                            isQueued = false
                            gameState.screen = .home
                        }) {
                            Text("Cancel")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                        }
                    } else {
                        Button(action: startGame) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("START GAME")
                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                    .tracking(0.5)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(theme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: theme.primary.opacity(0.4), radius: 12, y: 4)
                            .modifier(DepthShadowModifier(depth: 2, color: .black.opacity(0.3)))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                .background(
                    theme.backgroundPrimary
                        .opacity(0.9)
                        .mask(
                            LinearGradient(
                                colors: [.clear, .black],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 120)
                        .offset(y: -40)
                )
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appearAnimation = true
            }
        }
    }
    
    private func startGame() {
        AudioManager.shared.playSubmit()
        
        // Set mode and difficulty on gameState
        gameState.selectedMode = selectedMode
        if let diff = BotDifficulty(rawValue: selectedDifficulty) {
            gameState.botDifficulty = diff
        }
        
        // Use offline mode for bot matches, Game Center for PvP
        if gameState.matchType == .bot {
            // Offline bot match - no network required
            gameState.startOfflineBotMatch()
        } else {
            // PvP - use Apple Game Center
            isQueued = true
            gameState.startGameCenterMatch()
        }
    }
}

// MARK: - Mode Card
struct ModeCard: View {
    let size: Int
    let name: String
    let desc: String
    let time: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Text("\(size)")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundStyle(isSelected ? theme.primaryGradient : LinearGradient(colors: [theme.textMuted, theme.textMuted], startPoint: .top, endPoint: .bottom))
                    .shadow(color: isSelected ? theme.primary.opacity(0.3) : .clear, radius: 8)
                
                VStack(spacing: 4) {
                    Text(name)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? (KidsModeManager.shared.isEnabled ? theme.textPrimary : .white) : theme.textSecondary)
                    
                    Text(desc)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textMuted)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                Group {
                    if isSelected {
                        theme.surface
                    } else {
                        if KidsModeManager.shared.isEnabled {
                            theme.surfaceHighlight.opacity(0.6)
                        } else {
                            GlassView(opacity: 0.1)
                        }
                    }
                }
                .cornerRadius(16)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? theme.primary : theme.surfaceHighlight, lineWidth: isSelected ? 2 : 1)
            )
            .modifier(DepthShadowModifier(depth: isSelected ? 2 : 0, color: isSelected ? theme.primary : .black))
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

// MARK: - Difficulty Card
struct DifficultyCard: View {
    let id: String
    let name: String
    let emoji: String
    let desc: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.system(size: 28))
                
                Text(name)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? (KidsModeManager.shared.isEnabled ? theme.textPrimary : .white) : theme.textSecondary)
                
                Text(desc)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                Group {
                    if isSelected {
                        theme.surface
                    } else {
                        if KidsModeManager.shared.isEnabled {
                            theme.surfaceHighlight.opacity(0.6)
                        } else {
                            GlassView(opacity: 0.1)
                        }
                    }
                }
                .cornerRadius(14)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? difficultyColor : theme.surfaceHighlight, lineWidth: isSelected ? 2 : 1)
            )
            .modifier(DepthShadowModifier(depth: isSelected ? 2 : 0, color: isSelected ? difficultyColor : .black))
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
    
    var difficultyColor: Color {
        switch id {
        case "easy": return theme.success
        case "medium": return theme.warning
        case "hard": return theme.error
        default: return theme.primary
        }
    }
}

#Preview {
    ModeSelectView()
        .environmentObject(GameState())
        .environmentObject(SocketService())
}
