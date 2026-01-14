import SwiftUI

struct PINVerificationView: View {
    let onSuccess: () -> Void
    let onCancel: () -> Void
    @Environment(\.theme) var theme
    
    @ObservedObject private var kidsMode = KidsModeManager.shared
    @State private var enteredPIN = ""
    @State private var showError = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                theme.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Icon
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(theme.successGradient)
                    
                    // Title
                    VStack(spacing: 8) {
                        Text("Enter PIN")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("Enter your parental PIN to continue")
                            .font(.system(size: 16))
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    // PIN Dots
                    HStack(spacing: 16) {
                        ForEach(0..<4, id: \.self) { i in
                            Circle()
                                .fill(i < enteredPIN.count ? theme.primary : theme.surfaceLight)
                                .frame(width: 20, height: 20)
                                .animation(.easeInOut(duration: 0.15), value: enteredPIN.count)
                        }
                    }
                    .shake(showError: showError)
                    
                    // Hidden text field for keyboard
                    TextField("", text: $enteredPIN)
                        .keyboardType(.numberPad)
                        .focused($isFocused)
                        .opacity(0)
                        .frame(width: 1, height: 1)
                        .onChange(of: enteredPIN) { newValue in
                            // Limit to 4 digits
                            if newValue.count > 4 {
                                enteredPIN = String(newValue.prefix(4))
                            }
                            
                            // Auto-verify when 4 digits entered
                            if newValue.count == 4 {
                                verifyPIN()
                            }
                        }
                    
                    // Error message
                    if showError {
                        Text("Incorrect PIN")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    // Number pad
                    VStack(spacing: 12) {
                        ForEach(0..<3) { row in
                            HStack(spacing: 24) {
                                ForEach(1...3, id: \.self) { col in
                                    let num = row * 3 + col
                                    NumberButton(number: "\(num)") {
                                        addDigit("\(num)")
                                    }
                                }
                            }
                        }
                        
                        HStack(spacing: 24) {
                            // Empty placeholder
                            Color.clear.frame(width: 72, height: 72)
                            
                            NumberButton(number: "0") {
                                addDigit("0")
                            }
                            
                            // Delete button
                            Button(action: deleteDigit) {
                                Image(systemName: "delete.left.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(theme.textSecondary)
                                    .frame(width: 72, height: 72)
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
                .padding(24)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(theme.primary)
                }
            }
        }
    }
    
    private func addDigit(_ digit: String) {
        guard enteredPIN.count < 4 else { return }
        enteredPIN += digit
        showError = false
        
        if enteredPIN.count == 4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                verifyPIN()
            }
        }
    }
    
    private func deleteDigit() {
        guard !enteredPIN.isEmpty else { return }
        enteredPIN.removeLast()
        showError = false
    }
    
    private func verifyPIN() {
        if kidsMode.verifyPIN(enteredPIN) {
            onSuccess()
        } else {
            showError = true
            enteredPIN = ""
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - Number Button
struct NumberButton: View {
    let number: String
    let action: () -> Void
    @Environment(\.theme) var theme
    
    var body: some View {
        Button(action: {
            action()
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            Text(number)
                .font(.system(size: 32, weight: .medium, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .frame(width: 72, height: 72)
                .background(theme.surfaceLight)
                .clipShape(Circle())
        }
    }
}

// MARK: - Shake Modifier
extension View {
    func shake(showError: Bool) -> some View {
        self.modifier(ShakeModifier(showError: showError))
    }
}

struct ShakeModifier: ViewModifier {
    let showError: Bool
    @State private var offset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: showError) { newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 0.075).repeatCount(4, autoreverses: true)) {
                        offset = 10
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        offset = 0
                    }
                }
            }
    }
}

#Preview {
    PINVerificationView(
        onSuccess: {},
        onCancel: {}
    )
}
