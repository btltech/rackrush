import SwiftUI

struct PremiumTile: View {
    let letter: String
    let bonus: String?
    let isUsed: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    static let letterValues: [String: Int] = [
        "A": 1, "E": 1, "I": 1, "O": 1, "U": 1, "L": 1, "N": 1, "S": 1, "T": 1, "R": 1,
        "D": 2, "G": 2,
        "B": 3, "C": 3, "M": 3, "P": 3,
        "F": 4, "H": 4, "V": 4, "W": 4, "Y": 4,
        "K": 5,
        "J": 8, "X": 8,
        "Q": 10, "Z": 10
    ]
    
    var value: Int {
        Self.letterValues[letter.uppercased()] ?? 1
    }
    
    var tileColor: Color {
        if isUsed { return AppColors.surfaceLight.opacity(0.4) }
        if let bonus = bonus {
            switch bonus {
            case "DL": return AppColors.doubleLetter
            case "TL": return AppColors.tripleLetter
            case "DW": return AppColors.doubleWord
            default: break
            }
        }
        return AppColors.letterColor(value: value)
    }
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Outer glow for bonus tiles
                if !isUsed && bonus != nil {
                    RoundedRectangle(cornerRadius: Corners.md + 2)
                        .fill(tileColor.opacity(0.4))
                        .blur(radius: 10)
                }
                
                // Bottom shadow layer (3D depth)
                RoundedRectangle(cornerRadius: Corners.md)
                    .fill(tileColor.opacity(0.5))
                    .offset(y: isPressed ? 1 : 4)
                
                // Main tile body
                RoundedRectangle(cornerRadius: Corners.md)
                    .fill(
                        LinearGradient(
                            colors: [tileColor, tileColor.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .offset(y: isPressed ? 2 : 0)
                
                // Top bevel highlight
                VStack {
                    RoundedRectangle(cornerRadius: Corners.md)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .frame(height: 30)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: Corners.md))
                .offset(y: isPressed ? 2 : 0)
                
                // Inner border
                RoundedRectangle(cornerRadius: Corners.md)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .clear, .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .offset(y: isPressed ? 2 : 0)
                
                // Content
                VStack(spacing: 1) {
                    Text(letter.uppercased())
                        .font(Typography.tileLetter)
                        .foregroundColor(isUsed ? AppColors.textMuted : .white)
                        .shadow(color: .black.opacity(0.2), radius: 1, y: 1)
                    
                    HStack(spacing: 3) {
                        if let bonus = bonus {
                            Text(bonus)
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white.opacity(0.95))
                        }
                        Text("\(value)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isUsed ? AppColors.textMuted : .white.opacity(0.9))
                    }
                }
                .offset(y: isPressed ? 2 : 0)
            }
            .frame(height: 72)
            .opacity(isUsed ? 0.5 : 1)
        }
        .disabled(isUsed || isDisabled)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
        .pressEvents(onPress: { isPressed = true }, onRelease: { isPressed = false })
        // Accessibility
        .accessibilityLabel(TileAccessibilityLabel.forTile(letter: letter, value: value, bonus: bonus))
        .accessibilityHint(isUsed ? "Already used" : TileAccessibilityLabel.tileHint)
        .accessibilityAddTraits(isUsed ? .isStaticText : .isButton)
    }
}
