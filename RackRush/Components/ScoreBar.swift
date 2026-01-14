import SwiftUI

struct ScoreBar: View {
    let myScore: Int
    let oppScore: Int
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background (Opponent Color)
                Capsule()
                    .fill(AppColors.warmGradient)
                    .frame(width: geo.size.width, height: 8)
                
                // Foreground (My Color)
                Capsule()
                    .fill(AppColors.tealGradient)
                    .frame(width: myWidth(totalWidth: geo.size.width), height: 8)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: myScore)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: oppScore)
                
                // Center Marker
                Rectangle()
                    .fill(Color.white.opacity(0.8))
                    .frame(width: 2, height: 12)
                    .position(x: geo.size.width / 2, y: 4)
            }
        }
        .frame(height: 8)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AppColors.surfaceHighlight, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private func myWidth(totalWidth: CGFloat) -> CGFloat {
        let total = myScore + oppScore
        if total == 0 { return totalWidth / 2 }
        
        // Clamp ratio to avoid tiny slivers (min 10% if score > 0)
        let ratio = CGFloat(myScore) / CGFloat(total)
        return totalWidth * ratio
    }
}

#Preview {
    VStack(spacing: 20) {
        ScoreBar(myScore: 50, oppScore: 50)
        ScoreBar(myScore: 80, oppScore: 20)
        ScoreBar(myScore: 10, oppScore: 90)
        ScoreBar(myScore: 0, oppScore: 0)
    }
    .padding()
    .background(Color.gray)
}
