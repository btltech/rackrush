import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @ObservedObject var stats = StatsManager.shared
    @ObservedObject private var kidsMode = KidsModeManager.shared
    
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("showTimer") private var showTimer = true
    @AppStorage("playerName") private var playerName = ""
    
    @State private var showParentalControls = false
    @State private var showPINVerification = false
    @State private var pendingKidsModeState = false
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundPrimary
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "PROFILE", icon: "person.fill")
                            
                            VStack(spacing: 0) {
                                SettingsTextField(
                                    title: "Display Name",
                                    placeholder: "Anonymous",
                                    text: $playerName
                                )
                            }
                            .glassBackground(cornerRadius: 16)
                        }
                        
                        // Gameplay Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "GAMEPLAY", icon: "gamecontroller.fill")
                            
                            VStack(spacing: 0) {
                                SettingsToggle(
                                    title: "Sound Effects",
                                    subtitle: "Audio feedback for actions",
                                    icon: "speaker.wave.2.fill",
                                    isOn: $soundEnabled
                                )
                                
                                Divider()
                                    .background(theme.surfaceHighlight)
                                
                                SettingsToggle(
                                    title: "Haptic Feedback",
                                    subtitle: "Vibration on interactions",
                                    icon: "hand.tap.fill",
                                    isOn: $hapticsEnabled
                                )
                                
                                Divider()
                                    .background(theme.surfaceHighlight)
                                
                                SettingsToggle(
                                    title: "Show Timer",
                                    subtitle: "Display countdown during rounds",
                                    icon: "timer",
                                    isOn: $showTimer
                                )
                            }
                            .glassBackground(cornerRadius: 16)
                        }
                        
                        // Statistics Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "STATISTICS", icon: "chart.bar.fill")
                            
                            HStack(spacing: 12) {
                                StatCard(title: "Games", value: "\(stats.gamesPlayed)", gradient: theme.primaryGradient)
                                StatCard(title: "Wins", value: "\(stats.wins)", gradient: theme.successGradient)
                                StatCard(title: "Streak", value: "\(stats.currentStreak)", gradient: theme.accentGradient)
                            }
                        }
                        
                        // Kids Mode Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "KIDS MODE", icon: "figure.and.child.holdinghands")
                            
                            VStack(spacing: 0) {
                                HStack {
                                    Image(systemName: "figure.child")
                                        .font(.system(size: 18))
                                        .foregroundColor(theme.primary)
                                        .frame(width: 28)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Kids Mode")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(theme.textPrimary)
                                        
                                        Text(kidsMode.isEnabled ? "Active • \(kidsMode.ageGroup.displayName)" : "Disabled")
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // PIN-gated toggle
                                    Toggle("", isOn: Binding(
                                        get: { kidsMode.isEnabled },
                                        set: { newValue in
                                            if kidsMode.hasPIN {
                                                // Require PIN to change
                                                pendingKidsModeState = newValue
                                                showPINVerification = true
                                            } else {
                                                // No PIN set, allow direct toggle
                                                kidsMode.isEnabled = newValue
                                            }
                                        }
                                    ))
                                        .tint(theme.success)
                                }
                                .padding()
                                
                                Divider().background(theme.surfaceHighlight)
                                
                                Button(action: { showParentalControls = true }) {
                                    HStack {
                                    Image(systemName: "lock.shield.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(theme.accent)
                                            .frame(width: 28)
                                        
                                        Text("Parental Controls")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(theme.textPrimary)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(theme.textMuted)
                                    }
                                    .padding()
                                }
                            }
                            .glassBackground(cornerRadius: 16)
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "ABOUT", icon: "info.circle.fill")
                            
                            VStack(spacing: 0) {
                                SettingsRow(title: "Version", value: "1.0.0")
                                Divider().background(theme.surfaceHighlight)
                                SettingsRow(title: "Build", value: "2026.01.11")
                            }
                            .glassBackground(cornerRadius: 16)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .modifier(ToolbarBackgroundModifier())
        }
        .sheet(isPresented: $showParentalControls) {
            ParentalControlsView()
        }
        .sheet(isPresented: $showPINVerification) {
            PINVerificationView(
                onSuccess: {
                    kidsMode.isEnabled = pendingKidsModeState
                    showPINVerification = false
                },
                onCancel: {
                    showPINVerification = false
                }
            )
        }
    }
}

// iOS 15/16 compatibility for toolbar background
struct ToolbarBackgroundModifier: ViewModifier {
    @Environment(\.theme) var theme
    
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content
                .toolbarBackground(theme.backgroundSecondary, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        } else {
            content
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let icon: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.primaryGradient)
            
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary)
                .tracking(1.5)
        }
        .padding(.leading, 4)
    }
}

// MARK: - Settings Toggle
struct SettingsToggle: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.surfaceLight)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textMuted)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(theme.primary)
        }
        .padding(16)
    }
}

// MARK: - Settings TextField
struct SettingsTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(theme.surfaceLight)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "person.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textMuted)
                
                TextField(placeholder, text: $text)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
            }
        }
        .padding(16)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let title: String
    let value: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textMuted)
        }
        .padding(16)
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let gradient: LinearGradient
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(gradient)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassBackground(cornerRadius: 16)
    }
}

#Preview {
    SettingsView()
        .environmentObject(GameState())
}
