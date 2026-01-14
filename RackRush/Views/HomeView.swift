import SwiftUI

struct HomeView: View {
    @EnvironmentObject var socketService: SocketService
    @EnvironmentObject var gameState: GameState
    @Environment(\.theme) var theme
    @State private var showSettings = false
    @State private var showGuide = false
    @State private var showAchievements = false
    @State private var showLeaderboards = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var buttonsOffset: CGFloat = 60
    @State private var buttonsOpacity: Double = 0
    @State private var connectionBadgeOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // State of the art animated mesh background
            DynamicMeshView()
                .ignoresSafeArea()
            
            // Ambient floating particles
            AmbientParticlesView(
                count: 20,
                colors: [
                    theme.primary.opacity(0.4),
                    theme.secondary.opacity(0.3),
                    .white.opacity(0.2)
                ]
            )
            .ignoresSafeArea()
            
            // Subtle gradient overlay for depth
            LinearGradient(
                colors: [
                    theme.primary.opacity(0.03),
                    Color.clear,
                    theme.secondary.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top bar with help, achievements, leaderboards, and settings
                HStack(spacing: 12) {
                    // Help button
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showGuide = true
                    }) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(theme.surface.opacity(0.7))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(theme.surfaceHighlight, lineWidth: 1)
                            )
                    }
                    
                    // Achievements button
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showAchievements = true
                    }) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color(hex: "FFD700"))
                            .frame(width: 44, height: 44)
                            .background(theme.surface.opacity(0.7))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(theme.surfaceHighlight, lineWidth: 1)
                            )
                    }
                    
                    Spacer()
                    
                    // Leaderboards button
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showLeaderboards = true
                    }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.primary)
                            .frame(width: 44, height: 44)
                            .background(theme.surface.opacity(0.7))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(theme.surfaceHighlight, lineWidth: 1)
                            )
                    }
                    
                    // Settings button
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(theme.surface.opacity(0.7))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(theme.surfaceHighlight, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.md)
                
                Spacer()
                
                // Logo with animation and shimmer
                VStack(spacing: Spacing.md) {
                    VStack(spacing: -6) {
                        Text("RACK")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundStyle(AppColors.logoGradientPurple)
                            .shadow(color: theme.primary.opacity(0.4), radius: 20, x: 0, y: 8)
                        
                        Text("RUSH")
                            .font(.system(size: 60, weight: .black, design: .rounded))
                            .foregroundStyle(AppColors.logoGradientWarm)
                            .shadow(color: theme.accent.opacity(0.4), radius: 20, x: 0, y: 8)
                    }
                    .shimmer(duration: 3, delay: 1)
                    
                    // Subtitle
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.gold)
                        
                        Text("WORD DUEL")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textSecondary)
                            .tracking(4)
                        
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12))
                            .foregroundColor(theme.gold)
                    }
                    .opacity(subtitleOpacity)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                
                // Connection status
                ConnectionStatusBadge(isConnected: socketService.isConnected)
                    .padding(.top, Spacing.lg)
                    .opacity(connectionBadgeOpacity)
                
                Spacer()
                
                // Menu buttons container
                VStack(spacing: Spacing.md) {
                    HomeCardButton(
                        title: "PLAY ONLINE",
                        subtitle: "Compete with players worldwide",
                        icon: "globe.americas.fill",
                        gradient: AppColors.primaryGradient,
                        glowColor: AppColors.primary,
                        isLarge: true
                    ) {
                        gameState.setMatchType(.pvp)
                        gameState.goToModeSelect()
                    }
                    .shimmer(duration: 4, delay: 2)
                    
                    HStack(spacing: Spacing.md) {
                        HomeCardButton(
                            title: "VS BOT",
                            subtitle: "Practice mode",
                            icon: "cpu.fill",
                            gradient: AppColors.warmGradient,
                            glowColor: AppColors.accent
                        ) {
                            gameState.setMatchType(.bot)
                            gameState.goToModeSelect()
                        }
                        
                        HomeCardButton(
                            title: "DAILY",
                            subtitle: "World challenge",
                            icon: "calendar.badge.clock",
                            gradient: AppColors.goldGradient,
                            glowColor: AppColors.gold
                        ) {
                            gameState.screen = .dailyChallenge
                        }
                    }
                }
                .padding(Spacing.md)
                .background(theme.surface.opacity(0.3))
                .glassBackground(cornerRadius: 32)
                .padding(.horizontal, Spacing.lg)
                .offset(y: buttonsOffset)
                .opacity(buttonsOpacity)
                
                Spacer()
                Spacer()
            }
        }
        .onAppear {
            animateEntrance()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showGuide) {
            UserGuideView()
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
        }
        .sheet(isPresented: $showLeaderboards) {
            LeaderboardView()
        }
    }
    
    private func animateEntrance() {
        // Logo entrance
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            logoScale = 1.0
            logoOpacity = 1
        }
        
        // Subtitle fade in
        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
            subtitleOpacity = 1
        }
        
        // Connection badge
        withAnimation(.easeOut(duration: 0.4).delay(0.4)) {
            connectionBadgeOpacity = 1
        }
        
        // Buttons slide up
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.25)) {
            buttonsOffset = 0
            buttonsOpacity = 1
        }
    }
}

