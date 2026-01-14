import SwiftUI

// MARK: - Theme Protocol
protocol AppThemeProtocol {
    // Backgrounds
    var backgroundPrimary: Color { get }
    var backgroundSecondary: Color { get }
    var backgroundTertiary: Color { get }
    
    // Surfaces
    var surface: Color { get }
    var surfaceLight: Color { get }
    var surfaceHighlight: Color { get }
    
    // Brand/Accents
    var primary: Color { get }
    var primaryGradient: LinearGradient { get }
    var secondary: Color { get }
    var secondaryGradient: LinearGradient { get }
    var accent: Color { get }
    var accentGradient: LinearGradient { get }
    var gold: Color { get }
    
    var playerSelfGradient: LinearGradient { get }
    var playerOpponentGradient: LinearGradient { get }
    
    // Special
    var blue: Color { get }
    var purple: Color { get }
    
    // Text
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var textMuted: Color { get }
    
    // Status
    var success: Color { get }
    var successGradient: LinearGradient { get }
    var warning: Color { get }
    var error: Color { get }
    
    // Specialized
    func letterColor(value: Int) -> Color
    func timerColor(remaining: Int) -> Color
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppThemeProtocol
    
    init(isKidsMode: Bool = false) {
        if isKidsMode {
            self.currentTheme = KidsTheme()
        } else {
            self.currentTheme = DefaultTheme()
        }
    }
}

private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppThemeProtocol = DefaultTheme()
}

