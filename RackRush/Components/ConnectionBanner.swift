import SwiftUI

struct ConnectionBanner: View {
    let isConnected: Bool
    
    @State private var show = false
    
    var body: some View {
        VStack {
            if !isConnected {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(0.8)
                    
                    Text("Connecting to server...")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(AppColors.warning)
                .clipShape(Capsule())
                .shadow(color: AppColors.warning.opacity(0.4), radius: 8, y: 4)
                .transition(.move(edge: .top).combined(with: .opacity))
                .padding(.top, 8)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isConnected)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        VStack {
            ConnectionBanner(isConnected: false)
            Spacer()
        }
    }
}
