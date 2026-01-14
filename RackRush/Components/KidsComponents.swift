import SwiftUI

// MARK: - Kids Mode Tile
/// Large, colorful, bouncy tiles for children

struct KidsTile: View {
    let letter: String
    let isUsed: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    @State private var bounceScale: CGFloat = 1.0
    
    static let letterValues: [String: Int] = PremiumTile.letterValues
    
    var value: Int {
        Self.letterValues[letter.uppercased()] ?? 1
    }
    
    var tileColor: Color {
        if isUsed { return KidsColors.surface.opacity(0.3) }
        return KidsColors.tileColor(for: letter)
    }
    
    var body: some View {
        Button(action: {
            if !isUsed && !isDisabled {
                triggerBounce()
                onTap()
            }
        }) {
            ZStack {
                // Shadow layer
                RoundedRectangle(cornerRadius: KidsSizing.tileCornerRadius)
                    .fill(tileColor.opacity(0.3))
                    .offset(y: isPressed ? 2 : 6)
                
                // Main tile
                RoundedRectangle(cornerRadius: KidsSizing.tileCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [tileColor, tileColor.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: isPressed ? 2 : 0)
                
                // Highlight shine
                VStack {
                    RoundedRectangle(cornerRadius: KidsSizing.tileCornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(height: 35)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: KidsSizing.tileCornerRadius))
                .offset(y: isPressed ? 2 : 0)
                
                // Border
                RoundedRectangle(cornerRadius: KidsSizing.tileCornerRadius)
                    .stroke(.white.opacity(0.3), lineWidth: 2)
                    .offset(y: isPressed ? 2 : 0)
                
                // Letter and score
                VStack(spacing: 2) {
                    Text(letter.uppercased())
                        .font(KidsTypography.tileLetter)
                        .foregroundColor(isUsed ? KidsColors.textMuted : .white)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                    
                    Text("\(value)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isUsed ? KidsColors.textMuted : .white.opacity(0.85))
                }
                .offset(y: isPressed ? 2 : 0)
            }
            .frame(width: KidsSizing.tileSize, height: KidsSizing.tileSize + 8)
            .opacity(isUsed ? 0.4 : 1)
            .scaleEffect(bounceScale)
        }
        .disabled(isUsed || isDisabled)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
        // Accessibility
        .accessibilityLabel(TileAccessibilityLabel.forTile(letter: letter, value: value, bonus: nil))
        .accessibilityHint(isUsed ? "Already used" : TileAccessibilityLabel.tileHint)
    }
    
    private func triggerBounce() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bounceScale = 1.15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bounceScale = 1.0
            }
        }
    }
}

// MARK: - Kids Mascot
/// Animated helper character that encourages children

struct KidsMascot: View {
    let message: String
    let mood: Mood
    
    @State private var isAnimating = false
    
    enum Mood {
        case happy      // Big smile, bouncing
        case encouraging // Gentle smile, nodding
        case excited    // Stars in eyes, jumping
        case thinking   // Curious look
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            // Mascot character (using SF Symbols as placeholder)
            ZStack {
                Circle()
                    .fill(KidsColors.tileYellow)
                    .frame(width: 60, height: 60)
                
                // Face
                VStack(spacing: 4) {
                    HStack(spacing: 12) {
                        eye
                        eye
                    }
                    mouth
                }
            }
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .offset(y: isAnimating ? -4 : 0)
            .animation(
                .easeInOut(duration: 0.6)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear { isAnimating = true }
            
            // Speech bubble
            if !message.isEmpty {
                SpeechBubble(text: message)
            }
        }
    }
    
    private var eye: some View {
        ZStack {
            Ellipse()
                .fill(.white)
                .frame(width: 12, height: 14)
            
            Circle()
                .fill(Color(hex: "2C3E50"))
                .frame(width: 6, height: 6)
                .offset(y: 1)
            
            if mood == .excited {
                Image(systemName: "star.fill")
                    .font(.system(size: 4))
                    .foregroundColor(.white)
                    .offset(x: 1, y: -1)
            }
        }
    }
    
    private var mouth: some View {
        Group {
            switch mood {
            case .happy, .excited:
                // Big smile
                Capsule()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color(hex: "2C3E50"), lineWidth: 2)
                    .frame(width: 16, height: 8)
            case .encouraging:
                // Gentle smile
                Capsule()
                    .trim(from: 0.55, to: 0.95)
                    .stroke(Color(hex: "2C3E50"), lineWidth: 2)
                    .frame(width: 12, height: 6)
            case .thinking:
                // Curious O
                Circle()
                    .stroke(Color(hex: "2C3E50"), lineWidth: 2)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

struct SpeechBubble: View {
    let text: String
    
    var body: some View {
        HStack {
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(KidsColors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    BubbleShape()
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                )
        }
    }
}

struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let cornerRadius: CGFloat = 12
        let tailWidth: CGFloat = 10
        let tailHeight: CGFloat = 8
        
        // Main bubble
        path.addRoundedRect(
            in: CGRect(x: tailWidth, y: 0, width: rect.width - tailWidth, height: rect.height),
            cornerSize: CGSize(width: cornerRadius, height: cornerRadius)
        )
        
        // Tail pointing left
        path.move(to: CGPoint(x: tailWidth, y: rect.height / 2 - tailHeight / 2))
        path.addLine(to: CGPoint(x: 0, y: rect.height / 2))
        path.addLine(to: CGPoint(x: tailWidth, y: rect.height / 2 + tailHeight / 2))
        
        return path
    }
}

// MARK: - Word Pronunciation Button
struct PronunciationButton: View {
    let word: String
    @State private var isSpeaking = false
    
    var body: some View {
        Button(action: speak) {
            HStack(spacing: 6) {
                Image(systemName: isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                    .font(.system(size: 18))
                Text("Hear it")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
            }
            .foregroundColor(KidsColors.tileBlue)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(KidsColors.tileBlue.opacity(0.15))
            .clipShape(Capsule())
        }
        .disabled(isSpeaking)
    }
    
    // Static synthesizer so it doesn't get deallocated mid-speech
    private static let synthesizer = AVSpeechSynthesizer()
    
    private func speak() {
        isSpeaking = true
        
        // Use AVSpeechSynthesizer
        let utterance = AVSpeechUtterance(string: word)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8 // Slightly slower for kids
        utterance.pitchMultiplier = 1.1 // Slightly higher pitch
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        
        // Use static synthesizer so it persists
        Self.synthesizer.speak(utterance)
        
        // Reset after speaking
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSpeaking = false
        }
    }
}

import AVFoundation

#Preview {
    VStack(spacing: 30) {
        HStack {
            KidsTile(letter: "A", isUsed: false, isDisabled: false, onTap: {})
            KidsTile(letter: "B", isUsed: false, isDisabled: false, onTap: {})
            KidsTile(letter: "C", isUsed: true, isDisabled: false, onTap: {})
        }
        
        KidsMascot(message: "Great job! 🌟", mood: .happy)
        
        PronunciationButton(word: "CAT")
    }
    .padding()
    .background(KidsColors.skyGradient)
}
