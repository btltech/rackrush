import SwiftUI

@main
struct RackRushApp: App {
    @StateObject private var socketService = SocketService()
    @StateObject private var gameState = GameState()
    @StateObject private var themeManager = ThemeManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(socketService)
                .environmentObject(gameState)
                .environment(\.theme, themeManager.currentTheme)
                .preferredColorScheme(.dark)
                .onAppear {
                    gameState.socketService = socketService
                    socketService.connect()
                }
                .onChange(of: KidsModeManager.shared.isEnabled) { isKids in
                    themeManager.currentTheme = isKids ? KidsTheme() : DefaultTheme()
                }
        }
    }
}
