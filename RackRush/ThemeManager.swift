import SwiftUI

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
