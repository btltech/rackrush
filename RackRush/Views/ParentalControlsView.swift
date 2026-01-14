import SwiftUI

// MARK: - Parental Controls View
struct ParentalControlsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @ObservedObject private var kidsMode = KidsModeManager.shared
    
    @State private var showPINEntry = false
    @State private var showPINSetup = false
    @State private var showAgeGate = false
    @State private var enteredPIN = ""
    @State private var pinError = false
    @State private var showOnlineConsentSheet = false
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundPrimary
                    .ignoresSafeArea()
                
                if kidsMode.hasPIN && !kidsMode.isUnlocked {
                    // Locked - show PIN entry
                    PINEntryView(
                        title: "Enter Parental PIN",
                        subtitle: "Enter your 4-digit PIN to access settings",
                        onComplete: { pin in
                            if kidsMode.verifyPIN(pin) {
                                // Unlocked
                            } else {
                                pinError = true
                            }
                        },
                        showError: $pinError
                    )
                } else {
                    // Unlocked - show controls
                    controlsContent
                }
            }
            .navigationTitle("Parental Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        kidsMode.lockSettings()
                        dismiss()
                    }
                    .foregroundColor(theme.primary)
                }
            }
            .sheet(isPresented: $showPINSetup) {
                PINSetupView()
            }
            .sheet(isPresented: $showOnlineConsentSheet) {
                OnlinePlayConsentView()
            }
        }
        .onDisappear {
            kidsMode.lockSettings()
        }
    }
    
    private var controlsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Kids Mode Toggle
                kidsModeSection
                
                if kidsMode.isEnabled {
                    // Age Group Selection
                    ageGroupSection
                    
                    // Online Play
                    onlinePlaySection
                    
                    // Time Limits
                    timeLimitSection
                    
                    // Today's Usage
                    usageSection
                    
                    // PIN Settings
                    pinSection
                }
            }
            .padding()
        }
    }
    
    // MARK: - Sections
    
    private var onlinePlaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(theme.success)
                Text("Online Play")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Play with Other Kids")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                        
                        Text(kidsMode.onlinePlayAllowed ? "Enabled" : "Bot only")
                            .font(.system(size: 12))
                            .foregroundColor(kidsMode.onlinePlayAllowed ? theme.success : theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { kidsMode.onlinePlayAllowed },
                        set: { newValue in
                            if newValue {
                                // Show consent dialog
                                showOnlineConsentSheet = true
                            } else {
                                kidsMode.revokeOnlineConsent()
                            }
                        }
                    ))
                    .tint(theme.success)
                }
                
                // Safety info
                VStack(alignment: .leading, spacing: 6) {
                    SafetyBullet(icon: "checkmark.shield.fill", text: "Kids only match with other kids")
                    SafetyBullet(icon: "checkmark.shield.fill", text: "No chat or messaging")
                    SafetyBullet(icon: "checkmark.shield.fill", text: "Same age group only")
                    SafetyBullet(icon: "checkmark.shield.fill", text: "All words filtered for safety")
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var kidsModeSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "figure.and.child.holdinghands")
                    .font(.system(size: 24))
                    .foregroundColor(theme.primary)
                
                Text("Kids Mode")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Toggle("", isOn: $kidsMode.isEnabled)
                    .tint(KidsColors.tileGreen)
            }
            
            Text("When enabled, the app uses kid-friendly settings, filtered content, and time limits.")
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var ageGroupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "birthday.cake.fill")
                    .foregroundColor(theme.accent)
                Text("Age Group")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
            }
            
            ForEach(KidsModeManager.AgeGroup.allCases) { age in
                AgeGroupRow(
                    ageGroup: age,
                    isSelected: kidsMode.ageGroup == age,
                    onSelect: { kidsMode.ageGroup = age }
                )
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var timeLimitSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(theme.warning)
                Text("Daily Time Limit")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
            }
            
            Text("\(kidsMode.dailyTimeLimit) minutes per day")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(KidsColors.tileBlue)
            
            Slider(
                value: Binding(
                    get: { Double(kidsMode.dailyTimeLimit) },
                    set: { kidsMode.dailyTimeLimit = Int($0) }
                ),
                in: 15...120,
                step: 15
            )
            .tint(theme.primary)
            
            HStack {
                Text("15 min")
                    .font(.caption)
                    .foregroundColor(AppColors.textMuted)
                Spacer()
                Text("2 hours")
                    .font(.caption)
                    .foregroundColor(AppColors.textMuted)
            }
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var usageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(theme.success)
                Text("Today's Usage")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Played Today")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text(kidsMode.todayPlaytimeFormatted)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(theme.textSecondary)
                    Text("\(kidsMode.remainingTimeMinutes) min")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(kidsMode.remainingTimeMinutes > 5 ? theme.success : theme.warning)
                }
            }
            
            Button(action: {
                kidsMode.resetTodayPlaytime()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Today's Time")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(theme.primary)
            }
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var pinSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(theme.success)
                Text("Parental PIN")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
            }
            
            if kidsMode.hasPIN {
                Text("PIN is set. Required to access these settings.")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                
                Button(action: { showPINSetup = true }) {
                    Text("Change PIN")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.primary)
                }
            } else {
                Text("Set a PIN to prevent children from changing settings.")
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                
                Button(action: { showPINSetup = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Set Parental PIN")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(theme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding()
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Age Group Row
struct AgeGroupRow: View {
    let ageGroup: KidsModeManager.AgeGroup
    let isSelected: Bool
    let onSelect: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(ageGroup.displayName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("\(ageGroup.timerSeconds)s timer • \(ageGroup.letterCount) letters")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.success)
                } else {
                    Circle()
                        .stroke(theme.textMuted, lineWidth: 2)
                        .frame(width: 24, height: 24)
                }
            }
            .padding()
            .background(isSelected ? theme.success.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - PIN Entry View
struct PINEntryView: View {
    let title: String
    let subtitle: String
    let onComplete: (String) -> Void
    @Binding var showError: Bool
    @Environment(\.theme) var theme
    
    @State private var pin = ""
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.primary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            // PIN dots
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? theme.primary : theme.surfaceLight)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(theme.textMuted, lineWidth: 1)
                        )
                }
            }
            
            if showError {
                Text("Incorrect PIN. Try again.")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
            }
            
            // Number pad
            VStack(spacing: 16) {
                ForEach(0..<3) { row in
                    HStack(spacing: 24) {
                        ForEach(1...3, id: \.self) { col in
                            let number = row * 3 + col
                            PINButton(number: "\(number)") {
                                appendDigit("\(number)")
                            }
                        }
                    }
                }
                
                HStack(spacing: 24) {
                    // Empty space
                    Color.clear.frame(width: 70, height: 70)
                    
                    PINButton(number: "0") {
                        appendDigit("0")
                    }
                    
                    // Delete
                    Button(action: deleteDigit) {
                        Image(systemName: "delete.left.fill")
                            .font(.system(size: 24))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 70, height: 70)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .onChange(of: pin) { newValue in
            if newValue.count == 4 {
                onComplete(newValue)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if showError {
                        pin = ""
                    }
                }
            }
        }
    }
    
    private func appendDigit(_ digit: String) {
        guard pin.count < 4 else { return }
        showError = false
        pin += digit
    }
    
    private func deleteDigit() {
        guard !pin.isEmpty else { return }
        pin.removeLast()
    }
}

