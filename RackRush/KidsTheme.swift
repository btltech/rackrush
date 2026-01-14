import SwiftUI

// MARK: - Kids Mode Color Theme
/// Bright, playful colors for a child-friendly experience

// MARK: - Kids Theme Implementation
struct KidsTheme: AppThemeProtocol {
    // Backgrounds - Bright sky blue and pastel colors
    var backgroundPrimary = Color(hex: "B8E1FC")  // Light sky blue
    var backgroundSecondary = Color(hex: "E8F4FD")  // Lighter blue
    var backgroundTertiary = Color(hex: "FFF5E6")  // Warm cream
    
    // Surfaces - Clean white and light tones
    var surface = Color.white
    var surfaceLight = Color(hex: "F8FBFF")
    var surfaceHighlight = Color(hex: "E3F2FD")
    
    // Brand/Accents - Playful bright colors
    var primary = Color(hex: "7ED957")  // Bright green
    var secondary = Color(hex: "5DADE2")  // Sky blue
    var accent = Color(hex: "FF6B8A")  // Coral pink
    var gold = Color(hex: "FFE66D")  // Bright yellow
    
    // Special - Fun tile colors
    var blue = Color(hex: "5DADE2")
    var purple = Color(hex: "BB6BD9")
    
    var primaryGradient = LinearGradient(
        colors: [Color(hex: "7ED957"), Color(hex: "58D68D")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    var secondaryGradient = LinearGradient(
        colors: [Color(hex: "5DADE2"), Color(hex: "3498DB")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var accentGradient = LinearGradient(
        colors: [Color(hex: "FF6B8A"), Color(hex: "FF9FF3")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var playerSelfGradient = LinearGradient(
        colors: [Color(hex: "FFD700"), Color(hex: "FF8C00")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var playerOpponentGradient = LinearGradient(
        colors: [Color(hex: "00E5FF"), Color(hex: "0091FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Text - Dark on light backgrounds
    var textPrimary = Color(hex: "2C3E50")  // Dark blue-gray
    var textSecondary = Color(hex: "5D6D7E")  // Medium gray
    var textMuted = Color(hex: "95A5A6")  // Light gray
    
    // Status - Kid-friendly colors
    var success = Color(hex: "7ED957")  // Same as primary
    var successGradient = LinearGradient(
        colors: [Color(hex: "7ED957"), Color(hex: "58D68D")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    var warning = Color(hex: "FFE66D")  // Warm yellow
    var error = Color(hex: "FF6B8A")  // Soft coral (not harsh red)
    
    // Letter value-based colors
    func letterColor(value: Int) -> Color {
        let colors: [Color] = [
            Color(hex: "FF6B8A"), Color(hex: "FFB347"), Color(hex: "FFE66D"),
            Color(hex: "7ED957"), Color(hex: "5DADE2"), Color(hex: "BB6BD9")
        ]
        return colors[value % colors.count]
    }
    
    // Timer color
    func timerColor(remaining: Int) -> Color {
        if remaining <= 5 { return Color(hex: "FFB347") } // gentle urgency
        if remaining <= 15 { return warning }
        return success
    }
}

// Keep KidsColors for backward compatibility during transition
struct KidsColors {
    static let theme = KidsTheme()
    static var backgroundPrimary: Color { theme.backgroundPrimary }
    static var backgroundSecondary: Color { theme.backgroundSecondary }
    static var backgroundAccent: Color { theme.backgroundTertiary }
    
    static var skyGradient: LinearGradient {
        LinearGradient(
            colors: [theme.backgroundPrimary, theme.backgroundSecondary, .white.opacity(0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static let tileRed = Color(hex: "FF6B8A")
    static let tileOrange = Color(hex: "FFB347")
    static let tileYellow = Color(hex: "FFE66D")
    static let tileGreen = Color(hex: "7ED957")
    static let tileBlue = Color(hex: "5DADE2")
    static let tilePurple = Color(hex: "BB6BD9")
    static let tilePink = Color(hex: "FF9FF3")
    static let tileTeal = Color(hex: "48C9B0")
    
    static let tileColors: [Color] = [
        tileRed, tileOrange, tileYellow, tileGreen,
        tileBlue, tilePurple, tilePink, tileTeal
    ]
    
    static func tileColor(for letter: String) -> Color {
        let index = Int(letter.unicodeScalars.first?.value ?? 65) % tileColors.count
        return tileColors[index]
    }
    
    static var surface: Color { theme.surface }
    static var success: Color { theme.success }
    static var textPrimary: Color { theme.textPrimary }
    static var textSecondary: Color { theme.textSecondary }
    static var textMuted: Color { theme.textMuted }
    
    static var playButtonGradient: LinearGradient { theme.primaryGradient }
    static var starGradient: LinearGradient {
        LinearGradient(colors: [tileYellow, tileOrange], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Kids Mode Sizing
struct KidsSizing {
    // Tiles are 40% larger
    static let tileSize: CGFloat = 84  // vs 60 in normal mode
    static let tileFontSize: CGFloat = 36  // vs 26
    static let tileCornerRadius: CGFloat = 20  // vs 12
    
    // Buttons
    static let buttonHeight: CGFloat = 70
    static let buttonCornerRadius: CGFloat = 35
    static let buttonFontSize: CGFloat = 24
    
    // Text
    static let titleSize: CGFloat = 48
    static let headlineSize: CGFloat = 28
    static let bodySize: CGFloat = 20
    static let captionSize: CGFloat = 16
    
    // Spacing
    static let tileSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 28
}

// MARK: - Kids Mode Typography
struct KidsTypography {
    static let title = Font.system(size: KidsSizing.titleSize, weight: .bold, design: .rounded)
    static let headline = Font.system(size: KidsSizing.headlineSize, weight: .semibold, design: .rounded)
    static let body = Font.system(size: KidsSizing.bodySize, weight: .medium, design: .rounded)
    static let caption = Font.system(size: KidsSizing.captionSize, weight: .regular, design: .rounded)
    static let tileLetter = Font.system(size: KidsSizing.tileFontSize, weight: .bold, design: .rounded)
}

// MARK: - Kids Mode View Modifiers

struct KidsCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(KidsColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }
}

struct KidsBounceAnimation: ViewModifier {
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    .spring(response: 0.4, dampingFraction: 0.5)
                    .repeatForever(autoreverses: true)
                ) {
                    scale = 1.05
                }
            }
    }
}

extension View {
    func kidsCard() -> some View {
        modifier(KidsCardStyle())
    }
    
    func kidsBounce() -> some View {
        modifier(KidsBounceAnimation())
    }
}

// MARK: - Star Rating View
struct StarRating: View {
    let score: Int // 1-3 stars
    let maxStars: Int = 3
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(systemName: index < score ? "star.fill" : "star")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        index < score ? KidsColors.starGradient : LinearGradient(
                            colors: [KidsColors.textMuted],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: index < score ? .orange.opacity(0.4) : .clear, radius: 6)
            }
        }
    }
    
    /// Calculate stars based on performance
    static func starsFor(yourScore: Int, oppScore: Int, wordLength: Int) -> Int {
        if yourScore > oppScore && wordLength >= 4 {
            return 3 // Excellent!
        } else if yourScore > oppScore || wordLength >= 3 {
            return 2 // Good job!
        } else {
            return 1 // Great try!
        }
    }
}

// MARK: - Encouraging Messages
struct KidsMessages {
    static let winMessages = [
        "Amazing! 🌟",
        "You did it! 🎉",
        "Super star! ⭐",
        "Awesome job! 🏆",
        "Fantastic! 🎊"
    ]
    
    static let tryAgainMessages = [
        "Great try! ⭐",
        "Keep going! 💪",
        "You're learning! 📚",
        "Almost there! 🌈",
        "Good effort! 👏"
    ]
    
    static let encouragements = [
        "You can do it! 💪",
        "Take your time! ⏰",
        "Look for small words! 🔍",
        "Try starting with vowels! 🔤"
    ]
    
    static func randomWin() -> String {
        winMessages.randomElement() ?? winMessages[0]
    }
    
    static func randomTryAgain() -> String {
        tryAgainMessages.randomElement() ?? tryAgainMessages[0]
    }
    
    static func randomEncouragement() -> String {
        encouragements.randomElement() ?? encouragements[0]
    }
}
