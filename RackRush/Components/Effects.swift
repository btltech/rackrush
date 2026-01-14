import SwiftUI

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let delay: Double
    
    init(duration: Double = 2.5, delay: Double = 0) {
        self.duration = duration
        self.delay = delay
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .white.opacity(0.12), location: 0.45),
                            .init(color: .white.opacity(0.2), location: 0.5),
                            .init(color: .white.opacity(0.12), location: 0.55),
                            .init(color: .clear, location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: -geo.size.width * 0.3 + (geo.size.width * 1.3) * phase)
                    .blendMode(.softLight)
                }
                .mask(content)
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 2.5, delay: Double = 0) -> some View {
        modifier(ShimmerModifier(duration: duration, delay: delay))
    }
}

// MARK: - Pulsing Effect (for urgent elements like timer)
struct PulsingModifier: ViewModifier {
    let isActive: Bool
    let intensity: CGFloat
    @State private var isPulsing = false
    
    init(isActive: Bool, intensity: CGFloat = 0.05) {
        self.isActive = isActive
        self.intensity = intensity
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive && isPulsing ? 1 + intensity : 1.0)
            .animation(isActive ? .easeInOut(duration: 0.4).repeatForever(autoreverses: true) : .default, value: isPulsing)
            .onChange(of: isActive) { newValue in
                isPulsing = newValue
            }
            .onAppear {
                if isActive {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulsing(when active: Bool, intensity: CGFloat = 0.05) -> some View {
        modifier(PulsingModifier(isActive: active, intensity: intensity))
    }
}

// MARK: - Glow Effect
struct GlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .shadow(color: isActive ? color.opacity(0.6) : .clear, radius: radius * 0.5)
            .shadow(color: isActive ? color.opacity(0.4) : .clear, radius: radius)
            .shadow(color: isActive ? color.opacity(0.2) : .clear, radius: radius * 1.5)
    }
}

extension View {
    func glow(color: Color, radius: CGFloat = 12, when active: Bool = true) -> some View {
        modifier(GlowModifier(color: color, radius: radius, isActive: active))
    }
}

// MARK: - Depth Shadow (Multi-layer shadow for 3D effect)
struct DepthShadowModifier: ViewModifier {
    let depth: Int // 1-3
    let color: Color
    
    func body(content: Content) -> some View {
        switch depth {
        case 1:
            content
                .shadow(color: color.opacity(0.15), radius: 2, y: 2)
        case 2:
            content
                .shadow(color: color.opacity(0.1), radius: 2, y: 2)
                .shadow(color: color.opacity(0.08), radius: 6, y: 4)
        case 3:
            content
                .shadow(color: color.opacity(0.1), radius: 2, y: 2)
                .shadow(color: color.opacity(0.08), radius: 8, y: 6)
                .shadow(color: color.opacity(0.05), radius: 16, y: 10)
        default:
            content
        }
    }
}

extension View {
    func depthShadow(_ depth: Int = 2, color: Color = .black) -> some View {
        modifier(DepthShadowModifier(depth: depth, color: color))
    }
}

// MARK: - Frosted Glass Effect
struct FrostedGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color.white.opacity(0.03))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.15), .white.opacity(0.05), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}

extension View {
    func frostedGlass(cornerRadius: CGFloat = 16) -> some View {
        modifier(FrostedGlassModifier(cornerRadius: cornerRadius))
    }
}

// MARK: - Ambient Particles Background
struct AmbientParticlesView: View {
    let particleCount: Int
    let colors: [Color]
    
    @State private var particles: [Particle] = []
    @State private var phase: CGFloat = 0
    
    struct Particle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var speed: Double
        var offset: CGFloat
        var colorIndex: Int // Deterministic color per particle
    }
    
    init(count: Int = 15, colors: [Color] = [.white, .purple.opacity(0.5), .cyan.opacity(0.3)]) {
        self.particleCount = count
        self.colors = colors
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(colors[particle.colorIndex % colors.count])
                        .frame(width: particle.size, height: particle.size)
                        .position(
                            x: particle.x + sin(phase * particle.speed + particle.offset) * 30,
                            y: particle.y + cos(phase * particle.speed + particle.offset) * 20
                        )
                        .opacity(particle.opacity)
                        .blur(radius: particle.size * 0.3)
                }
            }
            .onAppear {
                // Generate particles with deterministic colors
                particles = (0..<particleCount).map { index in
                    Particle(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: 0...geo.size.height),
                        size: CGFloat.random(in: 8...50),
                        opacity: Double.random(in: 0.02...0.08),
                        speed: Double.random(in: 0.3...1.2),
                        offset: CGFloat.random(in: 0...(.pi * 2)),
                        colorIndex: index // Each particle gets consistent color
                    )
                }
                
                // Animate
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
            }
        }
    }
}