struct PINButton: View {
    let number: String
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(theme.textPrimary)
                .frame(width: 70, height: 70)
                .background(theme.surface)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        }
    }
}

// MARK: - PIN Setup View
struct PINSetupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var kidsMode = KidsModeManager.shared
    
    @State private var step = 1 // 1 = enter, 2 = confirm
    @State private var firstPIN = ""
    @State private var confirmPIN = ""
    @State private var showMismatch = false
    
    var body: some View {
        NavigationView {
            VStack {
                if step == 1 {
                    PINEntryView(
                        title: "Create PIN",
                        subtitle: "Enter a 4-digit PIN to protect settings",
                        onComplete: { pin in
                            firstPIN = pin
                            step = 2
                        },
                        showError: .constant(false)
                    )
                } else {
                    PINEntryView(
                        title: "Confirm PIN",
                        subtitle: "Enter the same PIN again",
                        onComplete: { pin in
                            if pin == firstPIN {
                                kidsMode.setPIN(pin)
                                dismiss()
                            } else {
                                showMismatch = true
                                confirmPIN = ""
                            }
                        },
                        showError: $showMismatch
                    )
                }
            }
            .navigationTitle(step == 1 ? "Create PIN" : "Confirm PIN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Safety Bullet
struct SafetyBullet: View {
    let icon: String
    let text: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(theme.success)
            
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(theme.textSecondary)
        }
    }
}

// MARK: - Online Play Consent View
struct OnlinePlayConsentView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @ObservedObject private var kidsMode = KidsModeManager.shared
    @State private var consentChecked = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "person.2.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(theme.primary)
                        
                        Text("Online Play for Kids")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("Allow your child to play with other kids online")
                            .font(.system(size: 16))
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top)
                    
                    // Safety Measures
                    VStack(alignment: .leading, spacing: 16) {
                        Text("SAFETY MEASURES")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.textMuted)
                            .tracking(1.5)
                        
                        SafetyRow(
                            icon: "figure.child",
                            title: "Kids-Only Matchmaking",
                            description: "Your child will only be matched with other players in Kids Mode"
                        )
                        
                        SafetyRow(
                            icon: "bubble.left.and.bubble.right.fill",
                            title: "No Communication",
                            description: "There is no chat, messaging, or any way to communicate with other players"
                        )
                        
                        SafetyRow(
                            icon: "person.crop.circle.badge.checkmark",
                            title: "Age-Based Matching",
                            description: "Players are matched within the same age group (\(kidsMode.ageGroup.rawValue) years)"
                        )
                        
                        SafetyRow(
                            icon: "text.badge.checkmark",
                            title: "Filtered Words",
                            description: "All words are filtered for age-appropriate content"
                        )
                        
                        SafetyRow(
                            icon: "eye.slash.fill",
                            title: "Anonymous Play",
                            description: "Players only see usernames, no personal information is shared"
                        )
                    }
                    .padding()
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Consent Checkbox
                    Button(action: { consentChecked.toggle() }) {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: consentChecked ? "checkmark.square.fill" : "square")
                                .font(.system(size: 24))
                                .foregroundColor(consentChecked ? theme.success : theme.textMuted)
                            
                            Text("I am the parent or legal guardian of this child and I consent to online play with the safety measures described above.")
                                .font(.system(size: 14))
                                .foregroundColor(theme.textPrimary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding()
                    .background(consentChecked ? theme.success.opacity(0.1) : theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                    // Enable Button
                    Button(action: enableOnlinePlay) {
                        Text("Enable Online Play")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(consentChecked ? theme.primaryGradient : LinearGradient(colors: [theme.textMuted], startPoint: .top, endPoint: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(!consentChecked)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(theme.backgroundPrimary.ignoresSafeArea())
            .navigationTitle("Parental Consent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func enableOnlinePlay() {
        kidsMode.grantOnlineConsent()
        dismiss()
    }
}

// MARK: - Safety Row
struct SafetyRow: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(theme.primary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

#Preview {
    ParentalControlsView()
}
