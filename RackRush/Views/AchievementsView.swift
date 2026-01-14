import SwiftUI

/// Achievement unlock notification overlay
struct AchievementUnlockView: View {
    let achievement: Achievement
    @Binding var isPresented: Bool
    @Environment(\.theme) var theme
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .opacity(opacity)
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 20) {
                // Badge icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [achievement.category.color.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 80
                            )
                        )
                        .frame(width: 140, height: 140)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [achievement.category.color, achievement.category.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .scaleEffect(scale)
                .rotation3DEffect(
                    .degrees(scale == 1.0 ? 360 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                
                VStack(spacing: 8) {
                    Text("ACHIEVEMENT UNLOCKED!")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textMuted)
                        .tracking(2)
                    
                    Text(achievement.title)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(achievement.description)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    // Category badge
                    Text(achievement.category.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(achievement.category.color)
                        .clipShape(Capsule())
                        .padding(.top, 4)
                }
                .padding(.horizontal, 32)
                .opacity(opacity)
            }
            .padding(32)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.3), radius: 30)
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismiss()
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeOut(duration: 0.3)) {
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
}

/// Achievements collection view
struct AchievementsView: View {
    @StateObject private var achievementSystem = AchievementSystem.shared
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: AchievementCategory?
    
    var filteredAchievements: [Achievement] {
        let all = AchievementSystem.allAchievements
        if let category = selectedCategory {
            return all.filter { $0.category == category }
        }
        return all
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Stats header
                    HStack(spacing: 24) {
                        StatBadge(
                            value: "\(achievementSystem.unlockedAchievements.count)",
                            label: "UNLOCKED",
                            color: theme.success
                        )
                        
                        StatBadge(
                            value: "\(AchievementSystem.allAchievements.count)",
                            label: "TOTAL",
                            color: theme.textMuted
                        )
                        
                        StatBadge(
                            value: "\(Int(Double(achievementSystem.unlockedAchievements.count) / Double(AchievementSystem.allAchievements.count) * 100))%",
                            label: "COMPLETE",
                            color: theme.primary
                        )
                    }
                    .padding()
                    
                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            CategoryFilterButton(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                color: theme.primary
                            ) {
                                selectedCategory = nil
                            }
                            
                            ForEach(AchievementCategory.allCases, id: \.self) { category in
                                CategoryFilterButton(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    color: category.color
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom)
                    
                    // Achievement grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredAchievements) { achievement in
                                AchievementCard(
                                    achievement: achievement,
                                    isUnlocked: achievementSystem.unlockedAchievements.contains(achievement.id)
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatBadge: View {
    let value: String
    let label: String
    let color: Color
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(theme.textMuted)
                .tracking(1)
        }
    }
}

struct CategoryFilterButton: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: {
            AudioManager.shared.playTap()
            action()
        }) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isSelected ? .white : theme.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? color : theme.surface)
                .clipShape(Capsule())
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.category.color.opacity(isUnlocked ? 0.2 : 0.05))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(isUnlocked ? achievement.category.color : theme.textMuted)
            }
            
            // Title
            Text(achievement.title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isUnlocked ? .white : theme.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Description
            Text(achievement.description)
                .font(.system(size: 11))
                .foregroundColor(theme.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if !isUnlocked {
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(theme.textMuted.opacity(0.5))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

#Preview {
    AchievementsView()
}
