import SwiftUI

// MARK: - Accessibility System
/// Centralized accessibility utilities for RackRush

struct AccessibilityConfig {
    // MARK: - Environment Readers
    
    /// Check if user prefers reduced motion
    static var prefersReducedMotion: Bool {
        UIAccessibility.isReduceMotionEnabled
    }
    
    /// Check if user prefers increased contrast
    static var prefersHighContrast: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }
    
    /// Check if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }
    
    /// Check if user prefers bold text
    static var prefersBoldText: Bool {
        UIAccessibility.isBoldTextEnabled
    }
}

// MARK: - Accessible Color Palette
/// Colors with sufficient contrast for accessibility (WCAG 2.1 AA compliant)
extension AppColors {
    // High contrast alternatives (used when system preference enabled)
    static var textPrimaryAccessible: Color {
        AccessibilityConfig.prefersHighContrast ? .white : textPrimary
    }
    
    static var textSecondaryAccessible: Color {
        AccessibilityConfig.prefersHighContrast ? Color(hex: "D0D0E0") : textSecondary
    }
    
    // Colorblind-safe status colors (distinguishable by brightness, not just hue)
    static var successAccessible: Color {
        Color(hex: "00CC88") // Brighter green, good for deuteranopia
    }
    
    static var warningAccessible: Color {
        Color(hex: "FFB800") // More saturated amber
    }
    
    static var errorAccessible: Color {
        Color(hex: "FF4466") // Brighter red-pink
    }
}

// MARK: - Reduce Motion Modifier
struct ReduceMotionModifier: ViewModifier {
    let animation: Animation?
    @State private var shouldAnimate = false
    
    init(animation: Animation? = .default) {
        self.animation = animation
    }
    
    func body(content: Content) -> some View {
        if AccessibilityConfig.prefersReducedMotion {
            // Instant transitions when reduce motion is on
            content
        } else {
            content.animation(animation, value: shouldAnimate)
        }
    }
}

extension View {
    /// Applies animation only if user hasn't enabled Reduce Motion
    func accessibleAnimation(_ animation: Animation? = .default) -> some View {
        modifier(ReduceMotionModifier(animation: animation))
    }
}

// MARK: - VoiceOver Labels for Game Elements
struct TileAccessibilityLabel {
    /// Generate VoiceOver label for a letter tile
    static func forTile(letter: String, value: Int, bonus: String?) -> String {
        var label = "\(letter), \(value) point\(value > 1 ? "s" : "")"
        
        if let bonus = bonus {
            switch bonus {
            case "DL": label += ", double letter bonus"
            case "TL": label += ", triple letter bonus"
            case "DW": label += ", double word bonus"
            default: break
            }
        }
        
        return label
    }
    
    /// Generate hint for tile interaction
    static var tileHint: String {
        "Double tap to add to your word"
    }
}

struct TimerAccessibilityLabel {
    /// Generate VoiceOver label for timer
    static func forTimer(seconds: Int, isUrgent: Bool) -> String {
        if isUrgent {
            return "\(seconds) seconds remaining. Hurry!"
        }
        return "\(seconds) seconds remaining"
    }
}

struct ScoreAccessibilityLabel {
    /// Generate VoiceOver label for score display
    static func forScore(your: Int, opponent: Int, round: Int, totalRounds: Int) -> String {
        let status: String
        if your > opponent {
            status = "You're winning"
        } else if opponent > your {
            status = "Opponent is winning"
        } else {
            status = "Tied"
        }
        
        return "Round \(round) of \(totalRounds). Your score: \(your). Opponent score: \(opponent). \(status)."
    }
}

// MARK: - Accessibility View Modifiers

extension View {
    /// Add VoiceOver label to a view
    func gameAccessibility(label: String, hint: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Mark as a button for VoiceOver
    func accessibleButton(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Mark as a header for VoiceOver navigation
    func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// Mark view as live region (announces changes)
    func accessibleLiveRegion() -> some View {
        self.accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Dynamic Type Support
struct DynamicTypeModifier: ViewModifier {
    let baseSize: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    
    @Environment(\.sizeCategory) var sizeCategory
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: scaledSize, weight: weight, design: design))
    }
    
    private var scaledSize: CGFloat {
        // Scale based on system size category, but cap at reasonable limits
        switch sizeCategory {
        case .extraSmall: return baseSize * 0.8
        case .small: return baseSize * 0.9
        case .medium: return baseSize
        case .large: return baseSize * 1.05
        case .extraLarge: return baseSize * 1.1
        case .extraExtraLarge: return baseSize * 1.15
        case .extraExtraExtraLarge: return baseSize * 1.2
        case .accessibilityMedium: return baseSize * 1.25
        case .accessibilityLarge: return baseSize * 1.35
        case .accessibilityExtraLarge: return baseSize * 1.45
        case .accessibilityExtraExtraLarge: return baseSize * 1.55
        case .accessibilityExtraExtraExtraLarge: return baseSize * 1.65
        @unknown default: return baseSize
        }
    }
}

extension View {
    /// Apply font that respects Dynamic Type settings
    func dynamicFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(DynamicTypeModifier(baseSize: size, weight: weight, design: design))
    }
}

// MARK: - High Contrast Mode
struct HighContrastBorderModifier: ViewModifier {
    let color: Color
    let width: CGFloat
    
    func body(content: Content) -> some View {
        if AccessibilityConfig.prefersHighContrast {
            content
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(color, lineWidth: width)
                )
        } else {
            content
        }
    }
}

extension View {
    /// Adds a high-contrast border when system setting is enabled
    func highContrastBorder(color: Color = .white, width: CGFloat = 2) -> some View {
        modifier(HighContrastBorderModifier(color: color, width: width))
    }
}

// MARK: - Colorblind-Safe Indicators
/// Visual patterns in addition to colors for bonus tiles
struct ColorblindSafeIndicator: View {
    let bonusType: String // "DL", "TL", "DW"
    
    var body: some View {
        ZStack {
            switch bonusType {
            case "DL":
                // Circle pattern for Double Letter
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 2))
                    .frame(width: 12, height: 12)
            case "TL":
                // Triangle pattern for Triple Letter
                Triangle()
                    .stroke(lineWidth: 2)
                    .frame(width: 12, height: 12)
            case "DW":
                // Star pattern for Double Word
                Image(systemName: "star.fill")
                    .font(.system(size: 10))
            default:
                EmptyView()
            }
        }
        .foregroundColor(.black.opacity(0.6))
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Accessibility Announcements
class AccessibilityAnnouncer {
    static func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    static func announceRoundStart(round: Int, totalRounds: Int) {
        announce("Round \(round) of \(totalRounds) starting")
    }
    
    static func announceRoundEnd(won: Bool, yourWord: String, yourScore: Int, oppWord: String, oppScore: Int) {
        if won {
            announce("You won this round! You played \(yourWord) for \(yourScore) points. Opponent played \(oppWord) for \(oppScore) points.")
        } else {
            announce("Opponent won this round. They played \(oppWord) for \(oppScore) points. You played \(yourWord) for \(yourScore) points.")
        }
    }
    
    static func announceMatchEnd(won: Bool, finalScore: Int, oppScore: Int) {
        if won {
            announce("Congratulations! You won the match \(finalScore) to \(oppScore)!")
        } else {
            announce("Match over. Opponent wins \(oppScore) to \(finalScore).")
        }
    }
    
    static func announceTimerWarning(seconds: Int) {
        if seconds == 10 {
            announce("10 seconds remaining")
        } else if seconds == 5 {
            announce("5 seconds remaining. Hurry!")
        }
    }
}
