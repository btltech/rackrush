import SwiftUI

struct ContentView: View {
    @EnvironmentObject var gameState: GameState
    @EnvironmentObject var socketService: SocketService
    @ObservedObject private var kidsMode = KidsModeManager.shared
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                switch gameState.screen {
                case .home:
                    HomeView()
                case .modeSelect, .queued:
                    ModeSelectView()
                case .match:
                    MatchView()
                        .onAppear {
                            if kidsMode.isEnabled {
                                kidsMode.startPlaySession()
                            }
                        }
                        .onDisappear {
                            if kidsMode.isEnabled {
                                kidsMode.stopPlaySession()
                            }
                        }
                case .roundResult:
                    // Use Kids view if Kids Mode is enabled
                    if kidsMode.isEnabled {
                        KidsRoundResultView()
                    } else {
                        RoundResultView()
                    }
                case .matchResult:
                    // Use Kids view if Kids Mode is enabled
                    if kidsMode.isEnabled {
                        KidsMatchEndView(
                            matchWon: gameState.myTotalScore > gameState.oppTotalScore,
                            onPlayAgain: {
                                gameState.screen = .home
                            }
                        )
                    } else {
                        MatchResultView()
                    }
                case .dailyChallenge:
                    DailyChallengeView()
                }
            }
            .animation(.easeInOut(duration: 0.3), value: gameState.screen)
            
            // Connection Banner Overlay
            ConnectionBanner(isConnected: socketService.isConnected)
            
            // Kids Mode time limit warning
            if kidsMode.isEnabled && kidsMode.showTimeLimitWarning {
                KidsTimeLimitWarning()
            }
            
            // Kids Mode time limit reached
            if kidsMode.isEnabled && kidsMode.isTimeLimitReached {
                KidsTimeLimitReached {
                    gameState.screen = .home
                }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { !hasSeenOnboarding },
            set: { if !$0 { hasSeenOnboarding = true } }
        )) {
            OnboardingView()
        }
    }
}

// MARK: - Kids Time Limit Warning
struct KidsTimeLimitWarning: View {
    @ObservedObject private var kidsMode = KidsModeManager.shared
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            VStack {
                Spacer()
                
                HStack(spacing: 12) {
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 24))
                        .foregroundColor(KidsColors.tileOrange)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("5 minutes left!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(KidsColors.textPrimary)
                        
                        Text("Finish up your game")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(KidsColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button("OK") {
                        withAnimation {
                            isVisible = false
                            kidsMode.showTimeLimitWarning = false
                        }
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(KidsColors.tileBlue)
                    .clipShape(Capsule())
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

// MARK: - Kids Time Limit Reached
struct KidsTimeLimitReached: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 60))
                    .foregroundColor(KidsColors.tilePurple)
                
                Text("Time's Up!")
                    .font(KidsTypography.title)
                    .foregroundColor(KidsColors.textPrimary)
                
                Text("You've played for your daily limit.\nCome back tomorrow for more fun!")
                    .font(KidsTypography.body)
                    .foregroundColor(KidsColors.textSecondary)
                    .multilineTextAlignment(.center)
                
                Button(action: onDismiss) {
                    Text("OK, Bye! 👋")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(KidsColors.playButtonGradient)
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 40)
            }
            .padding(32)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .shadow(color: .black.opacity(0.2), radius: 20)
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(SocketService())
        .environmentObject(GameState())
}
