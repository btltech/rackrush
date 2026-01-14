import SwiftUI

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