extension EnvironmentValues {
    var theme: AppThemeProtocol {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Premium Color Palette
// MARK: - Default Theme Implementation
struct DefaultTheme: AppThemeProtocol {
    // Backgrounds
    var backgroundPrimary = Color("BackgroundPrimary")
    var backgroundSecondary = Color("BackgroundSecondary")
    var backgroundTertiary = Color("BackgroundTertiary")
    
    // Surfaces
    var surface = Color("SurfaceMain")
    var surfaceLight = Color("SurfaceLight")
    var surfaceHighlight = Color("SurfaceHighlight")
    
    // Brand/Accents
    var primary = Color("BrandPrimary")
    var secondary = Color("BrandSecondary")
    var accent = Color("BrandAccent")
    var gold = Color("DoubleLetter")
    
    var primaryGradient = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var secondaryGradient = LinearGradient(
        colors: [Color(hex: "06D6A0"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var accentGradient = LinearGradient(
        colors: [Color(hex: "EF476F"), Color(hex: "F97316")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var playerSelfGradient = LinearGradient(
        colors: [Color(hex: "06D6A0"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var playerOpponentGradient = LinearGradient(
        colors: [Color(hex: "EF476F"), Color(hex: "F97316")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Special
    var blue = Color("TileBlue")
    var purple = Color("TilePurple")
    
    // Text
    var textPrimary = Color("TextPrimary")
    var textSecondary = Color("TextSecondary")
    var textMuted = Color("TextMuted")
    
    // Status
    var success = Color("StatusSuccess")
    var successGradient = LinearGradient(
        colors: [Color(hex: "06D6A0"), Color(hex: "22C55E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    var warning = Color("StatusWarning")
    var error = Color("StatusError")
    
    // Letter value-based colors
    func letterColor(value: Int) -> Color {
        switch value {
        case 1: return Color(hex: "4B5EAA")
        case 2: return Color(hex: "22C55E")
        case 3: return Color(hex: "8B5CF6")
        case 4: return Color(hex: "F97316")
        case 5: return Color(hex: "FBBF24")
        case 8: return Color(hex: "EF476F")
        case 10: return Color(hex: "F59E0B")
        default: return Color(hex: "4A5568")
        }
    }
    
    // Timer color
    func timerColor(remaining: Int) -> Color {
        if remaining <= 5 { return error }
        if remaining <= 15 { return warning }
        return success
    }
}

// Keep AppColors for backward compatibility during transition
struct AppColors {
    static let theme = DefaultTheme()
    static var backgroundPrimary: Color { theme.backgroundPrimary }
    static var backgroundSecondary: Color { theme.backgroundSecondary }
    static var backgroundTertiary: Color { theme.backgroundTertiary }
    static var surface: Color { theme.surface }
    static var surfaceLight: Color { theme.surfaceLight }
    static var surfaceHighlight: Color { theme.surfaceHighlight }
    static var primary: Color { theme.primary }
    static var secondary: Color { theme.secondary }
    static var accent: Color { theme.accent }
    static var gold: Color { theme.gold }
    static var textPrimary: Color { theme.textPrimary }
    static var textSecondary: Color { theme.textSecondary }
    static var textMuted: Color { theme.textMuted }
    static var success: Color { theme.success }
    static var warning: Color { theme.warning }
    static var error: Color { theme.error }
    
    // Bonus tile colors
    static var doubleLetter: Color { theme.blue }
    static var tripleLetter: Color { theme.purple }
    static var doubleWord: Color { theme.accent }
    
    static let warmGradient = LinearGradient(
        colors: [Color(hex: "EF476F"), Color(hex: "F97316")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let goldGradient = LinearGradient(
        colors: [Color(hex: "FBBF24"), Color(hex: "F59E0B"), Color(hex: "D97706")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let tealGradient = LinearGradient(
        colors: [Color(hex: "06D6A0"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let logoGradientPurple = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1"), Color(hex: "3B82F6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let logoGradientWarm = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "EF476F"), Color(hex: "EC4899")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static func letterColor(value: Int) -> Color { theme.letterColor(value: value) }
    static func timerColor(remaining: Int) -> Color { theme.timerColor(remaining: remaining) }
    
    // Gradient definitions for backward compatibility or direct use
    static var primaryGradient: LinearGradient { theme.primaryGradient }
    static var secondaryGradient: LinearGradient { theme.secondaryGradient }
    static var accentGradient: LinearGradient { theme.accentGradient }
    static var successGradient: LinearGradient { theme.successGradient }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Premium Typography
struct Typography {
    // Hero text for splash/victory moments
    static let hero = Font.system(size: 64, weight: .black, design: .rounded)
    // Display for big numbers/scores
    static let display = Font.system(size: 48, weight: .heavy, design: .rounded)
    // Large title for screen headers
    static let largeTitle = Font.system(size: 36, weight: .bold, design: .rounded)
    // Title for sections
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    // Headline for card titles
    static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
    // Subheadline
    static let subheadline = Font.system(size: 17, weight: .semibold, design: .rounded)
    // Body text
    static let body = Font.system(size: 16, weight: .medium, design: .rounded)
    // Caption
    static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
    // Small/label
    static let small = Font.system(size: 11, weight: .semibold, design: .rounded)
    // Letter on tiles
    static let tileLetter = Font.system(size: 28, weight: .bold, design: .rounded)
    // Timer display
    static let timer = Font.system(size: 56, weight: .black, design: .rounded)
}

// MARK: - Spacing System (8pt baseline)
struct Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius System
struct Corners {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let pill: CGFloat = 100
}

// MARK: - Enhanced Glassmorphism Modifier
struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.8
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.surface.opacity(opacity))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial.opacity(0.3))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.15), .white.opacity(0.05), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

// MARK: - Glass View Helper
struct GlassView: View {
    var cornerRadius: CGFloat = 16
    var opacity: Double = 0.8
    
    var body: some View {
        Color.clear
            .modifier(GlassBackground(cornerRadius: cornerRadius, opacity: opacity))
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = 16, opacity: Double = 0.8) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Inner Highlight (3D bevel effect)
struct InnerHighlight: ViewModifier {
    var cornerRadius: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .clear, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func innerHighlight(cornerRadius: CGFloat = 16) -> some View {
        modifier(InnerHighlight(cornerRadius: cornerRadius))
    }
}

// MARK: - iOS 15/16 Compatibility Modifiers
struct HideScrollBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content
                .onAppear {
                    UITableView.appearance().backgroundColor = .clear
                }
        }
    }
}
