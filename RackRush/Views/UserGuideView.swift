import SwiftUI

struct UserGuideView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    @State private var currentPage = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundPrimary
                    .ignoresSafeArea()
                
                TabView(selection: $currentPage) {
                    HowToPlayPage()
                        .tag(0)
                    
                    ScoringGuidePage()
                        .tag(1)
                    
                    BonusTilesPage()
                        .tag(2)
                    
                    TipsPage()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
            }
            .navigationTitle("How to Play")
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

// MARK: - How to Play Page
struct HowToPlayPage: View {
    @Environment(\.theme) var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: DeviceLayout.sectionSpacing) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: DeviceLayout.Fonts.title))
                        .foregroundStyle(theme.primaryGradient)
                    
                    Text("The Basics")
                        .font(.system(size: DeviceLayout.Fonts.headline, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                // Steps
                VStack(spacing: 20) {
                    GuideStep(
                        number: 1,
                        title: "Tap Letters",
                        description: "Tap tiles in your rack to build a word. Letters appear in the word builder above.",
                        icon: "square.grid.2x2"
                    )
                    
                    GuideStep(
                        number: 2,
                        title: "Submit Before Time Runs Out",
                        description: "You have 30 seconds per round. Submit your best word before the timer hits zero!",
                        icon: "timer"
                    )
                    
                    GuideStep(
                        number: 3,
                        title: "Longer = Better",
                        description: "Longer words score more points. Each letter has a value (like Scrabble).",
                        icon: "textformat.size.larger"
                    )
                    
                    GuideStep(
                        number: 4,
                        title: "Win 7 Rounds",
                        description: "Play 7 rounds. The player with the highest cumulative score wins the match!",
                        icon: "trophy.fill"
                    )
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Scoring Guide Page
struct ScoringGuidePage: View {
    @Environment(\.theme) var theme
    let letterValues: [(letters: String, value: Int)] = [
        ("A E I O U L N S T R", 1),
        ("D G", 2),
        ("B C M P", 3),
        ("F H V W Y", 4),
        ("K", 5),
        ("J X", 8),
        ("Q Z", 10)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: DeviceLayout.sectionSpacing) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "number.square.fill")
                        .font(.system(size: DeviceLayout.Fonts.title))
                        .foregroundStyle(theme.successGradient)
                    
                    Text("Letter Values")
                        .font(.system(size: DeviceLayout.Fonts.headline, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                // Letter value table
                VStack(spacing: 12) {
                    ForEach(letterValues, id: \.value) { row in
                        HStack {
                            Text(row.letters)
                                .font(.system(size: DeviceLayout.Fonts.body, weight: .semibold, design: .monospaced))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(row.value) pt\(row.value > 1 ? "s" : "")")
                                .font(.system(size: DeviceLayout.Fonts.body, weight: .bold))
                                .foregroundStyle(theme.primaryGradient)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                
                // Score formula
                VStack(spacing: 8) {
                    Text("Your Score = Sum of Letter Values")
                        .font(.system(size: DeviceLayout.Fonts.body))
                        .foregroundColor(theme.textSecondary)
                    
                    Text("+ Bonus Tiles!")
                        .font(.system(size: DeviceLayout.Fonts.body, weight: .bold))
                        .foregroundColor(theme.accent)
                }
                .padding(.top, 16)
                
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Bonus Tiles Page
struct BonusTilesPage: View {
    @Environment(\.theme) var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: DeviceLayout.sectionSpacing) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: DeviceLayout.Fonts.title))
                        .foregroundStyle(theme.secondaryGradient)
                    
                    Text("Bonus Tiles")
                        .font(.system(size: DeviceLayout.Fonts.headline, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                // Bonus explanations
                VStack(spacing: 16) {
                    BonusTileExplanation(
                        type: "DL",
                        name: "Double Letter",
                        description: "This letter's value is doubled",
                        color: theme.blue
                    )
                    
                    BonusTileExplanation(
                        type: "TL",
                        name: "Triple Letter",
                        description: "This letter's value is tripled",
                        color: theme.purple
                    )
                    
                    BonusTileExplanation(
                        type: "DW",
                        name: "Double Word",
                        description: "Your entire word score is doubled!",
                        color: theme.accent
                    )
                }
                .padding(.horizontal)
                
                // Example
                VStack(spacing: 12) {
                    Text("Example")
                        .font(.system(size: DeviceLayout.Fonts.body, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                    
                    HStack(spacing: 4) {
                        MiniTile(letter: "W", value: 4, bonus: nil)
                        MiniTile(letter: "O", value: 1, bonus: nil)
                        MiniTile(letter: "R", value: 1, bonus: "TL")
                        MiniTile(letter: "D", value: 2, bonus: nil)
                    }
                    
                    Text("W(4) + O(1) + R(1×3) + D(2) = 10 pts")
                        .font(.system(size: DeviceLayout.Fonts.caption, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                }
                .padding()
                .background(theme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Tips Page
struct TipsPage: View {
    @Environment(\.theme) var theme
    
    var body: some View {
        ScrollView {
            VStack(spacing: DeviceLayout.sectionSpacing) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: DeviceLayout.Fonts.title))
                        .foregroundColor(theme.accent)
                    
                    Text("Pro Tips")
                        .font(.system(size: DeviceLayout.Fonts.headline, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                // Tips list
                VStack(spacing: 16) {
                    TipCard(
                        icon: "rectangle.stack.fill",
                        title: "Prefixes & Suffixes",
                        description: "Look for common word parts: UN-, RE-, -ING, -ED, -LY"
                    )
                    
                    TipCard(
                        icon: "star.fill",
                        title: "Prioritize Bonus Tiles",
                        description: "Build words that use your bonus tiles - even if they're shorter"
                    )
                    
                    TipCard(
                        icon: "eyes.inverse",
                        title: "Watch the Opponent",
                        description: "When they submit, focus! Don't let them distract you."
                    )
                    
                    TipCard(
                        icon: "clock.fill",
                        title: "Submit Early If Stuck",
                        description: "A short word beats no word. Don't run out of time!"
                    )
                    
                    TipCard(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Clear and Retry",
                        description: "Tapped wrong letters? Hit clear (×) and start fresh."
                    )
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Supporting Views

struct GuideStep: View {
    let number: Int
    let title: String
    let description: String
    let icon: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Text("\(number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundColor(theme.primary)
                    
                    Text(title)
                        .font(.system(size: DeviceLayout.Fonts.body, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(description)
                    .font(.system(size: DeviceLayout.Fonts.caption))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct BonusTileExplanation: View {
    let type: String
    let name: String
    let description: String
    let color: Color
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 50, height: 50)
                
                Text(type)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.black)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: DeviceLayout.Fonts.body, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: DeviceLayout.Fonts.caption))
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MiniTile: View {
    let letter: String
    let value: Int
    let bonus: String?
    @Environment(\.theme) var theme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(bonus != nil ? bonusColor : theme.surface)
                .frame(width: 40, height: 48)
            
            VStack(spacing: 2) {
                Text(letter)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(bonus != nil ? .black : .white)
                
                if let bonus = bonus {
                    Text(bonus)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.black.opacity(0.7))
                } else {
                    Text("\(value)")
                        .font(.system(size: 9))
                        .foregroundColor(theme.textMuted)
                }
            }
        }
    }
    
    var bonusColor: Color {
        switch bonus {
        case "DL": return theme.blue
        case "TL": return theme.purple
        case "DW": return theme.accent
        default: return theme.surface
        }
    }
}

struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    @Environment(\.theme) var theme
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(theme.accent)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: DeviceLayout.Fonts.body, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: DeviceLayout.Fonts.caption))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    UserGuideView()
}