// MARK: - Connection Status Badge
struct ConnectionStatusBadge: View {
    let isConnected: Bool
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(isConnected ? theme.success : theme.warning)
                .frame(width: 8, height: 8)
                .shadow(color: (isConnected ? theme.success : theme.warning).opacity(0.6), radius: 4)
            
            Text(isConnected ? "Connected" : "Connecting...")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm + 2)
        .background(theme.surface.opacity(0.6))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(theme.surfaceHighlight.opacity(0.8), lineWidth: 1)
        )
    }
}

// MARK: - Home Card Button (Premium)
struct HomeCardButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    let glowColor: Color
    var isLarge: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    if isLarge {
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                Text(title)
                    .tracking(0.5)
                    .font(.system(size: isLarge ? 24 : 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .tracking(0.2)
                    .font(.system(size: isLarge ? 13 : 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .padding(isLarge ? 20 : 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                ZStack {
                    gradient
                    
                    // Texture overlay (subtle scanlines)
                    VStack(spacing: 4) {
                        ForEach(0..<10) { _ in
                            Color.white.opacity(0.05)
                                .frame(height: 1)
                        }
                    }
                    .rotationEffect(.degrees(-45))
                    .mask(Rectangle())
                    
                    // Glass highlight
                    LinearGradient(
                        colors: [.white.opacity(0.2), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: glowColor.opacity(0.4), radius: isPressed ? 8 : 15, x: 0, y: isPressed ? 4 : 10)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
        }
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
    }
}

// MARK: - Press Events Modifier
struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

// MARK: - Dynamic Mesh View (State of the Art)
struct DynamicMeshView: View {
    @State private var t: CGFloat = 0
    @State private var timer: Timer?
    @Environment(\.theme) var theme
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                theme.backgroundPrimary
                
                // Blob 1
                Circle()
                    .fill(theme.primary.opacity(0.4))
                    .frame(width: 450)
                    .blur(radius: 80)
                    .offset(
                        x: -100 + cos(t * 0.5) * 80,
                        y: -150 + sin(t * 0.7) * 100
                    )
                
                // Blob 2
                Circle()
                    .fill(theme.secondary.opacity(0.3))
                    .frame(width: 400)
                    .blur(radius: 80)
                    .offset(
                        x: 100 + sin(t * 0.4) * 120,
                        y: 100 + cos(t * 0.6) * 90
                    )
                
                // Blob 3
                Circle()
                    .fill(theme.accent.opacity(0.2))
                    .frame(width: 350)
                    .blur(radius: 80)
                    .offset(
                        x: -50 + sin(t * 0.8) * 150,
                        y: 150 + cos(t * 0.4) * 120
                    )
            }
        }
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                t += 0.02
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(SocketService())
        .environmentObject(GameState())
}