// MARK: - Confetti View (Enhanced)
struct EnhancedConfettiView: View {
    @State private var particles: [ConfettiPiece] = []
    @State private var isAnimating = false
    
    let colors: [Color] = [
        Color(hex: "FFD93D"), // Gold
        Color(hex: "FF6B6B"), // Coral
        Color(hex: "7C5DFA"), // Purple
        Color(hex: "00D4AA"), // Teal
        Color(hex: "FF8E53"), // Orange
        .white
    ]
    
    struct ConfettiPiece: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var rotation: Double
        var size: CGFloat
        var color: Color
        var shape: ConfettiShape
        var velocity: CGFloat
        var horizontalDrift: CGFloat
    }
    
    enum ConfettiShape: CaseIterable {
        case circle, square, rectangle
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { piece in
                    confettiShape(piece)
                        .fill(piece.color)
                        .frame(width: piece.size, height: piece.shape == .rectangle ? piece.size * 2.5 : piece.size)
                        .rotationEffect(.degrees(piece.rotation + (isAnimating ? 360 : 0)))
                        .position(
                            x: piece.x + (isAnimating ? piece.horizontalDrift : 0),
                            y: isAnimating ? geo.size.height + 50 : piece.y
                        )
                        .opacity(isAnimating ? 0 : 1)
                }
            }
            .onAppear {
                // Generate confetti
                particles = (0..<60).map { _ in
                    ConfettiPiece(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: -50...geo.size.height * 0.3),
                        rotation: Double.random(in: 0...360),
                        size: CGFloat.random(in: 6...14),
                        color: colors.randomElement()!,
                        shape: ConfettiShape.allCases.randomElement()!,
                        velocity: CGFloat.random(in: 0.8...1.5),
                        horizontalDrift: CGFloat.random(in: -100...100)
                    )
                }
                
                // Animate
                withAnimation(.easeIn(duration: 3)) {
                    isAnimating = true
                }
            }
        }
    }
    
    func confettiShape(_ piece: ConfettiPiece) -> AnyShape {
        switch piece.shape {
        case .circle:
            return AnyShape(Circle())
        case .square:
            return AnyShape(RoundedRectangle(cornerRadius: 2))
        case .rectangle:
            return AnyShape(RoundedRectangle(cornerRadius: 1))
        }
    }
}

// Helper for type-erased shapes
struct AnyShape: Shape {
    private let _path: @Sendable (CGRect) -> Path
    
    init<S: Shape & Sendable>(_ shape: S) {
        _path = { rect in
            shape.path(in: rect)
        }
    }
    
    func path(in rect: CGRect) -> Path {
        _path(rect)
    }
}

// NOTE: ShakeEffect is defined in Animations.swift

// MARK: - Bounce Scale Effect
struct BounceScaleModifier: ViewModifier {
    let trigger: Bool
    @State private var scale: CGFloat = 1.0
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onChange(of: trigger) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.15
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        scale = 1.0
                    }
                }
            }
    }
}

extension View {
    func bounceOnChange(_ trigger: Bool) -> some View {
        modifier(BounceScaleModifier(trigger: trigger))
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        AmbientParticlesView()
            .ignoresSafeArea()
        
        VStack(spacing: 40) {
            Text("RACK RUSH")
                .font(.system(size: 40, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                )
                .shimmer()
            
            RoundedRectangle(cornerRadius: 16)
                .fill(.purple)
                .frame(width: 200, height: 60)
                .glow(color: .purple)
                .depthShadow(3)
            
            Text("Frosted Glass")
                .foregroundColor(.white)
                .padding()
                .frostedGlass()
        }
    }
}
