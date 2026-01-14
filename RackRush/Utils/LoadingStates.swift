import SwiftUI

/// Loading state overlay for async operations
struct LoadingOverlay: View {
    let message: String
    @Environment(\.theme) var theme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }
}

/// Skeleton loading view for content placeholders
struct SkeletonView: View {
    @State private var isAnimating = false
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(width: CGFloat = 100, height: CGFloat = 20, cornerRadius: CGFloat = 8) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.5),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

/// Empty state view for no content scenarios
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    @Environment(\.theme) var theme
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(theme.textMuted)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    AudioManager.shared.playTap()
                    action()
                }) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(theme.primaryGradient)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Error state view with retry option
struct ErrorStateView: View {
    let error: String
    let retry: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(theme.error)
            
            VStack(spacing: 8) {
                Text("Something Went Wrong")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                
                Text(error)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: {
                AudioManager.shared.playTap()
                retry()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(theme.primaryGradient)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Loading") {
    LoadingOverlay(message: "Loading match...")
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "tray.fill",
        title: "No Matches Yet",
        message: "Start your first match to see your history here",
        actionTitle: "Play Now",
        action: {}
    )
}

#Preview("Error State") {
    ErrorStateView(error: "Failed to connect to server", retry: {})
}
