import SwiftUI

/// Interactive tutorial overlay that guides new players through core mechanics
struct TutorialOverlay: View {
    @ObservedObject var gameState: GameState
    @Binding var isActive: Bool
    @State private var currentStep: TutorialStep = .selectLetter
    @State private var highlightedIndices: Set<Int> = []
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Semi-transparent backdrop - never block touch events
            // so users can still interact with the game underneath
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            // Tutorial content
            VStack {
                Spacer()
                
                // Instruction card
                TutorialCard(step: currentStep)
                    .padding(.horizontal, 24)
                    .padding(.bottom, currentStep == .selectLetter ? 200 : 120)
                
                if currentStep == .complete {
                    Button(action: {
                        AudioManager.shared.playSubmit()
                        withAnimation {
                            isActive = false
                            gameState.hasCompletedTutorial = true
                        }
                    }) {
                        Text("Start Playing!")
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            setupTutorial()
        }
        .onChange(of: gameState.currentWord) { newValue in
            handleWordChange(newValue)
        }
        .onChange(of: gameState.submitted) { submitted in
            if submitted && currentStep == .tapToSubmit {
                advanceToNextStep()
            }
        }
    }
    
    private func setupTutorial() {
        // Ensure we're in tutorial mode
        gameState.isTutorialMode = true
        currentStep = .selectLetter
        
        // Highlight first 3 letters as suggestions
        highlightedIndices = [0, 1, 2]
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
    }
    
    private func handleWordChange(_ word: String) {
        switch currentStep {
        case .selectLetter:
            if word.count >= 1 {
                advanceToNextStep()
            }
        case .buildWord:
            if word.count >= 3 {
                advanceToNextStep()
            }
        default:
            break
        }
    }
    
    private func advanceToNextStep() {
        withAnimation {
            switch currentStep {
            case .selectLetter:
                currentStep = .buildWord
            case .buildWord:
                currentStep = .tapToSubmit
            case .tapToSubmit:
                // Wait for actual submission
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation {
                        currentStep = .complete
                    }
                }
            case .complete:
                break
            }
        }
    }
}

enum TutorialStep {
    case selectLetter
    case buildWord
    case tapToSubmit
    case complete
    
    var title: String {
        switch self {
        case .selectLetter: return "Tap a Letter"
        case .buildWord: return "Build a Word"
        case .tapToSubmit: return "Submit Your Word"
        case .complete: return "You're Ready!"
        }
    }
    
    var description: String {
        switch self {
        case .selectLetter:
            return "Tap any letter below to start building your word. Try tapping the first letter!"
        case .buildWord:
            return "Great! Keep tapping letters to form a word. You need at least 3 letters."
        case .tapToSubmit:
            return "Perfect! Now tap the green Submit button to score points."
        case .complete:
            return "🎉 You've mastered the basics! Longer words and bonus tiles (DL, TL) earn more points. Ready to play?"
        }
    }
    
    var icon: String {
        switch self {
        case .selectLetter: return "hand.tap.fill"
        case .buildWord: return "character.textbox"
        case .tapToSubmit: return "checkmark.circle.fill"
        case .complete: return "trophy.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .selectLetter: return Color(hex: "8B5CF6")
        case .buildWord: return Color(hex: "F59E0B")
        case .tapToSubmit: return Color(hex: "06D6A0")
        case .complete: return Color(hex: "FFD700")
        }
    }
}

struct TutorialCard: View {
    let step: TutorialStep
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            ZStack {
                Circle()
                    .fill(step.color.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: step.icon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [step.color, step.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Title
            Text(step.title)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(.white)
            
            // Description
            Text(step.description)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(theme.surface)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        )
    }
}

#Preview {
    TutorialOverlay(gameState: GameState(), isActive: .constant(true))
}
