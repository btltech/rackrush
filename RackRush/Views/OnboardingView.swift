import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding = false
    @State private var currentPage = 0
    @Environment(\.theme) var theme
    
    let pages: [OnboardingPage] = [
        OnboardingPage(
            title: "Welcome to RackRush",
            description: "The ultimate real-time word duel. Race against the clock and your opponent.",
            icon: "swift",
            color: Color(hex: "8B5CF6")
        ),
        OnboardingPage(
            title: "Real-Time 1v1",
            description: "Play against bots or real players. Both get the same letters. Highest score wins!",
            icon: "figure.badminton",
            color: Color(hex: "06D6A0")
        ),
        OnboardingPage(
            title: "How to Play",
            description: "Tap letters to build words. Valid words score points. Use bonus tiles (DL, TL) for big scores.",
            icon: "hand.tap.fill",
            color: Color(hex: "F59E0B")
        ),
        OnboardingPage(
            title: "Ready?",
            description: "Climb the leaderboard and become the ultimate word master!",
            icon: "trophy.fill",
            color: Color(hex: "06D6A0")
        )
    ]
    
    var body: some View {
        ZStack {
            theme.backgroundPrimary.ignoresSafeArea()
            
            VStack {
                Spacer()
                
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 400)
                
                Spacer()
                
                // Pagination and Button
                VStack(spacing: 32) {
                    // Dots
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? theme.primary : theme.surfaceHighlight)
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(), value: currentPage)
                        }
                    }
                    
                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            AudioManager.shared.playSubmit()
                            withAnimation {
                                hasSeenOnboarding = true
                            }
                        }
                    }) {
                        Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(theme.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: theme.primary.opacity(0.4), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
            
            // Skip button
            VStack {
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                hasSeenOnboarding = true
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .padding(.top, 20)
                        .padding(.trailing, 24)
                    }
                }
                Spacer()
            }
        }
        .transition(.move(edge: .bottom))
    }
}

struct OnboardingPage {
    let title: String
    let description: String
    let icon: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: page.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(LinearGradient(colors: [page.color, page.color.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .padding(.bottom, 16)
            
            Text(page.title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            Text(page.description)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .lineSpacing(4)
        }
    }
}

#Preview {
    OnboardingView()
}
