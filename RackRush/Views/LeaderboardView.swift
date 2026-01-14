import SwiftUI
import GameKit

/// Game Center leaderboard view
struct LeaderboardView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @State private var selectedLeaderboard: LeaderboardType = .wins
    @State private var isLoading = true
    @State private var entries: [LeaderboardEntry] = []
    @State private var playerRank: Int?
    @State private var showGameCenterUI = false
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Leaderboard type selector
                    LeaderboardTypeSelector(selectedType: $selectedLeaderboard)
                        .padding()
                        .onChange(of: selectedLeaderboard) { _ in
                            loadLeaderboard()
                        }
                    
                    if isLoading {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Text("Loading rankings...")
                            .foregroundColor(theme.textSecondary)
                            .padding()
                        Spacer()
                    } else if entries.isEmpty {
                        EmptyStateView(
                            icon: "chart.bar.fill",
                            title: "No Rankings Yet",
                            message: "Be the first to claim the top spot!",
                            actionTitle: "Play Match",
                            action: { dismiss() }
                        )
                    } else {
                        // Player's rank banner
                        if let rank = playerRank {
                            PlayerRankBanner(rank: rank, total: entries.count)
                                .padding(.horizontal)
                                .padding(.bottom)
                        }
                        
                        // Leaderboard list
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                                    LeaderboardRow(
                                        entry: entry,
                                        rank: index + 1,
                                        isPlayer: entry.isLocalPlayer
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationTitle("Leaderboards")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showGameCenterUI = true
                    }) {
                        Image(systemName: "gamecontroller.fill")
                            .foregroundColor(theme.primary)
                    }
                }
            }
        }
        .onAppear {
            loadLeaderboard()
        }
        .sheet(isPresented: $showGameCenterUI) {
            GameCenterLeaderboardView(leaderboardID: selectedLeaderboard.identifier)
        }
    }
    
    private func loadLeaderboard() {
        isLoading = true
        
        // Mock data for now - would integrate with Game Center in production
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            entries = generateMockEntries(for: selectedLeaderboard)
            playerRank = Int.random(in: 5...20)
            isLoading = false
        }
    }
    
    private func generateMockEntries(for type: LeaderboardType) -> [LeaderboardEntry] {
        let names = ["Alex", "Jordan", "Sam", "Taylor", "Morgan", "Casey", "Riley", "Drew", "Quinn", "Avery"]
        
        return names.enumerated().map { index, name in
            let score: Int
            switch type {
            case .wins:
                score = 100 - (index * 8)
            case .bestScore:
                score = 250 - (index * 15)
            case .winStreak:
                score = 25 - (index * 2)
            }
            
            return LeaderboardEntry(
                id: UUID().uuidString,
                playerName: name,
                score: score,
                isLocalPlayer: index == 4
            )
        }
    }
}

// MARK: - Supporting Views

struct LeaderboardTypeSelector: View {
    @Binding var selectedType: LeaderboardType
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(LeaderboardType.allCases, id: \.self) { type in
                Button(action: {
                    AudioManager.shared.playTap()
                    selectedType = type
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: type.icon)
                            .font(.system(size: 20))
                        Text(type.title)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(selectedType == type ? .white : theme.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if selectedType == type {
                                theme.primaryGradient
                            } else {
                                Color.clear
                            }
                        }
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(4)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct PlayerRankBanner: View {
    let rank: Int
    let total: Int
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .font(.system(size: 16))
                .foregroundColor(theme.primary)
            
            Text("Your Rank: #\(rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Text("of \(total)")
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    let rank: Int
    let isPlayer: Bool
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(rankColor)
            }
            
            // Player name
            Text(entry.playerName)
                .font(.system(size: 16, weight: isPlayer ? .bold : .medium))
                .foregroundColor(.white)
            
            if isPlayer {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.warning)
            }
            
            Spacer()
            
            // Score
            Text("\(entry.score)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(theme.primaryGradient)
        }
        .padding()
        .background(isPlayer ? theme.primary.opacity(0.1) : theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isPlayer ? theme.primary : Color.clear, lineWidth: 2)
        )
    }
    
    private var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD700") // Gold
        case 2: return Color(hex: "C0C0C0") // Silver
        case 3: return Color(hex: "CD7F32") // Bronze
        default: return Color.white
        }
    }
}

// MARK: - Game Center Native UI

struct GameCenterLeaderboardView: UIViewControllerRepresentable {
    let leaderboardID: String
    
    func makeUIViewController(context: Context) -> GKGameCenterViewController {
        let viewController = GKGameCenterViewController(leaderboardID: leaderboardID, playerScope: .global, timeScope: .allTime)
        viewController.gameCenterDelegate = context.coordinator
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: GKGameCenterViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, GKGameCenterControllerDelegate {
        func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
            gameCenterViewController.dismiss(animated: true)
        }
    }
}

// MARK: - Models

enum LeaderboardType: String, CaseIterable {
    case wins = "all_time_wins"
    case bestScore = "best_match_score"
    case winStreak = "longest_win_streak"
    
    var title: String {
        switch self {
        case .wins: return "Wins"
        case .bestScore: return "Best Score"
        case .winStreak: return "Win Streak"
        }
    }
    
    var icon: String {
        switch self {
        case .wins: return "trophy.fill"
        case .bestScore: return "star.fill"
        case .winStreak: return "flame.fill"
        }
    }
    
    var identifier: String {
        return "com.rackrush.\(rawValue)"
    }
}

struct LeaderboardEntry: Identifiable {
    let id: String
    let playerName: String
    let score: Int
    let isLocalPlayer: Bool
}

#Preview {
    LeaderboardView()
}
