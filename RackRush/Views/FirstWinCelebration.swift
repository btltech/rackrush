import SwiftUI

/// First win celebration overlay with confetti and achievement unlock
struct FirstWinCelebration: View {
    @Binding var isPresented: Bool
    @Environment(\.theme) var theme
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0
    @State private var confettiTrigger = 0
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .opacity(opacity)
            
            VStack(spacing: 32) {
                // Trophy icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                center: .center,
                                startRadius: 20,
                                endRadius: 100
                            )
                        )
                        .frame(width: 160, height: 160)
                        .shadow(color: Color(hex: "FFD700").opacity(0.6), radius: 30)
                    
                    Text("🏆")
                        .font(.system(size: 80))
                }
                .scaleEffect(scale)
                .rotation3DEffect(
                    .degrees(scale == 1.0 ? 360 : 0),
                    axis: (x: 0, y: 1, z: 0)
                )
                
                VStack(spacing: 12) {
                    Text("FIRST VICTORY!")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    Text("Achievement Unlocked")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                    
                    // Badge card
                    HStack(spacing: 12) {
                        Text("🎖️")
                            .font(.system(size: 32))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Beginner")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Win your first match")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.textMuted)
                        }
                        
                        Spacer()
                    }
                    .padding(16)
                    .background(theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 8)
                }
                .padding(.horizontal, 32)
                .opacity(opacity)
                
                Button(action: {
                    AudioManager.shared.playSubmit()
                    withAnimation(.spring()) {
                        isPresented = false
                    }
                }) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "06D6A0"), Color(hex: "00B894")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color(hex: "06D6A0").opacity(0.4), radius: 12, y: 4)
                }
                .padding(.horizontal, 32)
                .opacity(opacity)
            }
            
            // Confetti
            ConfettiView()
                .allowsHitTesting(false)
                .opacity(opacity)
        }
        .onAppear {
            // Animate entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Play celebration sound
            AudioManager.shared.playWin()
            
            // Trigger confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                confettiTrigger += 1
            }
        }
    }
}

#Preview {
    FirstWinCelebration(isPresented: .constant(true))
}
