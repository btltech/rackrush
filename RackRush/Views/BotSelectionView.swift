import SwiftUI

/// Bot selection view for choosing AI opponent
struct BotSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @StateObject private var botManager = BotPersonalityManager.shared
    @Binding var selectedBot: BotPersonality?
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Choose Your Opponent")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Each bot has a unique playstyle")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textSecondary)
                        }
                        .padding(.top)
                        
                        // Bot cards
                        ForEach(BotPersonality.allCases, id: \.self) { bot in
                            BotCard(
                                bot: bot,
                                isUnlocked: botManager.isUnlocked(bot),
                                isSelected: selectedBot == bot
                            ) {
                                if botManager.isUnlocked(bot) {
                                    AudioManager.shared.playTap()
                                    selectedBot = bot
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select Bot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
}

// MARK: - Bot Card

struct BotCard: View {
    let bot: BotPersonality
    let isUnlocked: Bool
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: bot.color).opacity(0.3),
                                    Color(hex: bot.color).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Text(bot.avatar)
                        .font(.system(size: 36))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(bot.displayName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(theme.success)
                        }
                    }
                    
                    Text(bot.description)
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                    
                    HStack(spacing: 12) {
                        // Difficulty badge
                        HStack(spacing: 4) {
                            Image(systemName: "chart.bar.fill")
                                .font(.system(size: 10))
                            Text(bot.difficulty)
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color(hex: bot.color))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: bot.color).opacity(0.2))
                        .clipShape(Capsule())
                        
                        if !isUnlocked {
                            HStack(spacing: 4) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 10))
                                Text("Locked")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(theme.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(theme.textMuted.opacity(0.2))
                            .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color(hex: bot.color) : Color.clear, lineWidth: 2)
            )
            .opacity(isUnlocked ? 1.0 : 0.6)
        }
        .disabled(!isUnlocked)
    }
}

/// Bot greeting overlay shown at match start
struct BotGreetingOverlay: View {
    let bot: BotPersonality
    @Binding var isPresented: Bool
    @Environment(\.theme) var theme
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .opacity(opacity)
            
            VStack(spacing: 16) {
                // Bot avatar
                Text(bot.avatar)
                    .font(.system(size: 60))
                    .scaleEffect(scale)
                
                // Bot name
                Text(bot.displayName)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Greeting
                Text(bot.randomGreeting())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .padding(32)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.3), radius: 20)
            .padding(.horizontal, 40)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
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

#Preview("Bot Selection") {
    BotSelectionView(selectedBot: .constant(.professor))
}

#Preview("Bot Greeting") {
    BotGreetingOverlay(bot: .professor, isPresented: .constant(true))
}
